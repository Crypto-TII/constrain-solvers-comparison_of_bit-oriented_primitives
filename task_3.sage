import sys
import os
import time
import math
import argparse

from ast import literal_eval
from csv import writer
from importlib import import_module

from scripts.constants import fixed_differential
from claasp.utils.sage_scripts import get_cipher_type, get_ciphers
from claasp.cipher_modules.models.utils import set_fixed_variables, integer_to_bit_list

sys.path.insert(0, "/home/sage/claasp")


parser = argparse.ArgumentParser(description='fixed_differential test script')
parser.add_argument('-m', action="store", dest="model", default='sat')
parser.add_argument('-s', action="store", dest="solver", default='cryptominisat')
parser.add_argument('-c', action="store", dest="cipher", default='speck_block_cipher.py')
parser.add_argument('-r', action="store", dest="rounds", default=10, type=int)

args = parser.parse_args()


def generate_creator(creator_file):
    creator_type = get_cipher_type(creator_file)
    creator_module = import_module(f'.ciphers.{creator_type}.{creator_file[:-3]}', 'claasp')
    for name in creator_module.__dict__:
        if 'BlockCipher' in name or 'HashFunction' in name or 'Permutation' in name:
            creator = creator_module.__dict__[name]
            break
    return creator


def handle_solution(solution, model):

    if isinstance(solution, list):
        build_time = solution[0]['building_time_seconds']
        memory = solution[0]['memory_megabytes']
        weight = solution[0]['total_weight']
        if args.model == 'cp':
            solve_time = solution[0]['solving_time_seconds']
        else:
            solve_time = sum([T['solving_time_seconds'] for T in solution])

        return build_time, solve_time, memory, len(solution), weight

    return solution['building_time_seconds'], solution['solving_time_seconds'], solution['memory_megabytes'], '/', solution['total_weight']


if __name__ == "__main__":

    if not os.path.exists(f'fixed_differential_results/'):
        os.makedirs(f'fixed_differential_results/')

    if not os.path.exists(f'fixed_differential_results/{args.cipher}.csv'):
        with open(f'fixed_differential_results/{args.cipher}.csv', 'a') as table:
            newline = [
                'Cipher',
                'Model',
                'Plaintext differential',
                'Output differential',
                'Building time',
                'Solving time',
                'Weight',
                'Solver']
            writer(table).writerow(newline)

    pt_size = fixed_differential[args.cipher][5]
    key_size = fixed_differential[args.cipher][6]
    with open(f'fixed_differential_results/{args.cipher}_{args.rounds}_rounds.csv', 'a') as table:
        creator = generate_creator(args.cipher)
        parameters = {'block_bit_size': pt_size, 'key_bit_size': key_size, 'number_of_rounds': args.rounds}
        cipher = creator(**parameters)
        if args.model == 'cp':
            module = import_module(
                f'claasp.cipher_modules.models.{args.model}.{args.model}_models'
                f'.{args.model}_xor_differential_trail_search_model')
            model_class = getattr(module, f'{args.model.capitalize()}XorDifferentialTrailSearchModel')
        else:
            module = import_module(
                f'claasp.cipher_modules.models.{args.model}.{args.model}_models.{args.model}_xor_differential_model')
            model_class = getattr(module, f'{args.model.capitalize()}XorDifferentialModel')

        model = model_class(cipher)

        plaintext_differential = fixed_differential[args.cipher][0]
        ciphertext_differential = fixed_differential[args.cipher][1]
        plaintext = set_fixed_variables(
            'plaintext', 'equal', range(pt_size), integer_to_bit_list(plaintext_differential, pt_size, 'big'))
        key = set_fixed_variables('key', 'equal', range(key_size), integer_to_bit_list(0, key_size, 'big'))
        comps = cipher.get_all_components()
        output_component = cipher.get_all_components()[-1].id
        output = set_fixed_variables(
            output_component,
            'equal',
            range(pt_size),
            integer_to_bit_list(ciphertext_differential, pt_size, 'big'))
        start = time.time()

        solutions = model.find_all_xor_differential_trails_with_weight_at_most(
            fixed_values=[plaintext, output, key],
            min_weight=fixed_differential[args.cipher][2],
            max_weight=fixed_differential[args.cipher][3])
        end = time.time()
        separation_line = [
            'Cipher',
            'Model',
            'Plaintext differential',
            'Output differential',
            'Overall time',
            'Number of solution',
            'Overall probability',
            'Solver']

        writer(table).writerow(separation_line)
        weights = [literal_eval(str(solution['total_weight'])) for solution in solutions]

        if len(weights) > 0:
            sum_of_prob = math.log2(sum([2**-w for w in weights]))
        else:
            sum_of_prob = -1

        final_line = [
            model.cipher_id,
            args.model,
            hex(plaintext_differential),
            hex(ciphertext_differential),
            end - start,
            len(solutions),
            sum_of_prob,
            args.solver]
        writer(table).writerow(final_line)
        print(final_line)
