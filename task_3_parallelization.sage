import os
import sys
from subprocess import Popen

import constants

sys.path.insert(0, "/home/sage/claasp")

if not os.path.exists('scripts/LOGS/task_3'):
    os.makedirs('scripts/LOGS/task_3')

commands = []
for cipher in ('speck_block_cipher.py', 'midori_block_cipher.py'):
    for model in ('sat', 'smt', 'milp', 'cp'):
        for solver in constants.MODEL_LIST[model]['solver_list']:
            cmd = ['sage', 'scripts/task_3.sage', '-m', model, '-s', solver,
                   '-c', cipher, '-r', str(constants.fixed_differential[cipher][4])]
            commands.append(cmd)

processes = [
    Popen(
        i,
        stdout=open(f'scripts/LOGS/task_3/{i[7].split("_")[0]}.txt', 'a'),
        stderr=open(f'scripts/LOGS/task_3/{i[7].split("_")[0]}_ERR.txt', 'a')) for i in commands]

for process in processes:
    process.communicate()
