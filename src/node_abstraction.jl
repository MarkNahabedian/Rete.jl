export AbstractReteNode, AbstractMemoryNode, AbstractReteJoinNode
export label, inputs, outputs, connect, emit, receive, install
export askc


"""
AbstractReteNode is the abstract supertype of all Rete nodes.
"""
abstract type AbstractReteNode end


"""
AbstractMemoryNode is the abstract supertype of all Rete memory nodes.
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
"""
function receive end


"""
    connect(from, to)

makes `to` an output of `from` and `from` an input of `to`.
"""
function connect(from::AbstractReteNode, to::AbstractReteNode)
    push!(from.outputs, to)
    push!(to.inputs, from)
    nothing
end



"""
    install(root, rule)

Installs the rule or rule group into the Rete rooted at `root`.
"""
function install end

function install(root::AbstractReteNode, rule_group)
    if isconcretetype(rule_group)
        install(root, rule_group())
    else
        for r in subtypes(rule_group)
            install(root, r)
        end
    end
end


"""
    askc(continuation, node)

Calls `continuation` on each *fact* available through `node`.
"""
function askc end


function askc(continuation, s::Set{<:AbstractReteNode})
    for input in s
        askc(input) do fact
            continuation(fact)
        end
    end
end

