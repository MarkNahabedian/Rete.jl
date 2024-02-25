

struct JoinSewquentialLetterDigram end

function install(s::JoinSewquentialLetterDigram, root::BasicReteNode)
    a = ensure_IsaMemoryNode(root, Char)
    join_ab = JoinNode("join a, b", JoinSewquentialLetterDigram())
    connect_a(a, join_ab)
    connect_b(a, join_ab)
    connect(join_ab, root)
end

function (::JoinSewquentialLetterDigram)(node::JoinNode, a::Char, b::Char)
    if codepoint(a) + 1 == codepoint(b)
        emit(node, (a, b))
    end
end


struct JoinSewquentialLetterTrigram end

function install(s::JoinSewquentialLetterTrigram, root::BasicReteNode)
    a = ensure_IsaMemoryNode(root, Tuple{Char, Char})
    b = ensure_IsaMemoryNode(root, Char)
    join_abc = JoinNode("join a, b, c", JoinSewquentialLetterTrigram())
    connect_a(a, join_abc)
    connect_b(b, join_abc)
    connect(join_abc, root)
end

function (::JoinSewquentialLetterTrigram)(node::JoinNode,
                                          p::Tuple{Char, Char},
                                          c::Char)
    if codepoint(p[2]) + 1 == codepoint(c)
        emit(node, p[1] * p[2] * c)
    end
end

@testset "rule example 1" begin
    root = BasicReteNode("root")
    install(JoinSewquentialLetterDigram(), root)
    install(JoinSewquentialLetterTrigram(), root)
    conclusions = ensure_IsaMemoryNode(root, String)
    for c in 'a':'g'
        receive(root, c)
    end
    @test conclusions.memory ==
        Set{String}(["abc", "bcd", "cde", "def", "efg"])
end

