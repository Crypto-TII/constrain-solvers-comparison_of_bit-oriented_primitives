from subprocess import Popen
import psutil
import os
from time import sleep
import sys
sys.path.insert(0, "/home/sage/tii-cryptalib")
from scripts.sage_scripts import famous_results, constants
import argparse
from claasp.utils.sage_scripts import get_ciphers, get_cipher_type


if os.path.exists('LOGS/task-3') == False:
    os.makedirs('LOGS/task-3')



commands = []

commands = []
for cipher in ['speck_block_cipher.py', 'midori_block_cipher']:
    for model in ['sat', 'smt', 'cp', 'milp']:
        for solver in constants.MODEL_LIST[model]['solver_list']:
            cmd = ['sage', 'scripts/task-3.sage', '-m', model, '-s', solver, '-c' ,cipher, '-r', str(constants.fixed_differential[cipher][4])]
            commands.append(cmd)

procs = [Popen(i, stdout=open(f'LOGS/task-3/{i[7].split("_")[0]}.txt','a'), stderr=open(f'LOGS/task-3/{i[7].split("_")[0]}_ERR.txt','a')) for i in commands]

for p in procs:
    p.communicate()




