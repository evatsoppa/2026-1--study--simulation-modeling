using DrWatson
@quickactivate "project"

using ConcurrentSim
using Distributions
using Random
using StableRNGs
using ResumableFunctions

struct MMcParameters
    λ::Float64
    μ::Float64
    c::Int
    num_customers::Int
    seed::Int
    max_time::Float64  # добавили максимальное время
end

function default_parameters()
    return MMcParameters(0.9, 0.5, 2, 100, 123, 1000.0)
end

@resumable function customer(
    env::Environment,
    server::Resource,
    id::Integer,
    t_a::Float64,
    service_dist::Distribution
)
    @yield timeout(env, t_a)
    @yield request(server)
    @yield timeout(env, rand(service_dist))
    @yield release(server)
end

function run_mmc_simulation(params::MMcParameters)
    rng = StableRNG(params.seed)
    sim = Simulation()
    server = Resource(sim, params.c)
    
    arrival_dist = Exponential(1 / params.λ)
    service_dist = Exponential(1 / params.μ)
    
    arrival_time = 0.0
    for i in 1:params.num_customers
        arrival_time += rand(rng, arrival_dist)
        @process customer(sim, server, i, arrival_time, service_dist)
    end
    
    run(sim, params.max_time)  # добавили ограничение по времени
    return Dict("simulation_time" => now(sim))
end

function main()
    params = default_parameters()
    println("Запуск M/M/c модели с параметрами: λ=$(params.λ), μ=$(params.μ), c=$(params.c)")
    results = run_mmc_simulation(params)
    println("Время симуляции: $(results["simulation_time"])")
    return results
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end