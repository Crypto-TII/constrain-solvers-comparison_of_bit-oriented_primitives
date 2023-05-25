from subprocess import Popen
import psutil
import os
from time import sleep
from claasp.utils.sage_scripts import get_ciphers, get_cipher_type

def kill_process_and_children(pid, sig=15):
    try:
        proc = psutil.Process(pid)
    except psutil.NoSuchProcess as e:
        print('couldnt kill process since it no longer exists')
        return
    
    for child_process in proc.children(recursive=True):
        child_process.send_signal(sig)
    proc.send_signal(sig)


if os.path.exists('LOGS/') == False:
    os.makedirs('LOGS/')


if os.path.exists('LOGS/task-1-easy/') == False:
    os.makedirs('LOGS/task-1-easy/')


commands = []
for model in ['cp','sat','smt','milp']:
    cmd_list = ['sage', 'scripts/task-1-easy.sage', '-m', model]
    commands.append(cmd_list)
        
procs = [Popen(i, stdout=open(f'LOGS/task-1-easy/{i[3]}.txt','a'), stderr=open(f'LOGS/task-1-easy/{i[3]}_ERR.txt','a')) for i in commands]
time = 0.0
         
while len(procs) > 0:
    for p in procs:
        if p.poll() == None and time < 259200.0:
            sleep(1)
            time+=1
        if p.poll() != None:
            p.communicate()
            procs.remove(p)
        if p.poll() == None and time == 259200.0:
            print('killing a process, timeout expired')
            kill_process_and_children(p.pid)
            procs.remove(p)
             
