import argparse
from csv import writer,reader
import sys
import os
sys.path.insert(0, "/home/sage/claasp")
from importlib import import_module
from claasp.cipher_modules.models.utils import set_fixed_variables
from claasp.utils.sage_scripts import get_ciphers, get_cipher_type
from claasp.cipher_modules.models.cp.cp_model import CpModel
from claasp.cipher_modules.models.sat.sat_model import SatModel
from claasp.cipher_modules.models.smt.smt_model import SmtModel
from claasp.cipher_modules.models.milp.milp_model import MilpModel
from scripts import constants

sys.path.insert(0  , os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

parser = argparse.ArgumentParser(description='compare script')

parser.add_argument('-m', action="store", dest="model", default='milp')

args = parser.parse_args()
files_list = get_ciphers()


def remove_repetitions(param):
    for i in range(len(param)):
        if 'number_of_rounds' in param[i]:
            param[i].pop("number_of_rounds")
  
    return [dict(t) for t in {tuple(d.items()) for d in param}]
    
def handle_solution(X, model):
    
    if isinstance(X,list):
        build_time = X[0]['building_time_seconds']
        memory = X[0]['memory_megabytes']
        weight = X[0]['total_weight']
        if args.model == 'cp':
            solve_time = X[0]['solving_time_seconds']
        else:
            solve_time = sum([T['solving_time_seconds'] for T in X])
        
        return build_time, solve_time, memory, len(X), weight 
   
    return X['building_time_seconds'], X['solving_time_seconds'], X['memory_megabytes'],'/', X['total_weight']


def generate_parameters( creator_file  ):
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
        fixed_variables.append(set_fixed_variables('plaintext', 'not_equal', list(range(plaintext_size)), [0]*plaintext_size))
    
    if 'key' in cipher.inputs and 'differential' in test:
        key_size = cipher.inputs_bit_size[cipher.inputs.index('key')]
        
        if cipher.type != 'hash_function':
            fixed_variables.append(set_fixed_variables('key', 'equal', list(range(key_size)), [0]*key_size))
        else: 
            fixed_variables.append(set_fixed_variables('key', 'not_equal', list(range(key_size)), [0]*key_size))
    
    return fixed_variables

def find_weight(model, cipher, rounds):

    with open(f'final_results/{model}/results_{str(rounds)}.csv','r') as table:
        csv_reader = reader(table)
        csv_list = list(csv_reader)
        try:
            el = next(x for x in csv_list if (x[0] == cipher and x[1] == 'find_lowest_weight_xor_differential_trail'))
            return el[7]
        except StopIteration:
            print(f'Error, no weight found on {cipher}. Please make sure to run "find_lowest" test first')
            return -1



def timeout(func, args=(), kwargs={}, timeout_duration = 600):
    @fork(timeout=timeout_duration, verbose=False)
    def my_new_func():
        return func(*args, **kwargs)
    return my_new_func()


if __name__=="__main__":
     

    if os.path.exists('quick_results/{'+str(args.model)) == False:
            os.makedirs('quick_results/'+str(args.model))

    failure_queue = dict.fromkeys(constants.MODEL_LIST[args.model]['solver_list'])
    for solver in failure_queue:
        failure_queue[solver] = []
    
    
    creator_list = [x for x in files_list if x.endswith('.py') and x not in constants.MODEL_LIST[args.model]['exclude_list']]
    

    for creator_file in creator_list:
        print(f'testing on {creator_file}')
        creator, available_parameters = generate_parameters(creator_file)
        for solver in constants.MODEL_LIST[args.model]['solver_list']: 
            print(f'testing with {solver}')
            for parameters in available_parameters:

                Nrounds = 1
                max_time = 0.0
                while True: 
                    Nrounds+=1
                    if max_time > 2.0 and Nrounds > 6:
                        break
                    if os.path.exists(f'quick_results/{args.model}/results_{Nrounds}.csv') == False:
                        with open(f'quick_results/{args.model}/results_{Nrounds}.csv','a') as table:
                            newline = ['Cipher', 'Test', 'Model', 'Building time', 'Solving time', 'Memory', 'Number of trails', 'Weight', 'Solver']
                            writer(table).writerow(newline)
                          
                
                    with open(f'quick_results/{args.model}/results_{Nrounds}.csv','a') as table:
                        parameters['number_of_rounds'] = Nrounds
                        if creator_file in list(X[0] for X in failure_queue[solver]):
                            break
                        cipher = creator(**parameters)
                        fixed_variables = generate_fixed_variables(cipher, test)
                            
                        if args.model == 'cp':    
                            module = import_module('claasp.cipher_modules.models.'+args.model+'.'+args.model+'_models.'+args.model+'_xor_differential_trail_search_model')
                            model_class = getattr(module,args.model.capitalize()+'XorDifferentialTrailSearchModel')
                        else:          
                            module = import_module('claasp.cipher_modules.models.'+args.model+'.'+args.model+'_models.'+args.model+'_xor_differential_model')
                            model_class = getattr(module,args.model.capitalize()+'XorDifferentialModel')
                        model = model_class(cipher)
                        
                        fixed_weight = find_weight(args.model,model.cipher_id,Nrounds)
                        if fixed_weight == -1:
                            continue
                        X = timeout(model.find_all_xor_differential_trails_with_fixed_weight,(fixed_variables, solver, fixed_weight))

                        if isinstance(X,str):
                            print(creator_file+' failed on '+str(parameters['number_of_rounds']))
                            failure_queue[solver].append([creator_file,parameters])
                            break
                        build_time, solve_time, memory, trail_num, weight = handle_solution(X,args.model)    
                        max_time = build_time + solve_time
                        newline = [model.cipher_id, test, model.__class__.__name__, build_time, solve_time, memory, trail_num, weight, solver]
                        print(newline)
                        writer(table).writerow(newline)
                            
