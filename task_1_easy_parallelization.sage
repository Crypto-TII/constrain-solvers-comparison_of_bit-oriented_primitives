import os
import argparse
import psutil

from subprocess import Popen
from time import sleep
from claasp.utils.sage_scripts import get_ciphers, get_cipher_type


def kill_process_and_children(pid, sig=15):
    try:
        proc = psutil.Process(pid)
    except psutil.NoSuchProcess as e:
        print('couldn\'t kill process since it no longer exists')
        return

    for child_process in proc.children(recursive=True):
        child_process.send_signal(sig)
    proc.send_signal(sig)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='parallelization of task 1')
    parser.add_argument('--models', '-m', action="extend", nargs='*',
                        default=['sat', 'smt', 'milp', 'cp'])
    args = parser.parse_args()

    if not os.path.exists('scripts/LOGS/task_1_easy/'):
        os.makedirs('scripts/LOGS/task_1_easy/')

    processes = [
        Popen(
            ['sage', 'scripts/task_1_easy.sage', '-m', model],
            stdout=open(f'scripts/LOGS/task_1_easy/{model}.txt', 'a'),
            stderr=open(f'scripts/LOGS/task_1_easy/{model}_ERR.txt', 'a')) for model in args.models]

    time = 0.0

    while len(processes) > 0:
        for process in processes:
            if (process.poll() is None) and (time < 259200.0):
                sleep(1)
                time += 1
            if process.poll() is not None:
                process.communicate()
                processes.remove(process)
            if (process.poll() is None) and (time >= 259200.0):
                print('killing a process, timeout expired')
                kill_process_and_children(process.pid)
                processes.remove(process)
