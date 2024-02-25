
using Base.Iterators: flatten

export JoinNode, connect_a, connect_b

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

# Maybe a JoinNode constructor that just takes the function as
# argument and uses its argument signature and function name as
# parameters
# NO.  Functions don't have signatures, methods do.

function connect(from::AbstractReteNode, to::JoinNode)
    error("Use connect_a or connect_b to connect toa JoinNode")
end

# We assume that the network is fully constructed before any facts are
# asserted.  Adding inputs to a JoinNode doesn't cause existing facts
# from those inputs to be processed.

function connect_a(from::AbstractMemoryNode, to::JoinNode)
    push!(from.outputs, to)
    push!(to.a_inputs, from)
end

function connect_b(from::AbstractMemoryNode, to::JoinNode)
    push!(from.outputs, to)
    push!(to.b_inputs, from)
end


function receive(node::JoinNode, fact, from::AbstractMemoryNode)
    if from in node.a_inputs
        # We should probably use the set unions of the input memories.
        for b_fact in flatten(map(input -> input.memory,
                                  # Because map isn't implemented for Set
                                  (i for i in node.b_inputs)))
            node.join_function(node, fact, b_fact)
        end
    elseif from in node.b_inputs
        for a_fact in flatten(map(input -> input.memory,
                                  # Because map isn't implemented for Set
                                  (i for i in node.a_inputs)))
            node.join_function(node, a_fact, fact)
        end
    end
end
