%% plot_regularised_sweep_pg.m
% Plot regularised-model outputs for gamma_on and beta_on parameter sweeps
% Saves time-series comparisons for: Pg, Pgrid, Pb (battery net power), SoC

clc; clear; close all;

%% locate project folders
thisFile = mfilename("fullpath");
thisDir  = fileparts(thisFile);
projRoot = fileparts(thisDir);

outDir = fullfile(projRoot,"experiments","exp_02_parameter_sweep","outputs");
figDir = fullfile(projRoot,"experiments","exp_02_parameter_sweep","figures","gamma_beta_sweep");

if ~isfolder(figDir)
    mkdir(figDir);
end

% Columns in results_reg_*.txt:
% [t load price Pgrid Pg Pc Pd SoC Pb gen_state gen_start u_c u_d]
COL_T     = 1;
COL_LOAD  = 2;
COL_PRICE = 3;
COL_PGRID = 4;
COL_PG    = 5;
COL_PC    = 6;
COL_PD    = 7;
COL_SOC   = 8;
COL_PB    = 9;

%% ===============================
%% 1. Gamma sweep
%% ===============================

k_list = [0.001 0.003 0.01 0.03 0.1 0.3 1 3 10 100 1000];

plotSweep( ...
    outDir, figDir, ...
    k_list, "results_reg_k_%g.txt", "k = %g", ...
    COL_PG, "P_{gen} (kW)", "Generator Output Comparison (Gamma Sweep)", ...
    "Pg_gamma_sweep.png", struct());

plotSweep( ...
    outDir, figDir, ...
    k_list, "results_reg_k_%g.txt", "k = %g", ...
    COL_PGRID, "P_{grid} (kW)", "Grid Import Power Comparison (Gamma Sweep)", ...
    "Pgrid_gamma_sweep.png", struct());

plotSweep( ...
    outDir, figDir, ...
    k_list, "results_reg_k_%g.txt", "k = %g", ...
    COL_PB, "P_{batt} = P_d - P_c (kW)", "Battery Net Power Comparison (Gamma Sweep)", ...
    "BatteryPower_gamma_sweep.png", struct("yline0",true));

plotSweep( ...
    outDir, figDir, ...
    k_list, "results_reg_k_%g.txt", "k = %g", ...
    COL_SOC, "SoC (kWh)", "SoC Comparison (Gamma Sweep)", ...
    "SoC_gamma_sweep.png", struct());

%% ===============================
%% 2. Beta sweep
%% ===============================

R_list = [0.001 0.003 0.01 0.03 0.1 0.3 1 3 10 100 1000];

plotSweep( ...
    outDir, figDir, ...
    R_list, "results_reg_R_%g.txt", "R = %g", ...
    COL_PG, "P_{gen} (kW)", "Generator Output Comparison (Beta Sweep)", ...
    "Pg_beta_sweep.png", struct());

plotSweep( ...
    outDir, figDir, ...
    R_list, "results_reg_R_%g.txt", "R = %g", ...
    COL_PGRID, "P_{grid} (kW)", "Grid Import Power Comparison (Beta Sweep)", ...
    "Pgrid_beta_sweep.png", struct());

plotSweep( ...
    outDir, figDir, ...
    R_list, "results_reg_R_%g.txt", "R = %g", ...
    COL_PB, "P_{batt} = P_d - P_c (kW)", "Battery Net Power Comparison (Beta Sweep)", ...
    "BatteryPower_beta_sweep.png", struct("yline0",true));

plotSweep( ...
    outDir, figDir, ...
    R_list, "results_reg_R_%g.txt", "R = %g", ...
    COL_SOC, "SoC (kWh)", "SoC Comparison (Beta Sweep)", ...
    "SoC_beta_sweep.png", struct());

%% ===============================
%% Local helpers
%% ===============================

function plotSweep(outDir, figDir, paramList, fileTemplate, legendTemplate, yCol, yLabel, figTitle, outFile, opts)
if nargin < 10 || isempty(opts), opts = struct(); end
if ~isfield(opts,"yline0"), opts.yline0 = false; end

figure('Position',[100 100 1400 500]);
hold on;
grid on;

legendText = strings(0,1);
hasAny = false;

for i = 1:length(paramList)
    p = paramList(i);
    fileName = sprintf(fileTemplate, p);
    filePath = fullfile(outDir, fileName);

    if ~isfile(filePath)
        warning("Missing file: %s", filePath);
        continue;
    end

    A = readmatrix(filePath);

    if size(A,2) < yCol
        warning("File %s has only %d columns; need %d. Skipped.", filePath, size(A,2), yCol);
        continue;
    end

    t = A(:,1);
    y = A(:,yCol);

    plot(t, y, 'LineWidth', 1.5);
    legendText(end+1) = sprintf(legendTemplate, p); %#ok<AGROW>
    hasAny = true;
end

if ~hasAny
    warning("No valid data found for figure: %s", outFile);
    close(gcf);
    return;
end

if opts.yline0
    yline(0,'--');
end

xlabel("Hour");
ylabel(yLabel);
title(figTitle);
legend(legendText, "Location", "eastoutside");
set(gca,'FontSize',14);

saveas(gcf, fullfile(figDir, outFile));
disp("Saved:");
disp(fullfile(figDir, outFile));
end
