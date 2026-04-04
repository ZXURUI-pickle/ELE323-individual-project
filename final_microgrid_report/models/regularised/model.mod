# Regularised convex
# Generator commitment relaxed: s_g in [0,1]
# On-time penalty ~ sum s_g, switching penalty ~ sum |Δs_g|
# Optional L1 penalty on |Pb|.

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
param c_fuel >= 0;

# Generator initial commitment (0/1 typical)
param z_init >= 0, <= 1;

# Battery
param Pb_max >= 0;
param eta_c > 0, <= 1;
param eta_d > 0, <= 1;

param E_min >= 0;
param E_max >= 0;
param E0;
param E_final;

param c_c  ;
param c_d  ;

# Regularisation weights
param gamma_on >= 0;   # on-time surrogate weight on s_g
param beta_on  >= 0;   # switching surrogate weight on |Δs_g|
param gamma_Pb >= 0;   # L1 on |Pb| (optional)

# Optional smoothing on Pg (QP if >0)
param lambda >= 0;

# ---- Shared params for compatibility (unused here) ----
param c_on >= 0;
param c_start >= 0;
param P_min_batt >= 0;

# Decision variables
var Pgrid{T} >= 0;
var Pg{T}    >= 0;
var Pc{T}    >= 0;
var Pd{T}    >= 0;
var SoC{T};

# Relaxed commitment
var s_g{T} >= 0, <= 1;

# |Δs_g|
var ds_abs{T} >= 0;

# Battery net power and |Pb|
var Pb{T};
var Pb_abs{T} >= 0;

minimize TotalCost:
    dt * sum {t in T} ( c_grid[t]*Pgrid[t] + c_fuel*Pg[t] + c_c*Pc[t] + c_d*Pd[t] )
  + dt * gamma_on * sum {t in T} s_g[t]
  +      beta_on  * sum {t in T} ds_abs[t]
  + dt * gamma_Pb * sum {t in T} Pb_abs[t]
  + lambda * sum {t in T: t>1} (Pg[t] - Pg[t-1])^2;

# Power balance
subject to PowerBalance{t in T}:
    Pgrid[t] + Pg[t] + Pd[t] = load[t] + Pc[t];

subject to GridLimit{t in T}:
    Pgrid[t] <= Pgrid_max;

# Generator linked to relaxed commitment
subject to GenUpper{t in T}:
    Pg[t] <= Pg_max * s_g[t];

subject to GenLower{t in T}:
    Pg[t] >= Pg_min * s_g[t];

# Battery limits
subject to ChargeLimit{t in T}:
    Pc[t] <= Pb_max;

subject to DischargeLimit{t in T}:
    Pd[t] <= Pb_max;

# SoC dynamics
subject to SoC_Init:
    SoC[1] = E0 + eta_c*Pc[1]*dt - (1/eta_d)*Pd[1]*dt;

subject to SoC_Dyn{t in T: t>1}:
    SoC[t] = SoC[t-1] + eta_c*Pc[t]*dt - (1/eta_d)*Pd[t]*dt;

subject to SoC_Bounds{t in T}:
    E_min <= SoC[t] <= E_max;

subject to SoC_Final:
    SoC[NT] >= E_final;

# Define Pb and |Pb|
subject to DefinePb{t in T}:
    Pb[t] = Pd[t] - Pc[t];

subject to AbsPbPos{t in T}:
    Pb_abs[t] >=  Pb[t];

subject to AbsPbNeg{t in T}:
    Pb_abs[t] >= -Pb[t];

# Define |Δs_g|
# t=1 relative to z_init
subject to DsAbs1_pos:
    ds_abs[1] >=  s_g[1] - z_init;

subject to DsAbs1_neg:
    ds_abs[1] >= -(s_g[1] - z_init);

# t>1 relative to previous
subject to DsAbs_pos{t in T: t>1}:
    ds_abs[t] >=  s_g[t] - s_g[t-1];

subject to DsAbs_neg{t in T: t>1}:
    ds_abs[t] >= -(s_g[t] - s_g[t-1]);