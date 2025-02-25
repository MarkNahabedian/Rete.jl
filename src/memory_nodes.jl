
using OrderedCollections: OrderedSet

export IsaMemoryNode
export is_memory_for_type, find_memory_for_type, ensure_memory_node


function emit(node::AbstractMemoryNode,
              to::AbstractReteNode, fact)
    receive(to, fact)
end

function emit(node::AbstractMemoryNode,
              to::AbstractReteJoinNode, fact)
    receive(to, fact, node)
end


"""
    IsaMemoryNode{T}()

IsaMemoryNode is a type of memory node that only stores facts of the
specified type (or subtype, as tested by `isa`).  Facts of other types
are ignored.
"""
struct IsaMemoryNode{T} <: AbstractMemoryNode
    inputs::Set{AbstractReteNode}
    outputs::Set{AbstractReteNode}
    # Prseserve insertion order for debugging:
    memory::OrderedSet{T}

    IsaMemoryNode{T}() where {T} =
        new(Set{AbstractReteNode}(),
            Set{AbstractReteNode}(),
            Set{T}())
end


inputs(node::IsaMemoryNode{T}) where {T} = node.inputs

outputs(node::IsaMemoryNode{T}) where {T} = node.outputs

label(node::IsaMemoryNode{T}) where {T} = "isa $T memory"


"""
    is_memory_for_type(node, typ::Type)::Bool

returns `true` if `node` stores objects of the specified type.

Used by [`find_memory_for_type`](@ref).
"""
is_memory_for_type(node::IsaMemoryNode, typ::Type)::Bool =
    memory_node_type(node) == typ

# Default method:
Rete.is_memory_for_type(::AbstractMemoryNode, ::Any) = false


memory_node_type(node::IsaMemoryNode) = typeof(node).parameters[1]


function receive(node::AbstractMemoryNode, fact)
    # Ignore facts not relevant to this memory node.
end

function receive(node::IsaMemoryNode{T}, fact::T) where{T}
    if !isa(fact, memory_node_type(node))
        return
    end
    if fact in node.memory
        return
    end
    push!(node.memory, fact)
    for output in node.outputs
        emit(node, output, fact)
    end
end


function askc(continuation::Function, node::IsaMemoryNode)
    for fact in node.memory
        continuation(fact)
    end
end

"""
    askc(continuation, root::AbstractReteRootNode, t::Type)

calls `continuation` on every fact of the specified type that are
stored in the network rooted at `root`.

Does not consider subtypes because that could lead to `continuation`
being called on the same fact more than once (from the memory node for
the type itself and from the memory nodes of subtypes).

Assumes all memory nodes are direct outputs of `root`.

Also assumes that every output of `root` implements `is_memory_for_type`.
"""
function askc(continuation, root::AbstractReteRootNode, t::Type)
    mem = find_memory_for_type(root, t)
    if mem === nothing
        error("No memory node for type $t")
    end
    askc(continuation, mem)
end


"""
    find_memory_for_type(root, typ::Type)::Union(Nothing, AbstractMemoryNode}

If there's a memory node in the Rete represented by `root` that stores
objects of the specified type then return it.  Otherwise return
nothing.
"""
function find_memory_for_type(root::AbstractReteRootNode,
                              typ::Type)::Union{Nothing, AbstractMemoryNode}
    for o in root.outputs
        if is_memory_for_type(o, typ)
            return o
        end
    end
    return nothing
end


"""
    ensure_memory_node(root::AbstractReteRootNode, typ::Type)::IsaTypeNode

Find a memory node for the specified type, or make one and add it
to the network.

The default is to make an IsaMemoryNode.  Specialize this function for
a `Type` to control what type of memory node should be used for that
type.
"""
function ensure_memory_node(root::AbstractReteRootNode,
                            typ::Type)::AbstractMemoryNode
    n = find_memory_for_type(root, typ)
    if n !== nothing
        return n
    end
    n = IsaMemoryNode{typ}()
    connect(root, n)
    n
end

