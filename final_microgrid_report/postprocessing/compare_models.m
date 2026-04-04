%% compare_models.m
% Compare Convex / Regularised / MIP for exp_01
% Reads outputs/results_*.txt, saves figures into figures/

clc; clear;

thisFile = mfilename("fullpath");
thisDir  = fileparts(thisFile);
projRoot = fileparts(thisDir);

expDir = fullfile(projRoot, "experiments", "exp_01_synthetic_baseline");
outDir = fullfile(expDir, "outputs");
figDir = fullfile(expDir, "figures");
if ~isfolder(figDir), mkdir(figDir); end

convPath = fullfile(outDir, "results_convex.txt");
regPath  = fullfile(outDir, "results_regularised.txt");
mipPath  = fullfile(outDir, "results_mip.txt");

assert(isfile(convPath), "Missing: %s", convPath);
assert(isfile(regPath),  "Missing: %s", regPath);
assert(isfile(mipPath),  "Missing: %s", mipPath);

C = readmatrix(convPath);
R = readmatrix(regPath);
M = readmatrix(mipPath);

% Columns:n
% [t load price Pgrid Pg Pc Pd SoC Pb gen_state gen_start u_c u_d]
t     = C(:,1);
load_ = C(:,2);
price = C(:,3);

Pgrid_C = C(:,4); Pg_C = C(:,5); Pc_C = C(:,6); Pd_C = C(:,7); SoC_C = C(:,8); Pb_C = C(:,9);
Pgrid_R = R(:,4); Pg_R = R(:,5); Pc_R = R(:,6); Pd_R = R(:,7); SoC_R = R(:,8); Pb_R = R(:,9);
Pgrid_M = M(:,4); Pg_M = M(:,5); Pc_M = M(:,6); Pd_M = M(:,7); SoC_M = M(:,8); Pb_M = M(:,9);


genState_R = R(:,10);  % s_g
genState_M = M(:,10);  % z_g
genStart_R = R(:,11);  % ds_abs
genStart_M = M(:,11);  % y_start

u_c = M(:,12);
u_d = M(:,13);

%% Plot: Grid import
figure('Position',[100 100 1100 420]);
plot(t, Pgrid_C, 'LineWidth', 1.2); hold on;
plot(t, Pgrid_R, 'LineWidth', 1.2);
plot(t, Pgrid_M, 'LineWidth', 1.2);
grid on;
xlabel('Hour'); ylabel('P_{grid} (kW)');
title('Grid Import Power Comparison');
legend('Convex','Regularised','MIP','Location','best');
saveas(gcf, fullfile(figDir, "Pgrid_comparison.png"));

%% Plot: Generator output
figure('Position',[100 100 1100 420]);
plot(t, Pg_C, 'LineWidth', 1.2); hold on;
plot(t, Pg_R, 'LineWidth', 1.2);
plot(t, Pg_M, 'LineWidth', 1.2);
grid on;
xlabel('Hour'); ylabel('P_{gen} (kW)');
title('Generator Output Comparison');
legend('Convex','Regularised','MIP','Location','best');
saveas(gcf, fullfile(figDir, "Pg_comparison.png"));

%% Plot: Battery net power
figure('Position',[100 100 1100 420]);
plot(t, Pb_C, 'LineWidth', 1.2); hold on;
plot(t, Pb_R, 'LineWidth', 1.2);
plot(t, Pb_M, 'LineWidth', 1.2);
yline(0,'--');
grid on;
xlabel('Hour'); ylabel('P_{batt} = P_d - P_c (kW)');
title('Battery Net Power Comparison');
legend('Convex','Regularised','MIP','Location','best');
saveas(gcf, fullfile(figDir, "BatteryPower_comparison.png"));

%% Plot: SoC
figure('Position',[100 100 1100 420]);
plot(t, SoC_C, 'LineWidth', 1.2); hold on;
plot(t, SoC_R, 'LineWidth', 1.2);
plot(t, SoC_M, 'LineWidth', 1.2);
grid on;
xlabel('Hour'); ylabel('SoC (kWh)');
title('SoC Comparison');
legend('Convex','Regularised','MIP','Location','best');
saveas(gcf, fullfile(figDir, "SoC_comparison.png"));

%% Quick “behaviour” metrics (no need to parse full costs)
epsP = 0.05;
onHours_M  = sum(genState_M > 0.5);
starts_M   = sum(genStart_M > 0.5);

onMass_R   = sum(genState_R);        % relaxed on-time mass
switch_R   = sum(genStart_R);        % relaxed switching mass

fprintf("\n==== Behaviour Metrics (proxy) ====\n");
fprintf("MIP   gen on-hours (z): %d / %d\n", onHours_M, length(t));
fprintf("MIP   gen starts   (y): %d\n", starts_M);
fprintf("REG   sum s_g           : %.4f\n", onMass_R);
fprintf("REG   sum |Δs_g|        : %.4f\n", switch_R);
fprintf("MIP   batt charge hrs   : %d / %d\n", sum(u_c), length(u_c));
fprintf("MIP   batt discharge hrs: %d / %d\n", sum(u_d), length(u_d));

fprintf("\n✅ Saved figures to:\n%s\n", figDir);

%% Plot: Generator ON/OFF state comparison
figure('Position',[100 100 1100 420]);

plot(t, genState_R, 'LineWidth', 1.8); hold on;
stairs(t, genState_M, 'LineWidth', 1.8);

ylim([-0.05, 1.05]);
yticks([0 0.2 0.4 0.6 0.8 1.0]);
grid on;

xlabel('Hour');
ylabel('Generator state');
title('Generator Commitment Comparison');
legend('Regularised: s_g','MIP: z_g','Location','best');

saveas(gcf, fullfile(figDir, "GeneratorState_comparison.png"));