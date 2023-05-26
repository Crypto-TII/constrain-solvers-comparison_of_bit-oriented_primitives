import sys
import os
import argparse
import constants

from importlib import import_module
from csv import writer
from claasp.cipher_modules.models.milp.milp_model import MilpModel
from claasp.cipher_modules.models.smt.smt_model import SmtModel
from claasp.cipher_modules.models.sat.sat_model import SatModel
from claasp.cipher_modules.models.cp.cp_model import CpModel
from claasp.utils.sage_scripts import get_ciphers, get_cipher_type
from claasp.cipher_modules.models.utils import set_fixed_variables


sys.path.insert(0, "/home/sage/claasp")

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

parser = argparse.ArgumentParser(description='compare script')

parser.add_argument('-m', action="store", dest="model", default='milp')

args = parser.parse_args()
files_list = get_ciphers()


def remove_repetitions(param):
    for i in range(len(param)):
        if 'number_of_rounds' in param[i]:
            param[i].pop("number_of_rounds")

    return [dict(t) for t in {tuple(d.items()) for d in param}]


def handle_solution(solution, model):

    if isinstance(solution, list):
        build_time = solution[0]['building_time_seconds']
        memory = solution[0]['memory_megabytes']
        weight = solution[0]['total_weight']
        if args.model == 'cp':
            solve_time = solution[0]['solving_time_seconds']
        else:
            solve_time = sum([sol['solving_time_seconds'] for sol in solution])

        return build_time, solve_time, memory, len(solution), weight

    return solution['building_time_seconds'], solution['solving_time_seconds'], solution['memory_megabytes'], '/', solution['total_weight']


def generate_parameters(creator_file):
    creator_type = get_cipher_type(creator_file)
    creator_module = import_module(f'.ciphers.{creator_type}.{creator_file[:-3]}', 'claasp')
    available_parameters = []
    for name in creator_module.__dict__:
        if 'BlockCipher' in name or 'HashFunction' in name or 'Permutation' in name:
            creator = creator_module.__dict__[name]
            available_parameters = creator_module.__dict__['PARAMETERS_CONFIGURATION_LIST']
            break
    available_parameters = remove_repetitions(available_parameters)
    return creator, available_parameters


def generate_fixed_variables(cipher, test):

    fixed_variables = []

    if 'plaintext' in cipher.inputs:
        plaintext_size = cipher.inputs_bit_size[cipher.inputs.index('plaintext')]
        fixed_variables.append(
            set_fixed_variables(
                'plaintext',
                'not_equal',
                list(range(plaintext_size)),
                [0] * plaintext_size))

    if 'key' in cipher.inputs and 'differential' in test:
        key_size = cipher.inputs_bit_size[cipher.inputs.index('key')]

        if cipher.type != 'hash_function':
            fixed_variables.append(set_fixed_variables('key', 'equal', list(range(key_size)), [0] * key_size))
        else:
            fixed_variables.append(set_fixed_variables('key', 'not_equal', list(range(key_size)), [0] * key_size))

    return fixed_variables


def timeout(func, args=(), kwargs={}, timeout_duration=600):
    @fork(timeout=timeout_duration, verbose=False)
    def my_new_func():
        return func(*args, **kwargs)
    return my_new_func()


if __name__ == "__main__":

    if not os.path.exists(f'quick_results/{args.model}'):
        os.makedirs(f'quick_results/{args.model}')

    failure_queue = dict.fromkeys(constants.MODEL_LIST[args.model]['solver_list'])
    for solver in failure_queue:
        failure_queue[solver] = []

    creator_list = [x for x in files_list if x.endswith(
        '.py') and x not in constants.MODEL_LIST[args.model]['exclude_list']]

    for creator_file in creator_list:
        print(f'testing on {creator_file}')
        creator, available_parameters = generate_parameters(creator_file)
        for solver in constants.MODEL_LIST[args.model]['solver_list']:
            print(f'testing with {solver}')
            for parameters in available_parameters:

                number_of_rounds = 1
                max_time = 0.0
                while True:
                    number_of_rounds += 1
                    if max_time > 2.0 and number_of_rounds > 6:
                        break
                    if not os.path.exists(f'quick_results/{args.model}/results_{number_of_rounds}.csv'):
                        with open(f'quick_results/{args.model}/results_{number_of_rounds}.csv', 'a') as table:
                            newline = [
                                'Cipher',
                                'Test',
                                'Model',
                                'Building time',
                                'Solving time',
                                'Memory',
                                'Number of trails',
                                'Weight',
                                'Solver']
                            writer(table).writerow(newline)

                    with open(f'quick_results/{args.model}/results_{number_of_rounds}.csv', 'a') as table:
                        parameters['number_of_rounds'] = number_of_rounds
                        if creator_file in list(failure[0] for failure in failure_queue[solver]):
                            break
                        cipher = creator(**parameters)
                        fixed_variables = generate_fixed_variables(cipher, test)

                        if args.model == 'cp':
                            module = import_module(
                                f'claasp.cipher_modules.models.{args.model}.{args.model}_models'
                                f'.{args.model}_xor_differential_trail_search_model')
                            model_capitalised = args.model.capitalize()
                            model_class = getattr(module, f'{model_capitalised}XorDifferentialTrailSearchModel')
                        else:
                            module = import_module(
                                f'claasp.cipher_modules.models.{args.model}.{args.model}_models' +
                                f'{args.model}_xor_differential_model')
                            model_capitalised = args.model.capitalize()
                            model_class = getattr(module, f'{model_capitalised}XorDifferentialModel')
                        model = model_class(cipher)
                        solution = timeout(model.find_lowest_weight_xor_differential_trail, (fixed_variables, solver))

                        if isinstance(solution, str):
                            print(f'{creator_file} failed on {parameters["number_of_rounds"]}')
                            failure_queue[solver].append([creator_file, parameters])
                            break
                        build_time, solve_time, memory, trail_num, weight = handle_solution(solution, args.model)
                        max_time = build_time + solve_time
                        newline = [model.cipher_id, test, model.__class__.__name__,
                                   build_time, solve_time, memory, trail_num, weight, solver]
                        print(newline)
                        writer(table).writerow(newline)

    print(f'STARTING SECOND PHASE FOR {args.model}')
    for i in range(3):
        end_time = 600 * 2 ** (i + 1)
        print(f'current end_time on {args.model} = {end_time}')
        for solver in constants.MODEL_LIST[args.model]['solver_list']:
            for creator_file, parameters in failure_queue[solver]:
                print('testing on couple  ', end='')
                print([creator_file, parameters], end='')
                print(' with ' + solver)
                creator = generate_parameters(creator_file)[0]
                for number_of_rounds in range(parameters['number_of_rounds'], 7):
                    parameters['number_of_rounds'] = number_of_rounds
                    cipher = creator(**parameters)
                    fixed_variables = generate_fixed_variables(cipher, test)

                    module = import_module(
                        f'claasp.cipher_modules.models.{args.model}.{args.model}_models'
                        f'.{args.model}_xor_differential_model')
                    model_capitalised = args.model.capitalize()
                    model_class = getattr(module, f'{model_capitalised}XorDifferentialModel')
                    model = model_class(ciphers)

                    solution = timeout(model.find_lowest_weight_xor_differential_trail,
                                       (fixed_variables, solver), timeout_duration=end_time)

                    if not isinstance(solution, str):
                        print(f'{creator_file} succeeded on {number_of_rounds}')
                        if [creator_file, parameters] in failure_queue[solver]:
                            failure_queue[solver].remove([creator_file, parameters])
                    if isinstance(solution, str) and ([creator_file, parameters] not in failure_queue[solver]):
                        failure_queue[solver].append([creator_file, parameters])
                        print(f'{creator_file} failed on {number_of_rounds}')
                        break
                    if isinstance(solution, str) and ([creator_file, parameters] in failure_queue[solver]):
                        print(f'{creator_file} failed again on {number_of_rounds}')
                        break
                    build_time, solve_time, memory, trail_num, weight = handle_solution(solution, args.model)
                    newline = [
                        model.cipher_id,
                        test,
                        model.__class__.__name__,
                        build_time,
                        solve_time,
                        memory,
                        trail_num,
                        weight,
                        solver]
                    print(newline)
                    with open(f'quick_results/{args.model}/results_{number_of_rounds}.csv', 'a') as table:
                        writer(table).writerow(newline)
