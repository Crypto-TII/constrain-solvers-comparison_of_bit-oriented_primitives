# Automatic Differential Cryptanalysis 

This repository contains the scripts that can be used to reproduce the 3 
tasks contained in the paper: [Differential cryptanalysis with SAT, SMT, MILP,
and CP: a detailed comparison for bit-oriented primitives]().

## Run the tests

Tests are completely automatized and `csv` files will be produced as output.

- CLAASP: the tests contained in this repository are
  intended to be run using the [Cryptographic Library for the Automated 
  Analysis of Symmetric Primitives](https://github.com/Crypto-TII/claasp). 
  In order to be updated with the last fixes, clone the repository:
  ```bash
  $ git clone https://github.com/Crypto-TII/claasp
  ```
- Get this repository: once you have downloaded the CLAASP
  repository, you must clone this repository:
  ```bash
  $ cd claasp
  $ git clone https://github.com/Crypto-TII/constrain-solvers-comparison_of_bit-oriented_primitives.git scripts
  ```
  Note that the second command will clone the repository into a directory called
  `scripts`.
- Installing the library: CLAASP is built on top of [SageMath](https://github.com/sagemath/sage),
  therefore you must install it first. You can install all the dependencies
  in your machine or use a Docker image. For a quick start, read
  [`docs/USER_GUIDE.md`](docs/USER_GUIDE.md#docker).
  The latter is the preferable method.
- You are ready to go. Inside the container created for CLAASP, type `sage
  scripts/<test-name>`. You should be able to see logs and output files in the
  scripts directory.

### Tasks

The tasks are the following ones:

1. the task 1 is the search for an optimal differential trail; note that 
   there are easy and difficult instances;
2. the task 2 is the enumeration of all optimal trails;
3. the task 3 is the estimation of the probability of a differential.

Every task has its own single model version and multiple model one. If 
you have enough computational resources, you can go straight for the 
multiple one.

- **Single model** - in order to run tests for a single model just type:
  ```bash
  # sage scripts/task_STRING.sage -m MODEL
  ```
  + (**mandatory**) replace `STRING` with `1_easy`, `1_difficult`, `2` or `3`;
  + (**optional**) replace `MODEL` with `sat`, `smt`, `milp` or 
    `cp`. The default is `sat`.
- **Multiple models** - if you have enough computational resources, you can go
  straight for parallelization:
  ```bash
  # sage scripts/task_STRING_parallelization.sage -m MODELS
  ```
  + (**mandatory**) replace `STRING` with `1_easy`, `1_difficult`, `2` or `3`;
  + (**optional**) replace `MODELS` with models you want to test. For 
    instance, say that you want just tests for SAT and CP, you need to run:
    ```bash
    # sage scripts/task_STRING_parallelization.sage -m sat cp
    ```
    The defaults are all four models.

## Docker (optional)

In order to not create too many containers, instead of running the CLAASP
`Makefile`
recipes, create an image:
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
You have now to install the library. Since at this point you are inside the
Docker container, you can run:
```
# make install
```
If you exit the container and need to go back to it, you just need to type
the Docker start command. In the case you have pulled the CLAASP repository
for updating purposes and the `Dockerfile` has not been changed, you can
safely start the `tester` container and re-run a `make install` command.