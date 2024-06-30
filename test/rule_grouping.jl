
abstract type RuleGroup1 <: Rule end

@rule RuleGroup1.AdjacentLetters(a::Char, b::Char,
                                 ::Tuple{Char, Char}) begin
    if codepoint(a) + 1 == codepoint(b)
        emit((a, b))
    end
end

@rule RuleGroup1.DigitBetweenLetters(letters::Tuple{Char, Char},
                                     digit::Int,
                                     ::String) begin
    emit(letters[1] * string(digit) * letters[2])
end

@testset "rule grouping" begin
    root = ReteRootNode("root")
    install(root, RuleGroup1)
    for c in 'a':'c'
        receive(root, c)
    end
    for i in 1:3
        receive(root, i)
    end
    results = askc(Collector{Any}(), root, String)
    @test sort(results) ==
        sort([
            "a1b", "a2b", "a3b",
            "b1c", "b2c", "b3c"
        ])
    counts = kb_counts(root)
    @test counts[Char] == 3
    @test counts[Int64] == 3
    @test counts[Tuple{Char, Char}] == 2
    @test counts[String] == 6
end

