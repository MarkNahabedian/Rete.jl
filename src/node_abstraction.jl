export AbstractReteNode, AbstractMemoryNode, AbstractReteJoinNode
export label, inputs, outputs, connect, emit, receive, install
export askc, walk_by_outputs


"""
AbstractReteNode is the abstract supertype of all Rete nodes.
"""
abstract type AbstractReteNode end


"""
AbstractMemoryNode is the abstract supertype of all Rete memory nodes.

Each concrete sybtype should implement [`is_memory_for_type`](@ref).
"""
abstract type AbstractMemoryNode <: AbstractReteNode end


"""
AbstractReteJoinNode is the abstract supertype of all Rete join nodes.
"""
abstract type AbstractReteJoinNode <: AbstractReteNode end


"""
    label(node)

Returns `node`'s label.
"""
function label end



"""
    inputs(node)

Returns the inputs of `node` -- those nodes which can send it *facts*.
"""
function inputs end


"""
    outputs(node)

Returns the outputs of `node` -- those nodes to which it can send
*facts*.
"""
function outputs end


"""
    emit(node, fact)

Distribute's `fact` to each of `node`'s outputs by calling
[`receive`](@ref) on the output node and `fact`.
"""
function emit end

function emit(node::AbstractReteNode, fact)
    for output in node.outputs
        receive(output, fact)
    end
end


"""
    receive(node, fact)

`receive` is how `node` is given a new *fact*.

An application calls `receive` on the root node to assert a new fact
to the network.
"""
function receive end


"""
    connect(from, to)

makes `to` an output of `from` and `from` an input of `to`.

When `to` is a join node then a third parameter (a positive integer)
identifies which parameter position `from` feed in to.
"""
function connect(from::AbstractReteNode, to::AbstractReteNode)
    push!(from.outputs, to)
    push!(to.inputs, from)
    nothing
end


"""
    askc(continuation, node)

Calls `continuation` on each *fact* available from `node`.
"""
function askc end


function askc(continuation, s::Set{<:AbstractReteNode})
    for input in s
        askc(input) do fact
            continuation(fact)
        end
    end
end


"""
   walk_by_outputs(func, node::AbstractReteNode)

Walks the network rooted at `root', applying func to each node.
"""
function walk_by_outputs(func, node::AbstractReteNode)
    visited = []
    function walker(node::AbstractReteNode)
        if in(node, visited)
            return
        end
        push!(visited, node)
        func(node)
        if :outputs in fieldnames(typeof(node))
            for o in node.outputs
                walker(o)
            end
        end
    end
    walker(node)
end

