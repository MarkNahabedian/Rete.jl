
abstract type AbstractThing end

struct Thing1 <: AbstractThing
    c::Char
end

struct Thing2 <: AbstractThing
    c::Char
end

@rule JuxtaposeAbstractThingsRule(t1::AbstractThing, t2::AbstractThing, ::Tuple) begin
     emit((t1.c, t2.c))
end

@rule JuxtaposeThings12Rule(t1::Thing1, t2::Thing2, ::String) begin
     emit("$(t1.c)$(t2.c)")
end

@testset "test thing/subthing" begin
    root = ReteRootNode("root")
    install(root, JuxtaposeAbstractThingsRule)
    install(root, JuxtaposeThings12Rule)
    for c in 'a':'c'
        receive(root, Thing1(c))
    end
    for c in 'd':'e'
        receive(root, Thing2(c))
    end
    @test askc(Counter(), root, Thing1) == 3
    @test askc(Counter(), root, Thing2) == 2
    @test askc(Counter(), root, AbstractThing) == 5
    @test askc(Counter(), root, String) == 6
    @test askc(Counter(), root, Tuple) == 25
end


