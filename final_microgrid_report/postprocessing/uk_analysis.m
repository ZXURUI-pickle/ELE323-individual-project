%% plot_uk_validation.m
% Compare Convex / Regularised / MIP under UK price data for exp_03

clc; clear; close all;

%% locate folders
thisFile = mfilename("fullpath");
thisDir  = fileparts(thisFile);
projRoot = fileparts(thisDir);

expDir = fullfile(projRoot, "experiments", "exp_03_uk_validation");
outDir = fullfile(expDir, "outputs");
figDir = fullfile(expDir, "figures");

if ~isfolder(figDir)
    mkdir(figDir);
end

convPath = fullfile(outDir, "results_convex_uk.txt");
regPath  = fullfile(outDir, "results_regularised_uk.txt");
mipPath  = fullfile(outDir, "results_mip_uk.txt");

assert(isfile(convPath), "Missing file: %s", convPath);
assert(isfile(regPath),  "Missing file: %s", regPath);
assert(isfile(mipPath),  "Missing file: %s", mipPath);

C = readmatrix(convPath);
R = readmatrix(regPath);
M = readmatrix(mipPath);

% Columns:
% [t load price Pgrid Pg Pc Pd SoC Pb gen_state gen_start u_c u_d]

t     = C(:,1);
load_ = C(:,2);
price = C(:,3);

Pgrid_C = C(:,4); Pg_C = C(:,5); Pc_C = C(:,6); Pd_C = C(:,7); SoC_C = C(:,8); Pb_C = C(:,9);
Pgrid_R = R(:,4); Pg_R = R(:,5); Pc_R = R(:,6); Pd_R = R(:,7); SoC_R = R(:,8); Pb_R = R(:,9);
Pgrid_M = M(:,4); Pg_M = M(:,5); Pc_M = M(:,6); Pd_M = M(:,7); SoC_M = M(:,8); Pb_M = M(:,9);

genState_R = R(:,10);   % s_g
genStart_R = R(:,11);  % ds_abs

genState_M = M(:,10);   % z_g
genStart_M = M(:,11);  % y_start

u_c = M(:,12);
u_d = M(:,13);

%% 1. UK price and load
figure('Position',[100 100 1200 350]);
plot(t, price, 'LineWidth', 1.3);
grid on;
xlabel('Hour');
ylabel('Price (GBP/kWh)');
title('UK Electricity Price (168 h)');
saveas(gcf, fullfile(figDir, "uk_price_168h.png"));

figure('Position',[100 100 1200 350]);
plot(t, load_, 'LineWidth', 1.3);
grid on;
xlabel('Hour');
ylabel('load (kW)');
title('load (168 h)');
saveas(gcf, fullfile(figDir, "load_168h.png"));

%% 2. Grid import comparison
figure('Position',[100 100 1200 400]);
plot(t, Pgrid_C, 'LineWidth', 1.2); hold on;
plot(t, Pgrid_R, 'LineWidth', 1.2);
plot(t, Pgrid_M, 'LineWidth', 1.2);
grid on;
xlabel('Hour');
ylabel('P_{grid} (kW)');
title('Grid Import Comparison under UK Price');
legend('Convex','Regularised','MIP','Location','best');
saveas(gcf, fullfile(figDir, "uk_grid_import_comparison.png"));

%% 3. Generator output comparison
figure('Position',[100 100 1200 400]);
plot(t, Pg_C, 'LineWidth', 1.2); hold on;
plot(t, Pg_R, 'LineWidth', 1.2);
plot(t, Pg_M, 'LineWidth', 1.2);
grid on;
xlabel('Hour');
ylabel('P_g (kW)');
title('Generator Output Comparison under UK Price');
legend('Convex','Regularised','MIP','Location','best');
saveas(gcf, fullfile(figDir, "uk_generator_output_comparison.png"));

%% 4. Battery net power comparison
figure('Position',[100 100 1200 400]);
plot(t, Pb_C, 'LineWidth', 1.2); hold on;
plot(t, Pb_R, 'LineWidth', 1.2);
plot(t, Pb_M, 'LineWidth', 1.2);
yline(0,'--');
grid on;
xlabel('Hour');
ylabel('P_b = P_d - P_c (kW)');
title('Battery Net Power Comparison under UK Price');
legend('Convex','Regularised','MIP','Location','best');
saveas(gcf, fullfile(figDir, "uk_battery_power_comparison.png"));

%% 5. SoC comparison
figure('Position',[100 100 1200 400]);
plot(t, SoC_C, 'LineWidth', 1.2); hold on;
plot(t, SoC_R, 'LineWidth', 1.2);
plot(t, SoC_M, 'LineWidth', 1.2);
grid on;
xlabel('Hour');
ylabel('SoC (kWh)');
title('Battery SoC Comparison under UK Price');
legend('Convex','Regularised','MIP','Location','best');
saveas(gcf, fullfile(figDir, "uk_soc_comparison.png"));

%% 6. Generator state comparison
figure('Position',[100 100 1200 350]);
plot(t, genState_R, 'LineWidth', 1.2); hold on;
stairs(t, genState_M, 'LineWidth', 1.2);
grid on;
xlabel('Hour');
ylabel('Generator state');
title('Generator Commitment Comparison');
legend('Regularised s_g','MIP z_g','Location','best');
saveas(gcf, fullfile(figDir, "uk_generator_state_comparison.png"));

%% 7. Behaviour metrics
fprintf("\n==== EXP03 UK VALIDATION METRICS ====\n");
fprintf("MIP gen on-hours     = %d / %d\n", sum(genState_M > 0.5), length(t));
fprintf("MIP gen starts       = %d\n", sum(genStart_M > 0.5));
fprintf("REG sum s_g          = %.4f\n", sum(genState_R));
fprintf("REG sum |Δs_g|       = %.4f\n", sum(genStart_R));
fprintf("MIP batt charge hrs  = %d / %d\n", sum(u_c), length(u_c));
fprintf("MIP batt discharge   = %d / %d\n", sum(u_d), length(u_d));

fprintf("\nSaved figures to:\n%s\n", figDir);