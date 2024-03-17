
@rule ThreeInputRule(a::Char, b::Int, c::Char, ::String) begin
    if a != c
        emit("$a$b$c")
    end
end

@testset "three input rule" begin
    root = ReteRootNode("root")
    install(root, ThreeInputRule)
    conclusions = find_memory_for_type(root, String)
    for c in 'a':'c'
        receive(root, c)
    end
    for i in 1:2
        receive(root, i)
    end
    results = collecting() do c
        askc(c, conclusions)
    end
    @test sort(results) ==
        sort(["a1b", "a1c",
              "a2b", "a2c", "b1a",
              "b1c", "b2a",
              "b2c", "c1a", "c1b",
              "c2a", "c2b"])
end

