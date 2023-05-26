import os
import psutil

from subprocess import Popen
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


if not os.path.exists('LOGS/'):
    os.makedirs('LOGS/')


if not os.path.exists('LOGS/task_2/'):
    os.makedirs('LOGS/task_2/')


commands = []
for model in ['sat', 'smt', 'milp', 'cp']:
    cmd_list = ['sage', 'scripts/task_2.sage', '-m', model]
    commands.append(cmd_list)

processes = [
    Popen(
        i,
        stdout=open(f'LOGS/task_2/{i[3]}.txt', 'a'),
        stderr=open(f'LOGS/task_2/{i[3]}_ERR.txt', 'a')) for i in commands]

time = 0.0

while len(processes) > 0:
    for process in processes:
        if (process.poll() is None) and (time < 259200.0):
            sleep(1)
            time += 1
        if process.poll() is not None:
            process.communicate()
            processes.remove(process)
        if (process.poll() is None) and (time == 259200.0):
            print('killing a process, timeout expired')
            kill_process_and_children(process.pid)
            processes.remove(process)
