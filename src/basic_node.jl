
export ReteRootNode


"""
ReteRootNode serves as the root node of a Rete network.
"""
struct ReteRootNode <: AbstractReteNode
    inputs::Set{AbstractReteNode}
    outputs::Set{AbstractReteNode}
    label::String

    function ReteRootNode(label::String)
        new(Set{AbstractReteNode}(),
            Set{AbstractReteNode}(),
            label)
    end
end
    
inputs(node::ReteRootNode) = node.inputs

outputs(node::ReteRootNode) = node.outputs

label(node::ReteRootNode) = node.label

function Base.show(io::IO, node::ReteRootNode)
    print(io, "$(typeof(node)) \"$(label(node))\" with $(length(inputs(node))) inputs, $(length(inputs(node))) outputs.")
end

function receive(node::ReteRootNode, fact)
    emit(node, fact)
end


"""
    install(root::ReteRootNode, rule::Type)

Installs the rule or rule group into the Rete rooted at `root`.
"""
function install end

function install(root::ReteRootNode, rule_group::Type)
    if isconcretetype(rule_group)
        install(root, rule_group())
    else
        for r in subtypes(rule_group)
            install(root, r)
        end
    end
end
