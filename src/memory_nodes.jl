
using OrderedCollections: OrderedSet

export IsaMemoryNode, ensure_IsaMemoryNode


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
    # Prseserve insertion order for debugging:
    memory::OrderedSet{T}

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
    if fact in node.memory
        return
    end
    for output in node.outputs
        emit(node, output, fact)
    end
    push!(node.memory, fact)
end

"""
    ensure_IsaMemoryNode(root, typ::Type)::IsaTypeNode

Find the IsaMemoryNode for the specified type, or add a new one.
"""
function ensure_IsaMemoryNode(root, typ::Type)::IsaMemoryNode
    for o in root.outputs
        if o isa IsaMemoryNode
            if length(typeof(o).parameters) == 1
                if typ == typeof(o).parameters[1]
                    return o
                end
            end
        end
    end
    n = IsaMemoryNode{typ}()
    connect(root, n)
    n
end

