% =====================================================================
%  All-in on a "good" coin: why a positive expected return can still
%  lose money.
%
%  The bet: a fair coin (50/50).
%    Heads -> wealth is multiplied by 1.5  (+50%)
%    Tails -> wealth is multiplied by 0.6  (-40%)
%  You bet ALL your wealth on every toss.
%
%  Expected value per toss:  0.5*1.5 + 0.5*0.6 = 1.05   (+5%, looks great)
%  Typical growth per toss:  sqrt(1.5*0.6)     = 0.949  (-5.1%, a loser)
%
%  Run: all_in_coin   (base MATLAB, R2016b or later; no toolboxes needed)
% =====================================================================

clear; clc; close all;

% ---------------- Settings ----------------
nPlayers = 10000;      % number of independent players
nTosses  = 100;        % tosses per player
start    = 100;        % starting wealth
up       = 1.5;        % multiplier on heads
down     = 0.6;        % multiplier on tails
pHeads   = 0.5;
rng(42);               % fix the random numbers so results are reproducible

% ---------------- Simulation ----------------
% One row per player, one column per toss: true = heads
heads   = rand(nPlayers, nTosses) < pHeads;
factors = down + (up - down) .* heads;        % 1.5 for heads, 0.6 for tails

% Wealth after each toss = start * product of all factors so far
wealth = start * cumprod(factors, 2);
wealth = [start * ones(nPlayers, 1), wealth];  % add toss 0
final  = wealth(:, end);

% ---------------- Theory ----------------
evFactor      = pHeads * up + (1 - pHeads) * down;                  % 1.05
logGrowth     = pHeads * log(up) + (1 - pHeads) * log(down);
typicalFactor = exp(logGrowth);                                     % 0.949

% Exact chance of ending above the start: you need enough heads k so that
% up^k * down^(n-k) > 1
kMin   = floor(nTosses * log(1 / down) / log(up / down)) + 1;
kAll   = 0:nTosses;
logPmf = gammaln(nTosses + 1) - gammaln(kAll + 1) - gammaln(nTosses - kAll + 1) ...
         + nTosses * log(0.5);                 % binomial probabilities, fair coin
pAhead = sum(exp(logPmf(kAll >= kMin)));

% ---------------- Results ----------------
fprintf('Per toss\n');
fprintf('  Expected (average) factor : %.4f  (%+.1f%%)\n', evFactor, 100 * (evFactor - 1));
fprintf('  Typical (geometric) factor: %.4f  (%+.1f%%)\n\n', typicalFactor, 100 * (typicalFactor - 1));
fprintf('After %d tosses, starting from %d\n', nTosses, start);
fprintf('  Theoretical expected wealth : %12.0f\n', start * evFactor ^ nTosses);
fprintf('  Simulated mean wealth       : %12.0f\n', mean(final));
fprintf('  Theoretical typical wealth  : %12.2f\n', start * typicalFactor ^ nTosses);
fprintf('  Simulated median wealth     : %12.2f\n', median(final));
fprintf('  Players who lost money      : %.1f%%   (theory: %.1f%%, need %d+ heads out of %d)\n', ...
        100 * mean(final < start), 100 * (1 - pAhead), kMin, nTosses);
fprintf('  Players who lost 99%% or more: %.1f%%\n', 100 * mean(final < start / 100));
sorted = sort(final, 'descend');
fprintf('  Share of all money held by the luckiest 1%% of players: %.1f%%\n', ...
        100 * sum(sorted(1:nPlayers / 100)) / sum(final));

% ---------------- Plots ----------------
t = 0:nTosses;
figure('Position', [100 100 1300 500]);

% Left: individual paths, simulated mean and median, and the theory lines
subplot(1, 2, 1); hold on;
semilogy(t, wealth(1:60, :)', 'Color', [0.6 0.6 0.6 0.35], 'LineWidth', 0.6);
h1 = semilogy(t, start * evFactor .^ t, 'k--', 'LineWidth', 1.5);
h2 = semilogy(t, mean(wealth, 1), 'Color', [0.12 0.47 0.71], 'LineWidth', 2);
h3 = semilogy(t, median(wealth, 1), 'Color', [0.84 0.15 0.16], 'LineWidth', 2);
h4 = semilogy(t, start * typicalFactor .^ t, 'k:', 'LineWidth', 1.5);
yline(start, 'k');
set(gca, 'YScale', 'log'); box on;
xlabel('Toss'); ylabel('Wealth (log scale)');
title('All-in every toss: the average rises, the typical player falls');
legend([h1 h2 h3 h4], {'Expected value: 100 x 1.05^t', 'Simulated mean of all players', ...
        'Simulated median player', 'Typical path: 100 x 0.949^t'}, ...
       'Location', 'southwest', 'FontSize', 8);

% Right: where players end up. Final wealth depends only on the number of
% heads k, so there are only nTosses + 1 possible values: one bar for each.
subplot(1, 2, 2); hold on;
nHeads = sum(heads, 2);
counts = accumarray(nHeads + 1, 1, [nTosses + 1, 1])';
logW   = log10(start * up .^ kAll .* down .^ (nTosses - kAll));
step   = log10(up / down);
gain   = logW > log10(start);
bar(logW(~gain), counts(~gain), 0.85, 'FaceColor', [0.84 0.15 0.16], 'EdgeColor', 'none');
bar(logW(gain),  counts(gain),  0.85, 'FaceColor', [0.17 0.63 0.17], 'EdgeColor', 'none');
xline(log10(start), 'k', 'LineWidth', 1.5);
seen = logW(counts > 0);
xlim([min(seen) - step, max(seen) + step]); box on;
xlabel('Final wealth (log10)'); ylabel('Number of players');
title(sprintf('Final wealth after %d tosses: %.0f%% lost money', nTosses, 100 * mean(final < start)));
legend({'Lost money', 'Made money', 'Starting wealth (100)'}, 'FontSize', 8);

saveas(gcf, 'all_in_coin.png');
