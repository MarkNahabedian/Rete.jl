
@rule JoinSewquentialLetterDigram2(a::Char, b::Char) begin
    if codepoint(a) + 1 == codepoint(b)
        emit((a, b))
    end
end

@rule JoinSewquentialLetterTrigram2(p::Tuple{Char, Char}, c::Char) begin
    if codepoint(p[2]) + 1 == codepoint(c)
        emit(p[1] * p[2] * c)
    end
end

@testset "rule example 2" begin
    root = BasicReteNode("root")
    install(root, JoinSewquentialLetterDigram2())
    install(root, JoinSewquentialLetterTrigram2())
    conclusions = ensure_IsaMemoryNode(root, String)
    @test length(root.inputs) == 2
    @test length(root.outputs) == 3
    for c in 'a':'g'
        receive(root, c)
    end
    @test conclusions.memory ==
        Set{String}(["abc", "bcd", "cde", "def", "efg"])
end
