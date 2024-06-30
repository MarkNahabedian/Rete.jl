using Rete
using Test

@testset "test counting" begin
    count = Counter()() do c
        for x in 1:20
            c(x)
        end
    end
    @test count == 20
end

@testset "test collecting" begin
    v = Collector{Any}()() do c
        for x in 1:4
            c(x)
        end
    end
    @test v == Vector{Any}(1:4)
end

@testset "test collectin type" begin
    v = Collector{Int}()() do c
        for x in 1:4
            c(x)
        end
    end
    @test v == Vector{Int}(1:4)
end

@testset "Node connection test" begin
    n1 = ReteRootNode("node 1")
    n2 = ReteRootNode("node 2")
    connect(n1, n2)
    @test n1.inputs == Set()
    @test n1.outputs == Set([n2])
    @test n2.inputs == Set([n1])
    @test n2.outputs == Set()
    let
        @test input_count(n1) == 0
        @test output_count(n1) == 1
        @test input_count(n2) == 1
        @test output_count(n2) == 0
        io = IOBuffer()
        show(io, n1)
        @test String(take!(io)) == "ReteRootNode \"node 1\" with 0 inputs, 1 outputs."
    end
end

@testset "Simple memory test" begin
    root = ReteRootNode("root")
    @test label(root) == "root"
    ints = IsaMemoryNode{Int}()
    @test ints isa AbstractMemoryNode
    @test label(ints) == "isa Int64 memory"
    connect(root, ints)
    for i in 1:5
        receive(root, i)
    end
    @test Set{Int}(1:5) == ints.memory
    let
        io = IOBuffer()
        show(io, ints)
        @test String(take!(io)) == "IsaMemoryNode{Int64} \"isa Int64 memory\" with 1 inputs, 0 outputs, 5 facts."
    end
end

function all_inputs_are_triggers(join::JoinNode)
    for input_tuple in join.inputs
        for input in input_tuple
            add_forward_trigger(join, input)
        end
    end
end

@testset "simple join test a b" begin
    root = ReteRootNode("root")
    chars = IsaMemoryNode{Char}()
    ints = IsaMemoryNode{Int}()
    connect(root, chars)
    connect(root, ints)
    join = JoinNode("join char int", 2,
                    function(node, c, i)
                        emit(node, "$c$i")
                    end)
    connect(chars, join, 1)
    connect(ints, join, 2)
    conclusions = IsaMemoryNode{String}()
    connect(root, conclusions)
    connect(join, root)
    all_inputs_are_triggers(join)
    for c in 'a':'c'
        receive(root, c)
    end
    for i in 1:3
        receive(root, i)
    end
    results = askc(Collector{Any}(), conclusions)
    @test sort(results) ==
        sort(["a1", "b1", "c1", "a2", "b2", "c2", "a3", "b3", "c3"])
    let
        @test input_count(join) == 2
        @test output_count(join) == 1
        io = IOBuffer()
        show(io, join)
        @test String(take!(io)) == "JoinNode \"join char int\" with 2 inputs, 1 outputs."
    end
end

@testset "symetric join test" begin
    root = ReteRootNode("root")
    ints = IsaMemoryNode{Int}()
    join = JoinNode("join", 2,
                    function(node, a, b)
                        if b == a + 1
                            emit(node, (a, b))
                        end
                    end)
    conclusions = IsaMemoryNode{Tuple{Int, Int}}()
    connect(root, ints)
    connect(root, conclusions)
    connect(ints, join, 1)
    connect(ints, join, 2)
    connect(join, root)
    all_inputs_are_triggers(join)
    for i in 1:5
        receive(root, i)
    end
    results = askc(Collector{Any}(), conclusions)
    @test sort(results) ==
        sort([(1, 2), (2, 3), (3, 4), (4, 5)])
end

@testset "3-ary join" begin
    root = ReteRootNode("root")
    ints = IsaMemoryNode{Int}()
    chars = IsaMemoryNode{Char}()
    join = JoinNode("join", 3,
                    function(node, a, b, c)
                        if a != c
                            emit(node, "$a$b$c")
                        end
                    end)
    conclusions = IsaMemoryNode{String}()
    connect(root, ints)
    connect(root, chars)
    connect(root, conclusions)
    connect(ints, join, 1)
    connect(chars, join, 2)
    connect(ints, join, 3)
    connect(join, root)
    all_inputs_are_triggers(join)
    for i in 1:2
        receive(root, i)
    end
    for c in 'a':'b'
        receive(root, c)
    end
    results = askc(Collector{Any}(), conclusions)
    @test sort(results) == sort(["1a2", "2a1", "1b2", "2b1"])
    all_facts = askc(Collector{Any}(), root.outputs)
    all_facts = sort(all_facts; by = string)
    @test all_facts == [1, "1a2", "1b2", 2, "2a1", "2b1", 'a', 'b']
end

@testset "ensure_memory_node" begin
    root = ReteRootNode("root")
    n1 = ensure_memory_node(root, Char)
    @test n1 == ensure_memory_node(root, Char)
    @test length(root.outputs) == 1
end

include("test_backwards.jl")
include("rule_example_2.jl")
include("rule_grouping.jl")
include("three_parameter_rule_example.jl")
include("test_rule_decls.jl")
include("test_copy_facts.jl")

