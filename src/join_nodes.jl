
using Base.Iterators: flatten
using IterTools: repeatedly

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
    inputs
    outputs::Set{AbstractReteNode}
    join_function

    JoinNode(label::String, input_arity, join_function) =
        new(label,
            Tuple(repeatedly(() -> Set{AbstractMemoryNode}(),
                             input_arity)),
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
    @assert input <= length(to.inputs)
    push!(from.outputs, to)
    push!(to.inputs[input], from)
end


function receive(node::JoinNode, fact, from::AbstractMemoryNode)
    args = Vector(undef, length(node.inputs))
    last_from_pos = findlast(map(i -> from in i, node.inputs))
    function helper(argnumber, hasfact)
        if argnumber > length(args)
            if hasfact
                node.join_function(node, args...)
            end
        else
            # Avoid computing more of the power set of arguments if
            # we've not added fact and we've passed the last set of
            # inputs that could contain from.
            if !hasfact && argnumber > last_from_pos
                return
            end
            for input in node.inputs[argnumber]
                askc(input) do i_fact
                    args[argnumber] = i_fact
                    helper(argnumber + 1,
                           hasfact || (i_fact == fact))
                end
            end
        end
    end
    helper(1, false)    
end

