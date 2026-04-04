%% plot_tradeoff_regularised.m
% Trade-off analysis for regularised convex parameter sweeps
% Author: Xurui project script
%
% This script:
% 1) reads gamma-sweep and beta-sweep result files
% 2) compares them against a MIP reference
% 3) computes summary metrics
% 4) plots parameter-metric curves and trade-off figures

clc; clear; close all;

%% ===============================
%% 0. Locate folders
%% ===============================
thisFile = mfilename("fullpath");
thisDir  = fileparts(thisFile);
projRoot = fileparts(thisDir);

outDir = fullfile(projRoot,"experiments","exp_02_parameter_sweep","outputs");
figDir = fullfile(projRoot,"experiments","exp_02_parameter_sweep","figures","tradeoff");

if ~isfolder(figDir)
    mkdir(figDir);
end

%% ===============================
%% 1. User settings
%% ===============================
% ---- sweep lists ----
k_list = [0.001 0.003 0.01 0.03 0.1 0.3 1 3 10 100 1000];
R_list = [0.001 0.003 0.01 0.03 0.1 0.3 1 3 10 100 1000];

% ---- result file names ----
mipFile = fullfile(projRoot,"experiments","exp_01_synthetic_baseline","outputs","results_mip.txt");

% ---- column indices in result files ----
col_t     = 1;
col_load  = 2;
col_price = 3;
col_Pgrid = 4;
col_Pg    = 5;
col_sg    = 10;   % if not present, sg will be approximated by Pg/Pg_max

% ---- model parameters ----
dt      = 1.0;    % hour
Pg_max  = 5.0;    % kW
c_fuel  = 0.1;   % £/kWh

% If your regularised objective is:
% sum_t [ dt*price*Pgrid + dt*c_fuel*Pg + dt*gamma*sg ] + beta*sum|dsg|
% then this script matches that structure.

%% ===============================
%% 2. Read MIP reference
%% ===============================
if ~isfile(mipFile)
    error("Missing MIP file: %s", mipFile);
end

A_mip = readmatrix(mipFile);

t_mip = A_mip(:,col_t);
Pg_mip = A_mip(:,col_Pg);

if size(A_mip,2) >= col_sg
    sg_mip = A_mip(:,col_sg);
else
    sg_mip = min(max(Pg_mip ./ Pg_max,0),1);
end

N_mip = length(t_mip);

%% ===============================
%% 3. Helper function for metrics
%% ===============================
% This local function is placed at end of script in MATLAB versions that
% support local functions in scripts.
%
% Returned metrics:
% total_cost      = grid cost + fuel cost + regularisation terms
% gen_energy      = sum(Pg)*dt
% usage_mass      = sum(sg)*dt
% switching_sg    = sum(abs(diff(sg)))
% switching_pg    = sum(abs(diff(Pg)))
% dist_mip_pg     = sum(abs(Pg - Pg_mip))
% dist_mip_sg     = sum(abs(sg - sg_mip))
% peak_pg         = max(Pg)

%% ===============================
%% 4. Gamma sweep metrics
%% ===============================
gamma_total_cost   = nan(size(k_list));
gamma_gen_energy   = nan(size(k_list));
gamma_usage_mass   = nan(size(k_list));
gamma_switching_sg = nan(size(k_list));
gamma_switching_pg = nan(size(k_list));
gamma_dist_mip_pg  = nan(size(k_list));
gamma_dist_mip_sg  = nan(size(k_list));
gamma_peak_pg      = nan(size(k_list));

for i = 1:length(k_list)

    gamma = k_list(i);
    fileName = sprintf("results_reg_k_%g.txt",gamma);
    filePath = fullfile(outDir,fileName);

    if ~isfile(filePath)
        warning("Missing file: %s", filePath);
        continue
    end

    A = readmatrix(filePath);

    if size(A,1) ~= N_mip
        warning("Length mismatch in gamma file: %s", fileName);
        continue
    end

    [total_cost, gen_energy, usage_mass, switching_sg, switching_pg, ...
        dist_mip_pg, dist_mip_sg, peak_pg] = ...
        compute_metrics(A, gamma, 0, dt, c_fuel, Pg_max, ...
                        col_t, col_price, col_Pgrid, col_Pg, col_sg, ...
                        Pg_mip, sg_mip);

    gamma_total_cost(i)   = total_cost;
    gamma_gen_energy(i)   = gen_energy;
    gamma_usage_mass(i)   = usage_mass;
    gamma_switching_sg(i) = switching_sg;
    gamma_switching_pg(i) = switching_pg;
    gamma_dist_mip_pg(i)  = dist_mip_pg;
    gamma_dist_mip_sg(i)  = dist_mip_sg;
    gamma_peak_pg(i)      = peak_pg;
end

%% ===============================
%% 5. Beta sweep metrics
%% ===============================
beta_total_cost   = nan(size(R_list));
beta_gen_energy   = nan(size(R_list));
beta_usage_mass   = nan(size(R_list));
beta_switching_sg = nan(size(R_list));
beta_switching_pg = nan(size(R_list));
beta_dist_mip_pg  = nan(size(R_list));
beta_dist_mip_sg  = nan(size(R_list));
beta_peak_pg      = nan(size(R_list));

for i = 1:length(R_list)

    beta = R_list(i);
    fileName = sprintf("results_reg_R_%g.txt",beta);
    filePath = fullfile(outDir,fileName);

    if ~isfile(filePath)
        warning("Missing file: %s", filePath);
        continue
    end

    A = readmatrix(filePath);

    if size(A,1) ~= N_mip
        warning("Length mismatch in beta file: %s", fileName);
        continue
    end

    % Here gamma is assumed fixed at the default value used in your beta sweep.
    % Change this if your beta sweep used another gamma.
    gamma_fixed_for_beta_sweep = 0.08;

    [total_cost, gen_energy, usage_mass, switching_sg, switching_pg, ...
        dist_mip_pg, dist_mip_sg, peak_pg] = ...
        compute_metrics(A, gamma_fixed_for_beta_sweep, beta, dt, c_fuel, Pg_max, ...
                        col_t, col_price, col_Pgrid, col_Pg, col_sg, ...
                        Pg_mip, sg_mip);

    beta_total_cost(i)   = total_cost;
    beta_gen_energy(i)   = gen_energy;
    beta_usage_mass(i)   = usage_mass;
    beta_switching_sg(i) = switching_sg;
    beta_switching_pg(i) = switching_pg;
    beta_dist_mip_pg(i)  = dist_mip_pg;
    beta_dist_mip_sg(i)  = dist_mip_sg;
    beta_peak_pg(i)      = peak_pg;
end

%% ===============================
%% 6. Plot: gamma parameter vs metrics
%% ===============================
fig1 = figure('Position',[100 100 1400 800]);
tl = tiledlayout(2,2,"Padding","compact","TileSpacing","compact");

nexttile
semilogx(k_list, gamma_total_cost, '-o','LineWidth',1.5)
grid on
xlabel('\gamma')
ylabel('Total cost')
title('\gamma vs total cost')

nexttile
semilogx(k_list, gamma_gen_energy, '-o','LineWidth',1.5)
grid on
xlabel('\gamma')
ylabel('Total generator energy (kWh)')
title('\gamma vs generator usage')

nexttile
semilogx(k_list, gamma_switching_sg, '-o','LineWidth',1.5)
grid on
xlabel('\gamma')
ylabel('\Sigma| \Deltas_g |')
title('\gamma vs switching penalty metric')

nexttile
semilogx(k_list, gamma_dist_mip_pg, '-o','LineWidth',1.5)
grid on
xlabel('\gamma')
ylabel('L1 distance to MIP (P_g)')
title('\gamma vs distance to MIP')

set(findall(fig1,'Type','axes'),'FontSize',13)
saveas(fig1, fullfile(figDir,"tradeoff_gamma_metrics.png"));

%% ===============================
%% 7. Plot: beta parameter vs metrics
%% ===============================
fig2 = figure('Position',[100 100 1400 800]);
tl = tiledlayout(2,2,"Padding","compact","TileSpacing","compact");

nexttile
semilogx(R_list, beta_total_cost, '-o','LineWidth',1.5)
grid on
xlabel('\beta')
ylabel('Total cost')
title('\beta vs total cost')

nexttile
semilogx(R_list, beta_gen_energy, '-o','LineWidth',1.5)
grid on
xlabel('\beta')
ylabel('Total generator energy (kWh)')
title('\beta vs generator usage')

nexttile
semilogx(R_list, beta_switching_sg, '-o','LineWidth',1.5)
grid on
xlabel('\beta')
ylabel('\Sigma| \Deltas_g |')
title('\beta vs switching penalty metric')

nexttile
semilogx(R_list, beta_dist_mip_pg, '-o','LineWidth',1.5)
grid on
xlabel('\beta')
ylabel('L1 distance to MIP (P_g)')
title('\beta vs distance to MIP')

set(findall(fig2,'Type','axes'),'FontSize',13)
saveas(fig2, fullfile(figDir,"tradeoff_beta_metrics.png"));

%% ===============================
%% 8. Plot: true trade-off figures
%% ===============================
% These are the most important ones for dissertation.

% ---- Gamma: usage vs cost ----
fig3 = figure('Position',[100 100 700 500]);
scatter(gamma_gen_energy, gamma_total_cost, 70, log10(k_list), 'filled')
grid on
xlabel('Total generator energy (kWh)')
ylabel('Total cost')
title('Gamma trade-off: generator usage vs cost')
cb = colorbar;
cb.Label.String = 'log10(\gamma)';
set(gca,'FontSize',13)
saveas(fig3, fullfile(figDir,"tradeoff_gamma_usage_vs_cost.png"));

% ---- Gamma: distance to MIP vs cost ----
fig4 = figure('Position',[100 100 700 500]);
scatter(gamma_dist_mip_pg, gamma_total_cost, 70, log10(k_list), 'filled')
grid on
xlabel('L1 distance to MIP (P_g)')
ylabel('Total cost')
title('Gamma trade-off: MIP distance vs cost')
cb = colorbar;
cb.Label.String = 'log10(\gamma)';
set(gca,'FontSize',13)
saveas(fig4, fullfile(figDir,"tradeoff_gamma_mip_vs_cost.png"));

% ---- Beta: switching vs cost ----
fig5 = figure('Position',[100 100 700 500]);
scatter(beta_switching_sg, beta_total_cost, 70, log10(R_list), 'filled')
grid on
xlabel('\Sigma| \Deltas_g |')
ylabel('Total cost')
title('Beta trade-off: switching vs cost')
cb = colorbar;
cb.Label.String = 'log10(\beta)';
set(gca,'FontSize',13)
saveas(fig5, fullfile(figDir,"tradeoff_beta_switch_vs_cost.png"));

% ---- Beta: distance to MIP vs cost ----
fig6 = figure('Position',[100 100 700 500]);
scatter(beta_dist_mip_pg, beta_total_cost, 70, log10(R_list), 'filled')
grid on
xlabel('L1 distance to MIP (P_g)')
ylabel('Total cost')
title('Beta trade-off: MIP distance vs cost')
cb = colorbar;
cb.Label.String = 'log10(\beta)';
set(gca,'FontSize',13)
saveas(fig6, fullfile(figDir,"tradeoff_beta_mip_vs_cost.png"));

%% ===============================
%% 9. Save tables
%% ===============================
T_gamma = table(k_list(:), gamma_total_cost(:), gamma_gen_energy(:), ...
    gamma_usage_mass(:), gamma_switching_sg(:), gamma_switching_pg(:), ...
    gamma_dist_mip_pg(:), gamma_dist_mip_sg(:), gamma_peak_pg(:), ...
    'VariableNames', {'gamma','total_cost','gen_energy','usage_mass', ...
    'switching_sg','switching_pg','dist_mip_pg','dist_mip_sg','peak_pg'});

T_beta = table(R_list(:), beta_total_cost(:), beta_gen_energy(:), ...
    beta_usage_mass(:), beta_switching_sg(:), beta_switching_pg(:), ...
    beta_dist_mip_pg(:), beta_dist_mip_sg(:), beta_peak_pg(:), ...
    'VariableNames', {'beta','total_cost','gen_energy','usage_mass', ...
    'switching_sg','switching_pg','dist_mip_pg','dist_mip_sg','peak_pg'});

writetable(T_gamma, fullfile(figDir,"tradeoff_gamma_metrics.csv"));
writetable(T_beta,  fullfile(figDir,"tradeoff_beta_metrics.csv"));

disp("Saved figures and tables:")
disp(fullfile(figDir,"tradeoff_gamma_metrics.png"))
disp(fullfile(figDir,"tradeoff_beta_metrics.png"))
disp(fullfile(figDir,"tradeoff_gamma_usage_vs_cost.png"))
disp(fullfile(figDir,"tradeoff_gamma_mip_vs_cost.png"))
disp(fullfile(figDir,"tradeoff_beta_switch_vs_cost.png"))
disp(fullfile(figDir,"tradeoff_beta_mip_vs_cost.png"))
disp(fullfile(figDir,"tradeoff_gamma_metrics.csv"))
disp(fullfile(figDir,"tradeoff_beta_metrics.csv"))

%% ===============================
%% Local function
%% ===============================
function [total_cost, gen_energy, usage_mass, switching_sg, switching_pg, ...
          dist_mip_pg, dist_mip_sg, peak_pg] = ...
          compute_metrics(A, gamma_val, beta_val, dt, c_fuel, Pg_max, ...
                          col_t, col_price, col_Pgrid, col_Pg, col_sg, ...
                          Pg_mip, sg_mip)

    %#ok<*INUSD>
    t     = A(:,col_t);
    price = A(:,col_price);
    Pgrid = A(:,col_Pgrid);
    Pg    = A(:,col_Pg);

    if size(A,2) >= col_sg
        sg = A(:,col_sg);
    else
        sg = min(max(Pg./Pg_max,0),1);
    end

    dsg = [0; diff(sg)];

    grid_cost  = dt * sum(price .* Pgrid);
    fuel_cost  = dt * c_fuel * sum(Pg);
    gamma_cost = dt * gamma_val * sum(sg);
    beta_cost  = beta_val * sum(abs(dsg));

    total_cost = grid_cost + fuel_cost + gamma_cost + beta_cost;

    gen_energy   = dt * sum(Pg);
    usage_mass   = dt * sum(sg);
    switching_sg = sum(abs(diff(sg)));
    switching_pg = sum(abs(diff(Pg)));
    dist_mip_pg  = sum(abs(Pg - Pg_mip));
    dist_mip_sg  = sum(abs(sg - sg_mip));
    peak_pg      = max(Pg);
end