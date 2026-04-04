param NT integer >= 1;
param dt >= 0;
set T := 1..NT;

param load{T} >= 0;
param c_grid{T} >= 0;

# Grid
param Pgrid_max >= 0;

# Generator (continuous here)
param Pg_max >= 0;
param c_fuel >= 0;

# Battery
param Pb_max >= 0;
param eta_c > 0, <= 1;
param eta_d > 0, <= 1;

param E_min >= 0;
param E_max >= 0;
param E0;
param E_final;

param c_c ;
param c_d ;

# Optional smoothing (convex QP if >0; LP if 0)
param lambda >= 0;

# ---- Shared params for compatibility with a single data.dat (unused here) ----
param Pg_min >= 0;
param c_on >= 0;
param c_start >= 0;
param z_init >= 0, <= 1;

param gamma_Pb >= 0;
param gamma_on >= 0;
param beta_on  >= 0;

param P_min_batt >= 0;

# Decision variables
var Pgrid{T} >= 0;
var Pg{T}    >= 0;
var Pc{T}    >= 0;
var Pd{T}    >= 0;
var SoC{T};


param MaxCost :=
    dt * sum {t in T} (c_grid[t] * load[t]);
