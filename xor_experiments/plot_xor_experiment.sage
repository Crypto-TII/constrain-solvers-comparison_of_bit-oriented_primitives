import numpy as np
import sage.all
import matplotlib.pyplot as plt


MODELS = ["exhaustive", "sequential", "modulo"]


aes_res = load('aes_xor_experiments_timeout20000.sobj')
AES_ROUND_MAX = 11
ROUND_RANGE = range(1, AES_ROUND_MAX)


for state_size_ctr in [2, 3, 4]:
    fig, axs = plt.subplots(4, sharex=True, sharey=False)
    fig.suptitle(f"AES (state_size={state_size_ctr})")
    c = 0
    for word_size_ctr in [2, 3, 4, 8]:
        axs[c].set_title(f"word_size={word_size_ctr}")
        axs[c].set(xlabel="Rounds", ylabel="Solving time (s)")
        axs[c].grid()
        sym = {"exhaustive": '-', "sequential": '--', "modulo": ':'}
        for tested_model in MODELS:
            # plt.semilogy(ROUND_RANGE, res[tested_model][state_size_ctr][word_size_ctr][:AES_ROUND_MAX-1], label=tested_model)
            axs[c].plot(ROUND_RANGE, aes_res[tested_model][state_size_ctr][word_size_ctr][:AES_ROUND_MAX - 1],
                        sym[tested_model],
                     label=tested_model)
        c += 1
        fig.legend(MODELS, loc='lower right')
    fig.tight_layout(pad=1)
    fig.savefig(f'aes_{state_size_ctr}x{state_size_ctr}.pdf')
plt.tight_layout()
plt.show()


midori_res = load('midori64_xor_experiments_timeout10000.sobj')
MIDORI_MAX_ROUND = 7
ROUND_RANGE = range(1, MIDORI_MAX_ROUND)

for tested_model in MODELS:
    plt.semilogy(ROUND_RANGE, midori_res[tested_model][:MIDORI_MAX_ROUND - 1], label=tested_model)

plt.legend(loc="lower right")
plt.ylabel("Solving time (s)")
plt.xlabel("Rounds")
plt.xticks(np.arange(min(ROUND_RANGE), max(ROUND_RANGE) + 1, 1.0))
plt.title("Midori64 xor experiment")
plt.grid()
plt.savefig('midori64.pdf')
plt.show()

