# MIP (hard on/off for generator + startup; battery deadband + mode exclusivity)

param NT integer >= 1;
param dt >= 0;
set T := 1..NT;

param load{T} >= 0;
param c_grid{T} >= 0;

# Grid
param Pgrid_max >= 0;

# Generator
param Pg_max >= 0;
param Pg_min >= 0;
param c_fuel  >= 0;
param c_on    >= 0;     # £ per hour (scaled by dt in objective)
param c_start >= 0;     # £ per start
param z_init  >= 0, <= 1;

# Battery
param Pb_max >= 0;
param P_min_batt >= 0;     # minimum effective charge/discharge power
param eta_c > 0, <= 1;
param eta_d > 0, <= 1;

param E_min >= 0;
param E_max >= 0;
param E0;
param E_final;

param c_c ;
param c_d ;

# Optional smoothing on Pg (MIQP if >0)
param lambda >= 0;

# ---- Shared params for compatibility (unused here) ----
param gamma_Pb >= 0;
param gamma_on >= 0;
param beta_on  >= 0;

# Decision variables
var Pgrid{T} >= 0;
var Pg{T}    >= 0;
var Pc{T}    >= 0;
var Pd{T}    >= 0;
var SoC{T};

# Generator binaries
var z_g{T} binary;      # on/off
var y_start{T} binary;  # startup indicator

# Battery mode binaries
var u_c{T} binary;
var u_d{T} binary;

minimize TotalCost:
    dt * sum {t in T} ( c_grid[t]*Pgrid[t] + c_fuel*Pg[t] + c_c*Pc[t] + c_d*Pd[t] )
  + dt * c_on * sum {t in T} z_g[t]
  +      c_start * sum {t in T} y_start[t]
  + lambda * sum {t in T: t>1} (Pg[t] - Pg[t-1])^2;

# Power balance
subject to PowerBalance{t in T}:
    Pgrid[t] + Pg[t] + Pd[t] = load[t] + Pc[t];

subject to GridLimit{t in T}:
    Pgrid[t] <= Pgrid_max;

# Generator on/off with min output (hard deadband)
subject to GenUpper{t in T}:
    Pg[t] <= Pg_max * z_g[t];

subject to GenLower{t in T}:
    Pg[t] >= Pg_min * z_g[t];

# Startup logic
subject to Startup1:
    y_start[1] >= z_g[1] - z_init;

subject to Startup{t in T: t>1}:
    y_start[t] >= z_g[t] - z_g[t-1];

# Battery deadband + mode activation
subject to ChargeDeadband_LB{t in T}:
    Pc[t] >= P_min_batt * u_c[t];

subject to ChargeDeadband_UB{t in T}:
    Pc[t] <= Pb_max * u_c[t];

subject to DischargeDeadband_LB{t in T}:
    Pd[t] >= P_min_batt * u_d[t];

subject to DischargeDeadband_UB{t in T}:
    Pd[t] <= Pb_max * u_d[t];

subject to ModeExcl{t in T}:
    u_c[t] + u_d[t] <= 1;

# SoC dynamics
subject to SoC_Init:
    SoC[1] = E0 + eta_c*Pc[1]*dt - (1/eta_d)*Pd[1]*dt;

subject to SoC_Dyn{t in T: t>1}:
    SoC[t] = SoC[t-1] + eta_c*Pc[t]*dt - (1/eta_d)*Pd[t]*dt;

subject to SoC_Bounds{t in T}:
    E_min <= SoC[t] <= E_max;

subject to SoC_Final:
    SoC[NT] >= E_final;