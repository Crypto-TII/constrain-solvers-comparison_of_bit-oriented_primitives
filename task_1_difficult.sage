import argparse
import math
from ast import literal_eval
from csv import writer, reader
import sys
import os
sys.path.insert(_sage_const_0 , "/home/sage/tii-claasp")
from importlib import import_module
from claasp.cipher_modules.models.utils import set_fixed_variables
from claasp.utils.sage_scripts import get_ciphers, get_cipher_type
from claasp.cipher_modules.models.cp.cp_model import CpModel
from claasp.cipher_modules.models.sat.sat_model import SatModel
from claasp.cipher_modules.models.smt.smt_model import SmtModel
from claasp.cipher_modules.models.milp.milp_model import MilpModel

parser = argparse.ArgumentParser(description='compare script')

parser.add_argument('-m', action="store", dest="model", default='milp')
parser.add_argument('-t', action="store", dest="test", default='find_lowest_weight_xor_differential_trail')
parser.add_argument('-c', action="store", dest="cipher", default='chacha_permutation.py')
parser.add_argument('-s', action="store", dest="solver", default='Gurobi')
parser.add_argument('-p', action="store", dest="param", default = str({}))
parser.add_argument('-r', action="store", dest="rounds", default='5')
parser.add_argument('-w', action="store", dest="weight", default='24')
args = parser.parse_args() 


def handle_solution(X, model):
    if isinstance(X,str):
        return  'Timed out', 'Timed out', 'Timed out', 'Timed out', 'Timed out'
    
    if isinstance(X,list):
        build_time = X[ 0 ]['building_time_seconds']
        memory = X[ 0 ]['memory_megabytes']
        weight = X[ 0 ]['total_weight']
        if args.model == 'cp':
            solve_time = X[_sage_const_0 ]['solving_time_seconds']
        else:
            solve_time = sum([T['solving_time_seconds'] for T in X])
        
        return build_time, solve_time, memory, len(X), weight 
   
    return X['building_time_seconds'], X['solving_time_seconds'], X['memory_megabytes'],'/', X['total_weight']


def generate_creator( creator_file  ):
    creator_type = get_cipher_type(creator_file)
    creator_module = import_module(f'.ciphers.{creator_type}.{creator_file[:-3 ]}', 'claasp')
    for name in creator_module.__dict__:
        if 'BlockCipher' in name or 'HashFunction' in name or 'Permutation' in name:
            creator = creator_module.__dict__[name]
            break 
    return creator


def generate_fixed_variables(cipher, test):

    if 'plaintext' in cipher.inputs:
        plaintext_size = cipher.inputs_bit_size[cipher.inputs.index('plaintext')]
    if 'key' in cipher.inputs:
        key_size = cipher.inputs_bit_size[cipher.inputs.index('key')] 
    

    fixed_variables = []
    if 'plaintext' in cipher.inputs:
        fixed_variables.append(set_fixed_variables('plaintext', 'not_equal', range(plaintext_size), (_sage_const_0 ,)*plaintext_size))        
    if 'key' in cipher.inputs and 'differential' in test:
        if cipher.type == 'hash_function':
            fixed_variables.append(set_fixed_variables('key', 'not_equal', range(key_size), (_sage_const_0 ,)*key_size))
        else:
            fixed_variables.append(set_fixed_variables('key','equal', range(key_size), (_sage_const_0 ,)*key_size))
    return fixed_variables


if __name__=="__main__":
    
    if os.path.exists('famous_results/') == False:
            os.makedirs('famous_results/')
     
    if os.path.exists(f'famous_results/{args.cipher}.csv') == False:
        with open(f'famous_results/{args.cipher}.csv','a') as table:
            newline = ['Cipher', 'Test', 'Model', 'Building time', 'Solving time', 'Memory', 'Number of trails', 'Weight', 'Solver']
            writer(table).writerow(newline)
                             
    with open(f'famous_results/{args.cipher}.csv','a') as table:
        creator = generate_creator(args.cipher)
        parameters = literal_eval(args.param)
        rounds = literal_eval(args.rounds)
        parameters['number_of_rounds'] = rounds
        cipher = creator(**parameters)
        fixed_variables = generate_fixed_variables(cipher, args.test)                      
            
        if args.model == 'cp':
            module = import_module(f'claasp.cipher_modules.models.{args.model}.{args.model}_models.{args.model}_xor_differential_trail_search_model')
            model_class = getattr(module,f'{args.model.capitalize()}XorDifferentialTrailSearchModel')
        else:               
            module = import_module(f'claasp.cipher_modules.models.{args.model}.{args.model}_models.{args.model}_xor_differential_model')
            model_class = getattr(module,f'{args.model.capitalize()}XorDifferentialModel')
        model = model_class(cipher)
        print(f'running {args.test} on {model.cipher_id}')
        X = model.find_lowest_weight_xor_differential_trail(fixed_values=fixed_variables, solver_name=args.solver)
        elif 'all' in args.test:
               weight=find_weight(args.solver,args.model,model.cipher_id)
               print(f'testing with weight {weight}')
               X = model.find_all_xor_differential_trails_with_fixed_weight(fixed_weight=weight, fixed_values=fixed_variables, solver_name=args.solver)
        elif 'one' in args.test:
               X = model.find_one_xor_differential_trail_with_fixed_weight(fixed_weight=weight, fixed_values=fixed_variables, solver_name=args.solver)
    
    
        build_time, solve_time, memory, trail_num, weight_found = handle_solution(X,args.model)    
        newline = [model.cipher_id, args.test, model.__class__.__name__, build_time, solve_time, memory, trail_num, weight_found, args.solver]
        print(newline)
        writer(table).writerow(newline)

