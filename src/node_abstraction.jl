
using Printf

export AbstractReteNode, AbstractMemoryNode, AbstractReteJoinNode
export label, inputs, outputs, emit, receive, install
export input_count, output_count, fact_count
export askc, walk_by_outputs


"""
AbstractReteNode is the abstract supertype of all Rete nodes.
"""
abstract type AbstractReteNode end


"""
AbstractMemoryNode is the abstract supertype of all Rete memory nodes.

Each concrete subtype should implement [`is_memory_for_type`](@ref) to
determine if it stores that type of fact.

A memory node should remember exactly one copy of each fact it
receives and return each fact it has remembered exactly once for any
given call to [`askc`](@ref).

A memory node should only remember facts which match the type that the
memory node is defined to store.  Not any of its subtypes.
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

Returns the inputs of `node` -- those nodes which can send it *facts*
-- as an iterable collection.
"""
function inputs end


"""
    outputs(node)

Returns the outputs of `node` -- those nodes to which it can send
*facts* -- as an iterable collection.
"""
function outputs end


"""
    input_count(node)

returns the number of inputs to the node.

Note that for join nodes, this is the number of parameters rather than
the number of nodes that emit facts to the join.
"""
input_count(node::AbstractReteNode) = length(inputs(node))


"""
    output_count(node)

returns the number of outputs from the node.
"""
output_count(node::AbstractReteNode) = length(outputs(node))


"""
    fact_count(node)

For memory nodes, return the number of facts currently stored in the
node's memory, otherwise return `nothing`.
"""
fact_count(node::AbstractReteNode) = nothing

function fact_count(node::AbstractMemoryNode)
    Counter()() do c
        askc(c, node)
    end
end


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
    askc(continuation::Function, node)

Calls `continuation` on each *fact* available from `node`.
"""
function askc end


function askc(continuation::Function, s::Set{<:AbstractReteNode})
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


function Base.show(io::IO, node::AbstractReteNode)
    print(io, "$(typeof(node)) \"$(label(node))\" with $(input_count(node)) inputs, $(output_count(node)) outputs.")
end

function Base.show(io::IO, node::AbstractMemoryNode)
    print(io, "$(typeof(node)) \"$(label(node))\" with $(input_count(node)) inputs, $(output_count(node)) outputs, $(fact_count(node)) facts.")
end

