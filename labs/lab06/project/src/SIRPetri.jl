module SIRPetri

using OrdinaryDiffEq
using Plots
using DataFrames
using Random

export build_sir_model, simulate_deterministic, simulate_stochastic
export plot_sir

"""
build_sir_model(β=0.3, γ=0.1)
Создаёт модель SIR.
Возвращает (params::NamedTuple, u0::Vector{Float64}, states::Vector{Symbol})
"""
function build_sir_model(β = 0.3, γ = 0.1)
    states = [:S, :I, :R]
    params = (β=β, γ=γ)
    u0 = [990.0, 10.0, 0.0]
    return params, u0, states
end

"""
sir_ode!
Возвращает функцию правой части ОДУ для модели SIR.
"""
function sir_ode!(params)
    function f!(du, u, p, t)
        S, I, R = u
        β, γ = params.β, params.γ
        
        infection_rate = β * S * I
        recovery_rate = γ * I
        
        du[1] = -infection_rate
        du[2] = infection_rate - recovery_rate
        du[3] = recovery_rate
    end
    return f!
end

"""
simulate_deterministic(params, u0, tspan; saveat=0.1)
Выполняет детерминированную ODE-симуляцию.
"""
function simulate_deterministic(params, u0, tspan; saveat = 0.1)
    f! = sir_ode!(params)
    prob = ODEProblem(f!, u0, tspan)
    sol = solve(prob, Tsit5(), saveat = saveat)
    
    df = DataFrame(time = sol.t)
    df.S = sol[1, :]
    df.I = sol[2, :]
    df.R = sol[3, :]
    
    return df
end

"""
simulate_stochastic(params, u0, tspan; rng=Random.GLOBAL_RNG)
Стохастическая симуляция (алгоритм Гиллеспи).
"""
function simulate_stochastic(params, u0, tspan; rng = Random.GLOBAL_RNG)
    u = copy(u0)
    t = 0.0
    times = [t]
    states = [copy(u)]
    
    β, γ = params.β, params.γ
    
    while t < tspan[2]
        S, I, R = u
        a_inf = β * S * I
        a_rec = γ * I
        a0 = a_inf + a_rec
        
        if a0 == 0
            break
        end
        
        dt = -log(rand(rng)) / a0
        r = rand(rng) * a0
        
        if r < a_inf
            u[1] -= 1
            u[2] += 1
        else
            u[2] -= 1
            u[3] += 1
        end
        
        t += dt
        
        if t <= tspan[2]
            push!(times, t)
            push!(states, copy(u))
        end
    end
    
    df = DataFrame(time = times)
    df.S = [s[1] for s in states]
    df.I = [s[2] for s in states]
    df.R = [s[3] for s in states]
    
    return df
end

"""
plot_sir(df)
Строит график динамики S, I, R из DataFrame.
"""
function plot_sir(df)
    p = plot(
        df.time,
        [df.S, df.I, df.R],
        label = ["S (Susceptible)" "I (Infected)" "R (Recovered)"],
        xlabel = "Time",
        ylabel = "Population",
        linewidth = 2,
    )
    return p
end

end # module