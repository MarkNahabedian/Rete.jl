
struct FactA
    v::Int
end

struct FactB
    v::Int
end

@testset "test copy_facts" begin
    from_kb = ReteRootNode("from")
    to_kb = ReteRootNode("to")
    # Since no rules are installed, we need to add the memory nodes by
    # hand:
    ensure_memory_node(from_kb, FactA)
    ensure_memory_node(from_kb, FactB)
    ensure_memory_node(to_kb, FactA)
    ensure_memory_node(to_kb, FactB)
    receive(from_kb, FactA(1))
    receive(from_kb, FactA(2))
    receive(from_kb, FactB(3))
    receive(from_kb, FactB(4))
    receive(from_kb, FactB(5))
    all_counts = Dict(
        FactA => 2,
        FactB => 3
    )
    @test kb_counts(from_kb) == all_counts
    @test kb_counts(to_kb) == Dict(
        FactA => 0,
        FactB => 0
    )
    copy_facts.([from_kb], [to_kb], [FactA, FactB])
    @test kb_counts(from_kb) == all_counts
    @test kb_counts(to_kb) == all_counts
end

