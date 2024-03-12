
using Base.Iterators: flatten

export JoinNode

"""
JoinNode implements a join operation between two streams of inputs A
abd B.  The first argiment of `join_function` is the JoinNode itself.
The second comes from the A stream.  The third comes from the B
stream.  `join_function` should call `emit` for each new fact it wants
to assert.
"""
struct JoinNode <: AbstractReteJoinNode
    label::String
    a_inputs   # ::Set{AbstractMemoryNode{T1}}
    b_inputs   # ::Set{AbstractMemoryNode{T2}}
    outputs::Set{AbstractReteNode}
    join_function

    JoinNode(label::String, join_function) =
        new(label,
            Set{AbstractMemoryNode}(),
            Set{AbstractMemoryNode}(),
            Set{AbstractReteNode}(),
            join_function)
end

label(n::JoinNode) = n.label


# Maybe a JoinNode constructor that just takes the function as
# argument and uses its argument signature and function name as
# parameters
# NO.  Functions don't have signatures, methods do.

function connect(from::AbstractReteNode, to::JoinNode, input::Int)
    @assert input >= 1
    @assert input <= 2
    push!(from.outputs, to)
    if input == 1
        push!(to.a_inputs, from)
    else
        push!(to.b_inputs, from)
    end
end


function receive(node::JoinNode, fact, from::AbstractMemoryNode)
    if from in node.a_inputs
        askc(node.b_inputs) do b_fact
            node.join_function(node, fact, b_fact)
        end
    end
    if from in node.b_inputs
        askc(node.a_inputs) do a_fact
            node.join_function(node, a_fact, fact)
        end
    end
end

