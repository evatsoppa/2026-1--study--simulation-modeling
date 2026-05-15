using DrWatson
@quickactivate "project"

include("../src/MMcQueue.jl")
include("../src/RossModel.jl")

function run_all_experiments()
    println("="^60)
    println("ЗАПУСК МОДЕЛИ M/M/c")
    println("="^60)
    main()

    println("\n\n")
    println("="^60)
    println("ЗАПУСК МОДЕЛИ РОССА")
    println("="^60)
    main_ross()
end

run_all_experiments()