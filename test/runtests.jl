using Rete
using Test

@testset "Node connection test" begin
    n1 = BasicReteNode("node 1")
    n2 = BasicReteNode("node 2")
    connect(n1, n2)
    @test n1.inputs == Set()
    @test n1.outputs == Set([n2])
    @test n2.inputs == Set([n1])
    @test n2.outputs == Set()
end

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

@testset "simple join test a b" begin
    root = BasicReteNode("root")
    chars = IsaMemoryNode{Char}()
    ints = IsaMemoryNode{Int}()
    connect(root, chars)
    connect(root, ints)
    join = JoinNode("join char int",
                    function(node, c, i)
                        emit(node, "$c$i")
                    end)
    connect_a(chars, join)
    connect_b(ints, join)
    conclusions = IsaMemoryNode{String}()
    connect(root, conclusions)
    connect(join, root)
    for c in 'a':'c'
        receive(root, c)
    end
    for i in 1:3
        receive(root, i)
    end
    @test sort(collect(conclusions.memory)) == sort([
        "a1", "b1", "c1", "a2", "b2", "c2", "a3", "b3", "c3"])
end

@testset "symetric join test" begin
    root = BasicReteNode("root")
    ints = IsaMemoryNode{Int}()
    join = JoinNode("join",
                    function(node, a, b)
                        if b == a + 1
                            emit(node, (a, b))
                        end
                    end)
    conclusions = IsaMemoryNode{Tuple{Int, Int}}()
    connect(root, ints)
    connect(root, conclusions)
    connect_a(ints, join)
    connect_b(ints, join)
    connect(join, root)
    for i in 1:5
        receive(root, i)
    end
    @test conclusions.memory ==
        Set{Tuple{Int, Int}}([
            (1, 2), (2, 3), (3, 4), (4, 5)])
end

@testset "ensure_IsaMemoryNode" begin
    root = BasicReteNode("root")
    n1 = ensure_IsaMemoryNode(root, Char)
    @test n1 == ensure_IsaMemoryNode(root, Char)
    @test length(root.outputs) == 1
end

include("rule_example_2.jl")
include("rule_grouping.jl")

