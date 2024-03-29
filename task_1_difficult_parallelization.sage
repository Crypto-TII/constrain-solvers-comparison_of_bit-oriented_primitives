import os
import sys
import argparse
import constants
import famous_results

from subprocess import Popen
from time import sleep


sys.path.insert(0, "/home/sage/tii-claasp")

parser = argparse.ArgumentParser(description='parallelization of task 1')
parser.add_argument('--models', '-m', action="extend", nargs='*',
                    default=['sat', 'smt', 'milp', 'cp'])
args = parser.parse_args()

if not os.path.exists('scripts/LOGS/task_1_difficult/'):
    os.makedirs('scripts/LOGS/task_1_difficult/')

commands = []
for model in args.models:
    for solver in constants.MODEL_LIST[model]['solver_list']:
        for cipher in ('speck_block_cipher.py', 'simon_block_cipher.py', 'present_block_cipher.py'):
            for param in famous_results.DIFFERENTIAL_TRAILS[cipher]:
                rounds, weight = famous_results.DIFFERENTIAL_TRAILS[cipher][param]
                cmd_list = ['sage', 'scripts/task_1_difficult.sage', '-m', model, '-s', solver, '-c',
                            cipher, '-p', str(dict(param)), '-r', str(rounds), '-w', str(weight)]
                commands.append(cmd_list)

processes = [Popen(i, stdout=open(f'scripts/LOGS/task_1_difficult/{i[3]}.txt', 'a'),
                   stderr=open(f'scripts/LOGS/task_1_difficult/{i[3]}_ERR.txt', 'a')) for i in commands]

time = 0

for process in processes:
    while process.poll() is None:
        if time > 86400:
            break
        sleep(10)
        time += 10

    if process.poll() is not None:
        process.communicate()
        continue

    elif time > 86400 and process.poll() is None:
        process.communicate()
        process.kill()
