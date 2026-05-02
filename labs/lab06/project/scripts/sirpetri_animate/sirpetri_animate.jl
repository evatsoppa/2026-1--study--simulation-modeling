using DrWatson
@quickactivate "project"
include(srcdir("SIRPetri.jl"))
using .SIRPetri
using DataFrames, CSV, Plots
using Random

β = 0.3
γ = 0.1
tmax = 100.0

params, u0, states = build_sir_model(β, γ)

df_det = simulate_deterministic(params, u0, (0.0, tmax), saveat = 0.5)

Random.seed!(123)
df_stoch = simulate_stochastic(params, u0, (0.0, tmax))

CSV.write(datadir("sir_det.csv"), df_det)
CSV.write(datadir("sir_stoch.csv"), df_stoch)

p_det = plot_sir(df_det)
savefig(plotsdir("sir_det_dynamics.png"))

p_stoch = plot_sir(df_stoch)
savefig(plotsdir("sir_stoch_dynamics.png"))

println("Анимация и симуляция завершены. Результаты в data/ и plots/")
