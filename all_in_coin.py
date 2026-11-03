"""
All-in on a "good" coin: why a positive expected return can still lose money.

The bet: a fair coin (50/50).
  Heads -> your wealth is multiplied by 1.5  (+50%)
  Tails -> your wealth is multiplied by 0.6  (-40%)
You bet ALL your wealth on every toss.

Expected value per toss:  0.5 * 1.5 + 0.5 * 0.6 = 1.05   (+5%, looks great)
Typical growth per toss:  sqrt(1.5 * 0.6) = 0.949         (-5.1%, a loser)

Run:  python all_in_coin.py      (needs numpy and matplotlib)
"""

import math

import matplotlib.pyplot as plt
import numpy as np

# ---------------- Settings ----------------
N_PLAYERS = 10_000      # number of independent players
N_TOSSES = 100          # tosses per player
START = 100.0           # starting wealth
UP, DOWN = 1.5, 0.6     # wealth multipliers for heads and tails
P_HEADS = 0.5
SEED = 42               # fix the random numbers so results are reproducible

rng = np.random.default_rng(SEED)

# ---------------- Simulation ----------------
# One row per player, one column per toss: True = heads
heads = rng.random((N_PLAYERS, N_TOSSES)) < P_HEADS
factors = np.where(heads, UP, DOWN)

# Wealth after each toss = start * product of all factors so far
wealth = START * np.cumprod(factors, axis=1)
wealth = np.hstack([np.full((N_PLAYERS, 1), START), wealth])   # add toss 0
final = wealth[:, -1]

# ---------------- Theory ----------------
ev_factor = P_HEADS * UP + (1 - P_HEADS) * DOWN                   # 1.05
log_growth = P_HEADS * math.log(UP) + (1 - P_HEADS) * math.log(DOWN)
typical_factor = math.exp(log_growth)                             # 0.949

# Exact chance of ending above the start: you need enough heads k so that
# UP^k * DOWN^(n-k) > 1.
k_min = math.floor(N_TOSSES * math.log(1 / DOWN) / math.log(UP / DOWN)) + 1
p_ahead = sum(math.comb(N_TOSSES, k) for k in range(k_min, N_TOSSES + 1)) / 2 ** N_TOSSES

# ---------------- Results ----------------
print("Per toss")
print(f"  Expected (average) factor : {ev_factor:.4f}  ({ev_factor - 1:+.1%})")
print(f"  Typical (geometric) factor: {typical_factor:.4f}  ({typical_factor - 1:+.1%})")
print()
print(f"After {N_TOSSES} tosses, starting from {START:.0f}")
print(f"  Theoretical expected wealth : {START * ev_factor ** N_TOSSES:,.0f}")
print(f"  Simulated mean wealth       : {final.mean():,.0f}")
print(f"  Theoretical typical wealth  : {START * typical_factor ** N_TOSSES:,.2f}")
print(f"  Simulated median wealth     : {np.median(final):,.2f}")
print(f"  Players who lost money      : {np.mean(final < START):.1%}"
      f"   (theory: {1 - p_ahead:.1%}, need {k_min}+ heads out of {N_TOSSES} to be ahead)")
print(f"  Players who lost 99% or more: {np.mean(final < START / 100):.1%}")
top = np.sort(final)[::-1]
print(f"  Share of all money held by the luckiest 1% of players: "
      f"{top[: N_PLAYERS // 100].sum() / final.sum():.1%}")

# ---------------- Plots ----------------
t = np.arange(N_TOSSES + 1)
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(13, 5))

# Left: individual paths, simulated mean and median, and the theory lines
for i in range(60):
    ax1.plot(t, wealth[i], color="grey", lw=0.6, alpha=0.35)
ax1.plot(t, START * ev_factor ** t, "k--", lw=1.5, label="Expected value: 100 x 1.05^t")
ax1.plot(t, wealth.mean(axis=0), color="tab:blue", lw=2, label="Simulated mean of all players")
ax1.plot(t, np.median(wealth, axis=0), color="tab:red", lw=2, label="Simulated median player")
ax1.plot(t, START * typical_factor ** t, "k:", lw=1.5, label="Typical path: 100 x 0.949^t")
ax1.axhline(START, color="black", lw=0.8)
ax1.set_yscale("log")
ax1.set_xlabel("Toss")
ax1.set_ylabel("Wealth (log scale)")
ax1.set_title("All-in every toss: the average rises, the typical player falls")
ax1.legend(fontsize=8, loc="lower left")

# Right: where players end up. Final wealth depends only on the number of
# heads k, so there are only N_TOSSES + 1 possible values: one bar for each.
n_heads = heads.sum(axis=1)
counts = np.bincount(n_heads, minlength=N_TOSSES + 1)
k = np.arange(N_TOSSES + 1)
log_w = np.log10(START * UP ** k * DOWN ** (N_TOSSES - k))
step = np.log10(UP / DOWN)
colors = np.where(log_w > np.log10(START), "tab:green", "tab:red")
ax2.bar(log_w, counts, width=0.85 * step, color=colors, alpha=0.8)
seen = log_w[counts > 0]
ax2.set_xlim(seen.min() - step, seen.max() + step)
ax2.axvline(np.log10(START), color="black", lw=1.5, label="Starting wealth (100)")
ax2.set_xlabel("Final wealth (log10)")
ax2.set_ylabel("Number of players")
ax2.set_title(f"Final wealth after {N_TOSSES} tosses: {np.mean(final < START):.0%} lost money")
ax2.legend(fontsize=8)

plt.tight_layout()
plt.savefig("all_in_coin.png", dpi=150)
plt.show()
