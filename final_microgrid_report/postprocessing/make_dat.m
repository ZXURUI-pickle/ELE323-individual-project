%% make_dat.m
% Generate synthetic 168h data for exp_01 (grid+generator+battery)
% Outputs:
%   experiments/exp_01_synthetic_baseline/outputs/data.dat
%   price_168h.csv

clc; clear;

%% 1) Auto-locate project root (final_microgrid_report)
thisFile = mfilename("fullpath");
thisDir  = fileparts(thisFile);
projRoot = fileparts(thisDir);

expDir = fullfile(projRoot, "experiments", "exp_01_synthetic_baseline");
outDir = fullfile(expDir, "outputs");
if ~isfolder(outDir), mkdir(outDir); end

fprintf("Project root: %s\n", projRoot);
fprintf("Experiment  : %s\n", expDir);
fprintf("Outputs     : %s\n\n", outDir);

%% 2) Settings (fixed across all models)
NT = 168;
dt = 1.0;

% Grid cap
Pgrid_max = 12;   % kW

% Battery
Pb_max = 5;       % kW
eta_c  = 0.95;
eta_d  = 0.95;

E_min   = 2;      % kWh
E_max   = 10;     % kWh
E0      = 5;      % kWh
E_final = 5;      % kWh

c_c = 0; % positive
c_d = 0; % negative

% Generator (dispatchable)
Pg_max  = 5;      % kW
Pg_min  = 0.05;   % kW (min stable output if ON)
c_fuel  = 0.10;   % £/kWh (constant marginal cost)

% MIP event costs(generator)
c_on    = 0.02;   % £/h (fixed cost when ON)
c_start = 0.02;   % £ per start
z_init  = 0;      % generator initially OFF

% Regularised-convex (soft surrogates)
gamma_on = c_on;      % penalty on relaxed commitment s_g
beta_on  = c_start;   % penalty on |Δs_g|
gamma_Pb = 0.005;      % penalty on |Pb| (battery small actions)

% Optional smoothing (set 0 to keep LP/MILP)
lambda = 0.000;

% Battery MIP deadband
P_min_batt = 1.5;  % kW

%% 3) Synthetic demand & calibrated price
t = (1:NT)';
hour = mod(t-1, 24); % 0..23

t = (1:NT)';
hour = mod(t-1, 24);   % 0..23
day  = floor((t-1)/24);

% ===== Load profile around 6 kW =====
base_load = 6.0;   % kW baseline

% morning peak
morning_peak = 1.2 * exp(-((hour - 8)/2.5).^2);

% evening peak
evening_peak = 1.8 * exp(-((hour - 19)/3.0).^2);

% night valley
night_valley = -0.8 * exp(-((hour - 3)/2.8).^2);

% small day-to-day variation
daily_shift = 0.2 * sin(2*pi*day/7);

% random perturbation
noise = 0.15 * randn(NT,1);

% final load curve
load_profile = base_load + morning_peak + evening_peak + night_valley + daily_shift + noise;

% clip to keep it realistic
load_profile(load_profile < 4.5) = 4.5;
load_profile(load_profile > 8.5) = 8.5;

% ---- Step 1: generate a raw synthetic pattern ----
price_raw = 0.07 ...
          + 0.008*(hour>=7  & hour<=10) ...
          + 0.015*(hour>=16 & hour<=21) ...
          + 0.005*randn(NT,1);

% optional small multi-hour spike
price_raw(112:116) = price_raw(112:116) + 0.02;

% ---- Step 2: calibrate to match real-price scale ----
mu_target    = 0.080;   % target mean from real-price plot
sigma_target = 0.015;   % target std roughly matching the plot

mu_raw    = mean(price_raw);
sigma_raw = std(price_raw);

price = mu_target + (sigma_target/sigma_raw) * (price_raw - mu_raw);

% ---- Step 3: clip to realistic bounds ----
price(price < 0.03) = 0.03;
price(price > 0.13) = 0.13;

%% 4) Write CSV
writematrix(price,  fullfile(outDir, "price_168h.csv"));
writematrix(load_profile, fullfile(outDir, "load_168h.csv"));

%% 5) Write AMPL data.dat (shared for ALL models)
datPath = fullfile(outDir, "data.dat");
fid = fopen(datPath, "w");
if fid < 0, error("Cannot open file for writing: %s", datPath); end

fprintf(fid, "param NT := %d;\n", NT);
fprintf(fid, "param dt := %.6f;\n\n", dt);

fprintf(fid, "param load :=\n");
for k = 1:NT
    fprintf(fid, "%d %.6f\n", k, load_profile(k));
end
fprintf(fid, ";\n\n");

fprintf(fid, "param c_grid :=\n");
for k = 1:NT
    fprintf(fid, "%d %.6f\n", k, price(k));
end
fprintf(fid, ";\n\n");

% Grid
fprintf(fid, "param Pgrid_max := %.6f;\n", Pgrid_max);

% Generator
fprintf(fid, "param Pg_max := %.6f;\n", Pg_max);
fprintf(fid, "param Pg_min := %.6f;\n", Pg_min);
fprintf(fid, "param c_fuel := %.6f;\n", c_fuel);
fprintf(fid, "param c_on := %.6f;\n", c_on);
fprintf(fid, "param c_start := %.6f;\n", c_start);
fprintf(fid, "param z_init := %.6f;\n\n", z_init);

% Battery
fprintf(fid, "param Pb_max := %.6f;\n", Pb_max);
fprintf(fid, "param eta_c := %.6f;\n", eta_c);
fprintf(fid, "param eta_d := %.6f;\n", eta_d);
fprintf(fid, "param E_min := %.6f;\n", E_min);
fprintf(fid, "param E_max := %.6f;\n", E_max);
fprintf(fid, "param E0 := %.6f;\n", E0);
fprintf(fid, "param E_final := %.6f;\n\n", E_final);

fprintf(fid, "param c_c := %.6f;\n", c_c);
fprintf(fid, "param c_d := %.6f;\n", c_d);

% Regularisation / smoothing / deadband
fprintf(fid, "param gamma_on := %.6f;\n", gamma_on);
fprintf(fid, "param beta_on := %.6f;\n", beta_on);
fprintf(fid, "param gamma_Pb := %.6f;\n", gamma_Pb);
fprintf(fid, "param lambda := %.6f;\n", lambda);
fprintf(fid, "param P_min_batt := %.6f;\n", P_min_batt);

fclose(fid);

fprintf("✅ Generated:\n");
fprintf("  %s\n", fullfile(outDir, "price_168h.csv"));
fprintf("  %s\n", datPath);






