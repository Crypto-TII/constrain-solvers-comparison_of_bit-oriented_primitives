
DIFFERENTIAL_TRAILS = {
        'speck_block_cipher.py' : { 
                    (('block_bit_size', 32), ('key_bit_size', 64)) : [9,30],
                    (('block_bit_size', 64), ('key_bit_size', 128)) : [13, 55],
                    (('block_bit_size', 128), ('key_bit_size', 256)) : [15, 115]},
        'simon_block_cipher.py' : {
            (('block_bit_size', 32), ('key_bit_size', 64)) : [12, 34],
            (('block_bit_size', 64), ('key_bit_size', 128)) : [19, 64],
            (('block_bit_size', 128), ('key_bit_size', 256)) : [37, 128]},
        'ascon_sbox_sigma_permutation.py' : { (()) : [3,190]},
        'present_block_cipher.py' : { (('key_bit_size', 80),) : [18,78]},
        'keccak_permutation.py' : { 
            (('word_size' , 4),) : [6,85],
            (('word_size' , 8),) : [5,108],
            (('word_size' , 16),) : [5,84],
            (('word_size' , 32),) : [5,432],
            (('word_size' , 64),) : [5,510]},
        'chacha_stream_cipher.py' : { (()) : [2,24]}
        }
                    
