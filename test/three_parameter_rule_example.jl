
@rule ThreeInputRule(a::Char, b::Int, c::Char, ::String) begin
    @rejectif a == c
    emit("$a$b$c")
end

@testset "three input rule" begin
    logger = TestLogger(; min_level=Logging.BelowMinLevel)
    with_logger(logger) do
        root = ReteRootNode("root")
        install(root, ThreeInputRule)
        for c in 'a':'c'
            receive(root, c)
        end
        for i in 1:2
            receive(root, i)
        end
        results = askc(Collector{String}(), root)
        @test sort!(results) ==
            sort(["a1b", "a1c",
                  "a2b", "a2c", "b1a",
                  "b1c", "b2a",
                  "b2c", "c1a", "c1b",
                  "c2a", "c2b"])
        @test emits(ThreeInputRule) == (String,)
        rejects = filter(logger.logs) do rec
            rec.group == ThreeInputRule
        end
        chars = askc(Counter(), root, Char)
        ints = askc(Counter(), root, Int)
        @test length(rejects) == chars * ints * chars - length(results)
        for r in rejects
            @test r.message == "@rejectif"
            @test r.file == @__FILE__
            kwargs = r.kwargs
            @test kwargs[:predicate] == :(a == c)
            p = kwargs[:parameters]
            @test codepoint(p[:a]) + 1 != codepoint(p[:c])
        end
    end
end

