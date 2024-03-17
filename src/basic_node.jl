
export BasicReteNode, ReteRootNode


struct BasicReteNode <: AbstractReteNode
    inputs::Set{AbstractReteNode}
    outputs::Set{AbstractReteNode}
    label::String

    function BasicReteNode(label::String)
        new(Set{AbstractReteNode}(),
            Set{AbstractReteNode}(),
            label)
    end
end

label(node::BasicReteNode) = node.label

function receive(node::BasicReteNode, fact)
    emit(node, fact)
end


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
    
label(node::ReteRootNode) = node.label

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
