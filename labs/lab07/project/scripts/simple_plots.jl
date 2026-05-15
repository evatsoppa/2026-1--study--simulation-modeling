using Plots, ConcurrentSim, Distributions, ResumableFunctions

# Папка для графиков
mkdir("plots")

# ====== M/M/c график ======
λ, μ, c = 0.9, 0.5, 2
sim = Simulation()
server = Resource(sim, c)
arrivals, services = Float64[], Float64[]

@resumable function tr(env, srv, id, d, svc, arr, ser)
    @yield timeout(env, d)
    push!(arr, now(env))
    @yield request(srv)
    push!(ser, now(env))
    @yield timeout(env, rand(svc))
    @yield release(srv)
end

t = 0.0
for i in 1:100
    t += rand(Exponential(1/λ))
    @process tr(sim, server, i, t, Exponential(1/μ), arrivals, services)
end
run(sim, 1000.0)

ts = sort(unique(vcat(arrivals, services)))
q = [count(x->x<=ti, arrivals) - count(x->x<=ti, services) for ti in ts]
plot(ts, q, title="M/M/c Queue", xlabel="Time", ylabel="Queue length", legend=false)
savefig("plots/mmc_queue.png")
println("Saved: plots/mmc_queue.png")

# ====== Ross график ======
function ross_time(S)
    sim = Simulation()
    repair = Resource(sim, 1)
    spares = Store{Process}(sim)
    
    @resumable function mach(env, rq, sp)
        while true
            @yield timeout(env, rand(Exponential(100.0)))
            take!(sp)
            @yield request(rq)
            @yield timeout(env, rand(Exponential(1.0)))
            @yield release(rq)
            put!(sp, active_process(env))
        end
    end
    
    for i in 1:10
        @process mach(sim, repair, spares)
    end
    for i in 1:S
        proc = @process mach(sim, repair, spares)
        put!(spares, proc)
    end
    
    try
        run(sim, timeout(sim, 2000.0))
        return 2000.0
    catch
        return now(sim)
    end
end

Ss = 1:5
times = [mean([ross_time(s) for _ in 1:3]) for s in Ss]
plot(Ss, times, marker=:circle, title="Ross Model", xlabel="Spare machines (S)", ylabel="Mean crash time", legend=false)
savefig("plots/ross_plot.png")
println("Saved: plots/ross_plot.png")
println("\n✅ Готово! Графики в папке plots")