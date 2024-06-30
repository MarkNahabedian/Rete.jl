
using DataStructures: DefaultDict

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


EXECTED_KB_STATS = """
inputs \toutputs \tfacts \tlabel
     2 \t     1 \t       \tJoinSequentialLetterDigram2
     2 \t     1 \t       \tJoinSequentialLetterTrigram2
     1 \t     2 \t     7 \tisa Char memory
     1 \t     0 \t     5 \tisa String memory
     1 \t     1 \t     6 \tisa Tuple{Char, Char} memory
     2 \t     3 \t       \troot
"""

@testset "rule example 2" begin
    root = ReteRootNode("root")
    install(root, JoinSequentialLetterDigram2)
    install(root, JoinSequentialLetterTrigram2)
    @test length(root.inputs) == 2
    @test length(root.outputs) == 3
    for c in 'a':'g'
        receive(root, c)
    end
    results = askc(Collector{Any}(), root, String)
    @test sort(results) ==
        sort(["abc", "bcd", "cde", "def", "efg"])
    # Test askc for subtypes:
    count_by_type = DefaultDict{Type, Int}(0)
    askc(root, Any) do fact
        count_by_type[typeof(fact)] += 1
    end
    @test Set(collect(count_by_type)) ==
        Set([Char => 7,
             Tuple{Char, Char} => 6,
             String => 5])
    let
        io = IOBuffer()
        kb_stats(io, root)
        @test String(take!(io)) == EXECTED_KB_STATS
    end
end

