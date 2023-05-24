
EXCLUDE_LIST = ['keccak_invertible_permutation.py', 'grain_core_permutation.py','aes_block_cipher.py', 'sparx_block_cipher.py', 'twofish_block_cipher.py',"__init__.py","lowmc_block_cipher.py",'chacha_stream_cipher.py', "sparkle_permutation.py","spongent_pi_permutation.py","raiden_block_cipher.py", "constant_block_cipher.py", "photon_permutation.py", "spongent_pi_precomputation_permutation.py", "lowmc_constants_block_cipher.py", "lowmc_generate_matrices_block_cipher.py", "fancy_block_cipher.py", "identity_block_cipher.py", "tinyjambu_permutation.py", "tinyjambu_32bits_word_permutation.py"]

MODEL_LIST = {
    'sat' : {
        'solver_list' : ['kissat', 'cadical', 'minisat', 'mathsat', 'yices-sat', 'cryptominisat', 'glucose-syrup'],
        'exclude_list' : EXCLUDE_LIST + ['chacha_stream_cipher.py','sha1_hash_function.py', 'sha2_hash_function.py','blake2_hash_function.py', 'gift_sbox_permutation.py','skinny_block_cipher.py', 'des_block_cipher.py', 'des_exact_key_length_block_cipher.py', 'keccak_invertible_permutation.py', 'chacha_permutation.py']
        }, 
    'cp' : {
        'solver_list' : ['Chuffed', 'Gecode', 'Choco', 'ortools'],
        'exclude_list' : EXCLUDE_LIST
        },
    'smt' : {
        'solver_list' : ['yices-smt2', 'mathsat', 'z3'],
        'exclude_list' : EXCLUDE_LIST + ['des_block_cipher.py', 'gift_sbox_permutation.py', 'skinny_block_cipher.py', 'keccak_invertible_permutation.py', 'des_exact_key_length_block_cipher.py']
        }, 
    'milp' : {
        'solver_list' : ['Gurobi', 'GLPK'],
        'exclude_list' : EXCLUDE_LIST + ['des_exact_key_lenght_block_cipher.py']
        } 
    }

fixed_differential = {
        'speck_block_cipher.py' : [0x4000409210420040, 0x8080a0808481a4a0,52,66,10,64,128],
        'midori_block_cipher.py' : [0x0002002000002000, 0x0000022222022022,0, 63,4,64,128],
        'simon_block_cipher.py' : [0x8, 0x08000000,38, 52, 14,32,64]
        }

