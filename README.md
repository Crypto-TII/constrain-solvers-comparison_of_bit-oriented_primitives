# Automatic Differential Cryptanalysis 

This repository contains the scripts that can be used to reproduce the 3 
tasks contained in the paper: [Differential cryptanalysis with SAT, SMT, MILP,
and CP: a detailed comparison for bit-oriented primitives]().

## Run the tests

Tests are completely automatized and `csv` files will be produced as output.

- CLAASP (**mandatory**): the tests contained in this repository are 
  intended to be run using the [Cryptographic Library for the Automated 
  Analysis of Symmetric Primitives](https://github.com/Crypto-TII/claasp). 
  Thus, you have to install it. In order to be updated with the last fixes, 
  clone the main branch:
  ```bash
  $ git clone -b main --single-branch https://github.com/Crypto-TII/claasp
  ```
  Thus, you can follow the user guide contained in the file
  `docs/USER_GUIDE.md`. Installation using Docker is the preferable method.
- Using Docker (**optional**): in order to not create too many containers, 
  instead of running the `Makefile` recipe, create an image:
  ```bash
  $ docker build -f docker/Dockerfile -t claasp .
  ```
  create a container using the image just created:
  ```bash
  $ docker create -i --name tester -v `pwd`:/home/sage/tii-claasp -t claasp /bin/bash
  ```
  and start the container:
  ```bash
  $ docker start -ia tester
  ```
  You should now install the library. Since at this point you are inside the 
  Docker container, you must run:
  ```
  # make install
  ```
  If you exit the container and need to go back to it, you just need to type 
  the Docker start command. In the case you have pulled the CLAASP repo to 
  update and the `Dockerfile` has not been changed, you can safely start the 
  container and re-run a `make install` command. 
- Create directory (**mandatory**): once you have downloaded the CLAASP 
  repository, you cna clone this repository:
  ```bash
  $ cd claasp
  $ git clone https://github.com/Crypto-TII/constrain-solvers-comparison_of_bit-oriented_primitives.git scripts
  ```
- You are ready to go. Just type `sage <test-name>`. You should be able to 
  see logs and output files.