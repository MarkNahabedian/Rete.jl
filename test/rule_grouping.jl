
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
    conclusions = find_memory_for_type(root, String)
    for c in 'a':'c'
        receive(root, c)
    end
    for i in 1:3
        receive(root, i)
    end
    results = collecting() do c
        askc(c, conclusions)
    end
    @test sort(results) ==
        sort([
            "a1b", "a2b", "a3b",
            "b1c", "b2c", "b3c"
        ])
end

