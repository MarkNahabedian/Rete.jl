
export BasicReteNode


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

function emit(node::BasicReteNode, fact)
    for output in node.outputs
        receive(output, fact)
    end
end

