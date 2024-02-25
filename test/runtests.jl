using Rete
using Test

@testset "Simple memory test" begin
    root = BasicReteNode("root")
    @test label(root) == "root"
    ints = IsaMemoryNode{Int}()
    @test ints isa AbstractMemoryNode
    @test label(ints) == "isa Int64 memory"
    connect(root, ints)
    for i in 1:5
        receive(root, i)
    end
    @test Set{Int}(1:5) == ints.memory
end

