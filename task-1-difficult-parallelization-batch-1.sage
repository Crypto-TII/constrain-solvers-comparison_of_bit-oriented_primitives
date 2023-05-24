from subprocess import Popen
import os
from time import sleep
import sys
sys.path.insert(0, "/home/sage/claasp")
from scripts.sage_scripts import famous-results, constants
import argparse


if os.path.exists('LOGS/') == False:
    os.makedirs('LOGS/')


if os.path.exists('LOGS/task-1-difficult/') == False:
    os.makedirs('LOGS/task-1-difficult/')
    
commands = []
for model in ['milp']:
    for solver in constants.MODEL_LIST[model]['solver_list']:
        for cipher in ['speck_block_cipher.py']:
            for param in famous_results.DIFFERENTIAL_TRAILS[cipher]:
                if ('block_bit_size',64) in param:
                    continue
                rounds, weight = famous_results.DIFFERENTIAL_TRAILS[cipher][param]
                cmd_list = ['sage', 'scripts/sage_scripts/task-1-difficult.sage', '-m', model, '-s', solver, '-c', cipher, '-p', str(dict(param)), '-r', str(rounds), '-w', str(weight)]                              
                commands.append(cmd_list)
    
procs = [Popen(i, stdout=open(f'LOGS/task-1-difficult/{i[3]}.txt','a'), stderr=open(f'LOGS/task-1-difficult/{i[3]}_ERR.txt','a')) for i in commands]
    
time=0

for p in procs:        
    while p.poll() == None:    
        if time > 86400:
            break
        sleep(10)
        time+=10
        
    if p.poll() != None:
        p.communicate()
        continue

    elif time > 86400 and p.poll()==None:
        p.communicate()
        p.kill()
 

commands = []
for model in ['cp']:
    for solver in constants.MODEL_LIST[model]['solver_list']:
        for cipher in ['speck_block_cipher.py']:
            for param in famous_results.DIFFERENTIAL_TRAILS[cipher]:
                if ('block_bit_size',32) not in param:
                    continue
                rounds, weight = famous_results.DIFFERENTIAL_TRAILS[cipher][param]
                cmd_list = ['sage', 'scripts/sage_scripts/task-1-difficult.sage', '-m', model, '-s', solver, '-c', cipher, '-p', str(dict(param)), '-r', str(rounds), '-w', str(weight)]                  
                commands.append(cmd_list)
    
procs = [Popen(i, stdout=open(f'LOGS/task-1-difficult/{i[3]}.txt','a'), stderr=open(f'LOGS/task-1-difficult/{i[3]}_ERR.txt','a')) for i in commands]
    
time=0
    
for p in procs:
    while p.poll() == None:    
        if time > 86400:
            break
        sleep(10)
        time+=10
        
    if p.poll() != None:
        p.communicate()
        continue

    elif time > 86400 and p.poll()==None:
        p.communicate()
        p.kill()


commands = []
for model in ['cp']:
    for solver in constants.MODEL_LIST[model]['solver_list']:
        for cipher in ['speck_block_cipher.py']:
            for param in famous_results.DIFFERENTIAL_TRAILS[cipher]:
                if ('block_bit_size',64) not in param:
                    continue
                rounds, weight = famous_results.DIFFERENTIAL_TRAILS[cipher][param]
                cmd_list = ['sage', 'scripts/sage_scripts/task-1-difficult.sage', '-m', model, '-s', solver, '-c', cipher, '-p', str(dict(param)), '-r', str(rounds), '-w', str(weight)]                        
                commands.append(cmd_list)
    
procs = [Popen(i, stdout=open(f'LOGS/task-1-difficult/{i[3]}.txt','a'), stderr=open(f'LOGS/task-1-difficult/{i[3]}_ERR.txt','a')) for i in commands]
    
time=0
    
for p in procs:        
    while p.poll() == None:    
        if time > 86400:
            break
        sleep(10)
        time+=10
        
    if p.poll() != None:
        p.communicate()
        continue

    elif time > 86400 and p.poll()==None:
        p.communicate()
        p.kill()

