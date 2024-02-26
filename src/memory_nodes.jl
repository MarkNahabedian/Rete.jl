
using OrderedCollections: OrderedSet

export IsaMemoryNode, find_memory_for_type, ensure_IsaMemoryNode


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
    find_memory_for_type(root, typ::Type)::UnionPNothing, IsaTypeNode}

If there's a memory node in the Rete represented by `root` that stores
objects of the specified type then return it.  Otherwiaw return
nothing.
"""
function find_memory_for_type(root, typ::Type)::Union{Nothing, IsaMemoryNode}
    for o in root.outputs
        if o isa IsaMemoryNode
            if length(typeof(o).parameters) == 1
                if typ == typeof(o).parameters[1]
                    return o
                end
            end
        end
    end
    return nothing
end


"""
    ensure_IsaMemoryNode(root, typ::Type)::IsaTypeNode

Find the IsaMemoryNode for the specified type, or make one and add it
to the network.
"""
function ensure_IsaMemoryNode(root, typ::Type)::IsaMemoryNode
    n = find_memory_for_type(root, typ)
    if n !== nothing
        return n
    end
    n = IsaMemoryNode{typ}()
    connect(root, n)
    n
end

