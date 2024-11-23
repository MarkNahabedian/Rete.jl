
@testset "exttract_rule_declarations" begin
    let
        expr = Meta.parse(""" begin end""")
        decls = Rete.exttract_rule_declarations(expr)
        @test decls.has_decls == false
        @test decls.forward_triggers == []
        @test decls.custom_install == false
    end
    let
        expr = Meta.parse("""begin
                               RULE_DECLARATIONS(
                                 FORWARD_TRIGGERS(a, b),
                                 CUSTOM_INSTALL())
                             end""")
        decls = Rete.exttract_rule_declarations(expr)
        @test decls.has_decls == true
        @test decls.forward_triggers == [:a, :b]
        @test decls.custom_install == true
    end
end


@rule RuleWithCustomInstall(a::Int, b::Char, ::String) begin
    RULE_DECLARATIONS(CUSTOM_INSTALL())
    emit("$b$a")
end

@rule RuleWithoutCustomInstall(a::Int, b::Char, ::String) begin
    emit("$a$b")
end

@testset "test CUSTOM_INSTALL" begin
    got_with = false
    got_without = false
    for m in methods(install)
        if hasproperty(m.sig, :parameters)
            if m.sig.parameters[3] == RuleWithoutCustomInstall
                got_without = true
            elseif m.sig.parameters[3] == RuleWithCustomInstall
                got_with = true
            end
        end
    end
    @test !got_with
    @test got_without
end

@rule RuleWithNoForwardTriggers(a::Int, b::Char, ::String) begin
    RULE_DECLARATIONS(FORWARD_TRIGGERS())
    emit("$b$a")
end

@rule RuleWithForwardTriggers(a::Int, b::Char, ::String) begin
    emit("$b$(a)_FT")
end

@rule RuleWithExplicitForwardTriggers(a::Int, b::Char, ::String) begin
    RULE_DECLARATIONS(FORWARD_TRIGGERS(a, b))
    emit("$b$(a)_EFT")
end

@testset "rule declared without forward triggers" begin
    root = ReteRootNode("root")
    install(root, RuleWithNoForwardTriggers)
    install(root, RuleWithForwardTriggers)
    # Find each join node and check triggers
    join_for_RuleWithNoForwardTriggers = nothing
    join_for_RuleWithForwardTriggers = nothing
    walk_by_outputs(root) do node
        if label(node) == "RuleWithNoForwardTriggers"
            join_for_RuleWithNoForwardTriggers = node
        end
        if label(node) == "RuleWithForwardTriggers"
            join_for_RuleWithForwardTriggers = node
        end
    end
    @test length(join_for_RuleWithNoForwardTriggers.forward_triggers) == 0
    @test length(join_for_RuleWithForwardTriggers.forward_triggers) == 2
    for c in 'a':'c'
        receive(root, c)
    end
    for i in 1:3
        receive(root, i)
    end
    @test 3 == askc(Counter(), root, Char)
    @test 9 == askc(Counter(), root, String)
    results = askc(Collector{String}(), root)
    @test length(filter(results) do r
                     occursin("_FT", r)
                 end) == 9
    @test length(filter(results) do r
                     !occursin("_FT", r)
                 end) == 0
end

@testset "explicit forward triggers" begin
    root = ReteRootNode("root")
    install(root, RuleWithExplicitForwardTriggers)
    join = nothing
    walk_by_outputs(root) do node
        if label(node) == "RuleWithExplicitForwardTriggers"
            join = node
        end
    end
    @test length(join.forward_triggers) == 2
    for c in 'a':'c'
        receive(root, c)
    end
    for i in 1:3
        receive(root, i)
    end
    results = askc(Collector{String}(), root)
    @test length(results) == 9
end

