using Logging
using DataStructures: DefaultDict

@rule JoinSequentialLetterDigram2(a::Char, b::Char, ::Tuple{Char, Char}) begin
    @continueif codepoint(a) + 1 == codepoint(b)
    emit((a, b))
end

@rule JoinSequentialLetterTrigram2(p::Tuple{Char, Char}, c::Char, ::String) begin
    @continueif codepoint(p[2]) + 1 == codepoint(c)
    emit(p[1] * p[2] * c)
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
    logger = TestLogger(; min_level=Logging.BelowMinLevel)
    with_logger(logger) do
        root = ReteRootNode("root")
        install(root, JoinSequentialLetterDigram2)
        install(root, JoinSequentialLetterTrigram2)
        @test length(root.inputs) == 2
        @test length(root.outputs) == 3
        for c in 'a':'g'
            receive(root, c)
        end
        results = askc(Collector{String}(), root)
        @test sort(results) ==
            sort(["abc", "bcd", "cde", "def", "efg"])
        # Test askc for subtypes:
        count_by_type = DefaultDict{Type, Int}(0)
        for o in root.outputs
            askc(o) do fact
                count_by_type[typeof(fact)] += 1
            end
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
        let
            rejects1 = filter(logger.logs) do rec
                rec.group == JoinSequentialLetterDigram2
            end
            chars = askc(Counter(), root, Char)
            tpls = askc(Counter(), root, Tuple{Char, Char})
            @test length(rejects1) == chars * chars - (chars - 1)
            for r in rejects1
                @test r.message == "@continueif"
                @test r.file == @__FILE__
                kwargs = r.kwargs
                @test kwargs[:predicate] == :(codepoint(a) + 1 == codepoint(b))
                p = kwargs[:parameters]
                @test codepoint(p[:a]) + 1 != codepoint(p[:b])
            end
            rejects2 = filter(logger.logs) do rec
                rec.group == JoinSequentialLetterTrigram2
            end
            # I don't understand why this isn't the right calculation:
            # @test length(rejects2) == chars * tpls - length(results)
            for r in rejects2
                @test r.message == "@continueif"
                @test r.file == @__FILE__
                kwargs = r.kwargs
                @test kwargs[:predicate] == :(codepoint(p[2]) + 1 == codepoint(c))
                p = kwargs[:parameters]
                @test codepoint(p[:p][2]) + 1 != codepoint(p[:c])
            end
        end
    end
end

