
@rule JoinSequentialLetterDigram2(a::Char, b::Char,
                                  ::Tuple{Char, Char}) begin
    if codepoint(a) + 1 == codepoint(b)
        emit((a, b))
    end
end

@rule JoinSequentialLetterTrigram2(p::Tuple{Char, Char}, c::Char,
                                   ::String) begin
    if codepoint(p[2]) + 1 == codepoint(c)
        emit(p[1] * p[2] * c)
    end
end

@testset "rule example 2" begin
    root = ReteRootNode("root")
    install(root, JoinSequentialLetterDigram2)
    install(root, JoinSequentialLetterTrigram2)
    @test length(root.inputs) == 2
    @test length(root.outputs) == 3
    for c in 'a':'g'
        receive(root, c)
    end
    results = collecting() do c
        askc(c, root, String)
    end
    @test sort(results) ==
        sort(["abc", "bcd", "cde", "def", "efg"])
end

