
export IsaMemoryNode

function emit(node::AbstractMemoryNode,
              to::AbstractReteNode, fact)
    receive(to, fact)
end

function emit(node::AbstractMemoryNode,
              to::AbstractReteJoinNode, fact)
    receive(to, fact, node)
end


"""
IsaMemoryNode is a type of memory node that only stores facts of the
specified type.  Facts of other types are ignored.
"""
struct IsaMemoryNode{T} <: AbstractMemoryNode
    inputs::Set{<:AbstractReteNode}
    outputs::Set{<:AbstractReteNode}
    memory::Set{T}

    IsaMemoryNode{T}() where {T} =
        new(Set{AbstractReteNode}(),
            Set{AbstractReteNode}(),
            Set{T}())
                
end

label(node::IsaMemoryNode{T}) where {T} = "isa $T memory"


function receive(node::IsaMemoryNode, fact)
    # Ignore facts not relevant to this memory node.
end

function receive(node::IsaMemoryNode{T}, fact::T) where{T}
    push!(node.memory, fact)
    for output in node.outputs
        emit(node, output, fact)
    end
end

