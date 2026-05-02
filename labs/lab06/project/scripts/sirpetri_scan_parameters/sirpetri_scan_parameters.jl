using DrWatson
@quickactivate "project"
include(srcdir("SIRPetri.jl"))
using .SIRPetri
using DataFrames, CSV, Plots

beta_range = 0.1:0.05:0.8
gamma_fixed = 0.1
tmax = 100.0

results = []

for beta in beta_range
    params, u0, _ = build_sir_model(beta, gamma_fixed)
    df = simulate_deterministic(params, u0, (0.0, tmax), saveat = 0.5)
    peak_I = maximum(df.I)
    final_R = df.R[end]
    push!(results, (beta = beta, peak_I = peak_I, final_R = final_R))
end

df_scan = DataFrame(results)
CSV.write(datadir("sir_scan.csv"), df_scan)

p = plot(
    df_scan.beta,
    [df_scan.peak_I df_scan.final_R],
    label = ["Peak I" "Final R"],
    marker = :circle,
    xlabel = "beta (infection rate)",
    ylabel = "Population",
)
savefig(plotsdir("sir_scan.png"))

println("Сканирование beta завершено. Результат в data/sir_scan.csv")
