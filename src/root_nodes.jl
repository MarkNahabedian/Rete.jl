# The root node of a Rete

export CanInstallRulesTrait, AbstractReteRootNode, ReteRootNode


"""
    CanInstallRulesTrait

Having this trait gives the root node of a knowledge base the
`install` method to facilitate adding rules to the network.

You can add this trait to `YourType` with

```
CanInstallRulesTrait(::Type{<:YourType}) = CanInstallRulesTrait())
```
"""
struct CanInstallRulesTrait end


"""
    install(root, rule::Type)

Installs the rule or rule group into the Rete rooted at `root`.
"""
install(root::T, rule::Type) where T =
    install(CanInstallRulesTrait(T), root, rule)

function install(trait::CanInstallRulesTrait, root, rule_group::Type)
    if isconcretetype(rule_group)
        install(trait, root, rule_group())
    else
        for r in subtypes(rule_group)
            install(trait, root, r)
        end
    end
end


"""
    AbstractReteRootNode

AbstractReteRootNode is the abstract supertype for all root nodes of a
Rete.
"""
abstract type AbstractReteRootNode <: AbstractReteNode end


"""
    ReteRootNode

ReteRootNode serves as the root node of a Rete network.

If you need a specialized root node for your application, see
[`AbstractReteRootNode`](@ref) and [`CanInstallRulesTrait`](@ref).
"""
struct ReteRootNode <: AbstractReteRootNode
    inputs::Set{AbstractReteNode}
    outputs::Set{AbstractReteNode}
    label::String

    function ReteRootNode(label::String)
        new(Set{AbstractReteNode}(),
            Set{AbstractReteNode}(),
            label)
    end
end

CanInstallRulesTrait(::Type{ReteRootNode}) = CanInstallRulesTrait()

inputs(node::ReteRootNode) = node.inputs

outputs(node::ReteRootNode) = node.outputs

label(node::ReteRootNode) = node.label

function receive(node::AbstractReteRootNode, fact)
    emit(node, fact)
end

