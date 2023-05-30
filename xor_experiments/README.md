# MILP XOR modeling

### Content

This folder contains the data of our experiment on `Midori64` and different instances of `AES` (with `state size` in `[2,3,4]`, and `word size` in `[2,3,4,8]`)

We considered the 3 following models

- `sequential`: this model generates 4 inequalities for the 2-input XOR and then performs the k-XOR sequentially,
  storing the intermediate result of each 2-XOR in a binary intermediate variable

- `modulo`: this model generates 1 equality to model any k-input XOR as sum(x_i) + y = 2 * d, where d is a dummy integer
  variable.
- `exhaustive`: this model generates 2^k inequalities to exclude all impossible (k+1)-tuple (x_0,...x_{k-1}, y)

### Usage

To generate the plot: 
````
sage plot_xor_experiment.sage
