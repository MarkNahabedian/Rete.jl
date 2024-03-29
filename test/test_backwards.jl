
@testset "test BackwardFilterNode" begin
    root = ReteRootNode("root")
    ints = ensure_IsaMemoryNode(root, Int)
    connect(root, ints)
    even = BackwardFilterNode(iseven, "even Ints")
    connect(ints, even)
    for i in 1:10
        receive(root, i)
    end
    filtered = collecting() do c
        askc(c, even)
    end
    @test sort(filtered) == [2, 4, 6, 8, 10]
end

@testset "test BackwardExtremumNode" begin
    root = ReteRootNode("root")
    ints = ensure_IsaMemoryNode(root, Int)
    connect(root, ints)
    maxval = BackwardExtremumNode(>, identity, "greatest int")
    connect(ints, maxval)
    for i in 1:10
        receive(root, i)
    end
    extreme = collecting() do c
        askc(c, maxval)
    end
    @test extreme == [10]
end

