using DrWatson
@quickactivate "project"

using ConcurrentSim
using Distributions
using Random
using ResumableFunctions
using Statistics

struct RossParameters
    N::Int
    S::Int
    R::Int
    mean_time_to_fail::Float64
    mean_repair_time::Float64
    seed::Int
end

# Быстрые параметры для тестирования
function fast_ross_parameters()
    return RossParameters(5, 2, 1, 10.0, 2.0, 42)  # меньшие числа для быстрого теста
end

function default_ross_parameters()
    return RossParameters(10, 3, 1, 100.0, 1.0, 42)
end

@resumable function working_machine(
    env::Environment,
    repair_queue::Resource,
    spares::Store{Process},
    fail_rate::Float64,
    repair_rate::Float64,
    id::Int
)
    while true
        @yield timeout(env, rand(Exponential(fail_rate)))
        
        # Пытаемся взять резервную машину
        spare_event = take!(spares)
        @yield spare_event
        
        # В ремонт
        @yield request(repair_queue)
        @yield timeout(env, rand(Exponential(repair_rate)))
        @yield release(repair_queue)
        
        # Возврат в резерв
        @yield put!(spares, active_process(env))
    end
end

function run_ross_simulation(params::RossParameters)
    env = Simulation()
    
    repair_queue = Resource(env, params.R)
    spares = Store{Process}(env)
    
    # Запуск работающих машин
    for i in 1:params.N
        @process working_machine(env, repair_queue, spares, 
                               params.mean_time_to_fail, 
                               params.mean_repair_time, i)
    end
    
    # Резервные машины
    for i in 1:params.S
        proc = @process working_machine(env, repair_queue, spares,
                                       params.mean_time_to_fail,
                                       params.mean_repair_time, params.N + i)
        put!(spares, proc)
    end
    
    # Устанавливаем таймаут, чтобы симуляция не шла вечно
    # Если система не упала за 5000 часов, останавливаем
    timeout_event = timeout(env, 5000.0)
    
    try
        result = run(env, timeout_event)
        if result === timeout_event
            return 5000.0  # Не упала за время симуляции
        else
            return now(env)
        end
    catch e
        if isa(e, StopSimulation)
            return now(env)
        else
            rethrow(e)
        end
    end
end

function run_ross_experiments(params::RossParameters; num_runs=5)  # меньше прогонов для теста
    crash_times = []
    
    for run in 1:num_runs
        print("  Run $run...")
        flush(stdout)
        
        run_params = RossParameters(params.N, params.S, params.R, 
                                   params.mean_time_to_fail, 
                                   params.mean_repair_time, 
                                   params.seed + run)
        crash_time = run_ross_simulation(run_params)
        push!(crash_times, crash_time)
        println(" Crash time: $crash_time")
    end
    
    avg_time = mean(crash_times)
    std_time = std(crash_times)
    
    return (avg_time=avg_time, std_time=std_time, all_times=crash_times)
end

function main_ross()
    println("\n=== БЫСТРЫЙ ТЕСТ ===")
    fast_params = fast_ross_parameters()
    println("Быстрые параметры:")
    println("  N=$(fast_params.N), S=$(fast_params.S), R=$(fast_params.R)")
    println("  Среднее время до отказа: $(fast_params.mean_time_to_fail)")
    println("  Среднее время ремонта: $(fast_params.mean_repair_time)")
    println()
    
    fast_results = run_ross_experiments(fast_params, num_runs=3)
    println("\nБыстрый тест - среднее время до падения: $(fast_results.avg_time) ± $(fast_results.std_time)")
    
    println("\n=== ПОЛНЫЙ ТЕСТ ===")
    params = default_ross_parameters()
    println("Полные параметры:")
    println("  N=$(params.N), S=$(params.S), R=$(params.R)")
    println("  Среднее время до отказа: $(params.mean_time_to_fail)")
    println("  Среднее время ремонта: $(params.mean_repair_time)")
    println()
    
    results = run_ross_experiments(params, num_runs=5)
    
    println("\n"^60)
    println("ИТОГОВЫЕ РЕЗУЛЬТАТЫ:")
    println("  Среднее время до падения: $(results.avg_time) ± $(results.std_time)")
    println("  Все времена падения: $(results.all_times)")
    
    return results
end

if abspath(PROGRAM_FILE) == @__FILE__
    main_ross()
end