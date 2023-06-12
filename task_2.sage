import sys
import os
import argparse
import constants

from importlib import import_module
from csv import writer, reader

from claasp.cipher_modules.models.utils import set_fixed_variables
from claasp.utils.sage_scripts import get_ciphers, get_cipher_type
from claasp.name_mappings import INPUT_KEY, INPUT_PLAINTEXT


sys.path.insert(0, "/home/sage/tii-claasp")

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

parser = argparse.ArgumentParser(description='compare script')
parser.add_argument('-m', action="store", dest="model", default='sat')
args = parser.parse_args()

files_list = get_ciphers()


def remove_repetitions(param):
    for i in range(len(param)):
        if 'number_of_rounds' in param[i]:
            param[i].pop("number_of_rounds")

    return [dict(t) for t in {tuple(d.items()) for d in param}]


def handle_solution(solution):

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


def generate_fixed_variables(cipher):

    fixed_variables = []

    if INPUT_PLAINTEXT in cipher.inputs:
        plaintext_size = cipher.inputs_bit_size[cipher.inputs.index(INPUT_PLAINTEXT)]
        fixed_variables.append(
            set_fixed_variables(
                INPUT_PLAINTEXT,
                'not_equal',
                range(plaintext_size),
                (0,) * plaintext_size))

    if INPUT_KEY in cipher.inputs:
        key_size = cipher.inputs_bit_size[cipher.inputs.index(INPUT_KEY)]

        if cipher.type != 'hash_function':
            fixed_variables.append(
                set_fixed_variables(
                    INPUT_KEY,
                    'equal',
                    range(key_size),
                    (0,) * key_size))
        else:
            fixed_variables.append(
                set_fixed_variables(
                    INPUT_KEY,
                    'not_equal',
                    range(key_size),
                    (0,) * key_size))

    return fixed_variables


def find_weight(model, cipher, rounds):

    with open(f'scripts/task_1_easy_results/{model}/results_{rounds}.csv', 'r') as table:
        csv_reader = reader(table)
        csv_list = list(csv_reader)
        try:
            el = next(csv_entry for csv_entry in csv_list if (csv_entry[0] == cipher))
            return el[6]
        except StopIteration:
            print(f'Error, no weight found on {cipher}. Please make sure to run task 1 first '
                  '(find lowest weight trail).')
            return -1


def timeout(func, args=(), kwargs={}, timeout_duration=600):
    @fork(timeout=timeout_duration, verbose=False)
    def my_new_func():
        return func(*args, **kwargs)
    return my_new_func()


if __name__ == "__main__":

    if not os.path.exists(f'scripts/task_2_results/{args.model}'):
        os.makedirs(f'scripts/task_2_results/{args.model}')

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
                    if not os.path.exists(f'scripts/task_2_results/{args.model}/results_{number_of_rounds}.csv'):
                        with open(f'scripts/task_2_results/{args.model}/results_{number_of_rounds}.csv', 'a') as table:
                            newline = [
                                'Cipher',
                                'Model',
                                'Building time',
                                'Solving time',
                                'Memory',
                                'Number of trails',
                                'Weight',
                                'Solver']
                            writer(table).writerow(newline)

                    with open(f'scripts/task_2_results/{args.model}/results_{number_of_rounds}.csv', 'a') as table:
                        parameters['number_of_rounds'] = number_of_rounds
                        if creator_file in list(failure[0] for failure in failure_queue[solver]):
                            break
                        cipher = creator(**parameters)
                        fixed_variables = generate_fixed_variables(cipher)

                        if args.model == 'cp':
                            module = import_module(
                                f'claasp.cipher_modules.models.{args.model}.{args.model}_models'
                                f'.{args.model}_xor_differential_trail_search_model')
                            model_capitalised = args.model.capitalize()
                            model_class = getattr(module, f'{model_capitalised}XorDifferentialTrailSearchModel')
                        else:
                            module = import_module(
                                f'claasp.cipher_modules.models.{args.model}.{args.model}_models' +
                                f'.{args.model}_xor_differential_model')
                            model_capitalised = args.model.capitalize()
                            model_class = getattr(module, f'{model_capitalised}XorDifferentialModel')
                        model = model_class(cipher)

                        fixed_weight = find_weight(args.model, model.cipher_id, number_of_rounds)
                        if fixed_weight == -1:
                            continue

                        solution = timeout(model.find_all_xor_differential_trails_with_fixed_weight,
                                           (fixed_variables, solver, fixed_weight))

                        if isinstance(solution, str):
                            print(f'{creator_file} failed on {parameters["number_of_rounds"]}')
                            failure_queue[solver].append([creator_file, parameters])
                            break
                        build_time, solve_time, memory, trail_num, weight = handle_solution(solution)
                        max_time = build_time + solve_time
                        newline = [model.cipher_id, model.__class__.__name__,
                                   build_time, solve_time, memory, trail_num, weight, solver]
                        print(newline)
                        writer(table).writerow(newline)
