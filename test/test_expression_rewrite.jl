using Rete: PatternVariable, pattern_matcher, rewrite_rule_body

@testset "test pattern_matcher" begin
    let
        bindings = Dict()
        @test pattern_matcher(1, 1, bindings)
        @test length(bindings) == 0
    end
    let
        bindings = Dict()
        @test !pattern_matcher(1, 2, bindings)
    end
    let
        bindings = Dict()
        @test pattern_matcher(:a, :a, bindings)
        @test length(bindings) == 0
    end
    let
        bindings = Dict()
        @test !pattern_matcher(:a, :b, bindings)
    end
    let
        bindings = Dict()
        @test pattern_matcher(PatternVariable(:a), 2, bindings)
        @test length(bindings) == 1
        @test bindings[:a] == 2
    end
    let
        bindings = Dict(:a => 2)
        @test pattern_matcher(PatternVariable(:a), 2, bindings)
        @test length(bindings) == 1
        @test bindings[:a] == 2
    end
    let
        bindings = Dict(:a => 3)
        @test !pattern_matcher(PatternVariable(:a), 2, bindings)
        @test bindings[:a] == 3
    end
    let
        bindings = Dict()
        @test pattern_matcher([1, 2, 3], [1, 2, 3], bindings)
        @test length(bindings) == 0
    end
    let
        bindings = Dict()
        @test pattern_matcher([1, PatternVariable(:a), PatternVariable(:b)],
                              [1, 2, 3], bindings)
        @test length(bindings) == 2
        @test bindings[:a] == 2
        @test bindings[:b] == 3
    end
    let
        bindings = Dict()
        @test !pattern_matcher([1, PatternVariable(:a), PatternVariable(:a)],
                              [1, 2, 3], bindings)
    end
    let
        bindings = Dict()
        @test pattern_matcher([1, PatternVariable(:a), PatternVariable(:a)],
                              [1, 2, 2], bindings)
        @test length(bindings) == 1
        @test bindings[:a] == 2
    end
    let
        bindings = Dict()
        @test pattern_matcher(:(2 * $(PatternVariable(:a))), :(2 * 3), bindings)
        @test length(bindings) == 1
        @test bindings[:a] == 3
    end
end

