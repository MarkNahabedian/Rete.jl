
@testset "test BackwardFilterNode" begin
    root = ReteRootNode("root")
    ints = ensure_memory_node(root, Int)
    connect(root, ints)
    even = BackwardFilterNode(iseven, "even Ints")
    connect(ints, even)
    for i in 1:10
        receive(root, i)
    end
    filtered = askc(Collector{Any}(), even)
    @test sort(filtered) == [2, 4, 6, 8, 10]
    let
        @test input_count(even) == 1
        @test output_count(even) == 0
        io = IOBuffer()
        show(io, even)
        @test String(take!(io)) == "BackwardFilterNode \"even Ints\" with 1 inputs, 0 outputs."
    end
end

@testset "test BackwardExtremumNode" begin
    root = ReteRootNode("root")
    ints = ensure_memory_node(root, Int)
    connect(root, ints)
    maxval = BackwardExtremumNode(>, identity, "greatest int")
    connect(ints, maxval)
    for i in 1:10
        receive(root, i)
    end
    extreme = askc(Collector{Any}(), maxval)
    @test extreme == [10]
    let
        @test input_count(maxval) == 1
        @test output_count(maxval) == 0
        io = IOBuffer()
        show(io, maxval)
        @test String(take!(io)) == "BackwardExtremumNode \"greatest int\" with 1 inputs, 0 outputs."
    end
end

