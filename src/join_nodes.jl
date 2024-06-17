
using IterTools: repeatedly

export JoinNode, add_forward_trigger, is_forward_trigger


"""
JoinNode implements a join operation between multiple streams of
inputs.  The first argiment of `join_function` is the JoinNode itself.
The remaining arguments come from the input streams of the join node.
`join_function` should call `emit` for each new fact it wants to
assert.
"""
struct JoinNode <: AbstractReteJoinNode
    label::String
    inputs
    outputs::Set{AbstractReteNode}
    forward_triggers::Set{AbstractReteNode}
    join_function

    JoinNode(label::String, input_arity, join_function) =
        new(label,
            # inputs:
            Tuple(repeatedly(() -> Set{AbstractMemoryNode}(),
                             input_arity)),
            # outputs:
            Set{AbstractReteNode}(),
            # forward_triggers
            Set{AbstractReteNode}(),
            join_function)
end

inputs(n::JoinNode) = n.inputs

outputs(n::JoinNode) = n.outputs

label(n::JoinNode) = n.label

function Base.show(io::IO, node::JoinNode)
    print(io, "$(typeof(node)) \"$(label(node))\" with $(length(inputs(node))) inputs, $(length(inputs(node))) outputs.")
end


function connect(from::AbstractReteNode, to::JoinNode, input::Int)
    @assert input >= 1
    @assert input <= length(to.inputs)
    push!(from.outputs, to)
    push!(to.inputs[input], from)
end


"""
    add_forward_trigger(n::JoinNode, from::AbstractReteNode)

adds `from` as a forward trigger of the JoinNode.

When a JoinNode `receive`s a fact from one of its forward trigger
inputs, it joins that input with all combinations of facts from other
inputs and performs its `join_function`.  Otherwise the JoinNode is
not triggered.
"""
function add_forward_trigger(n::JoinNode, from::AbstractReteNode)
    push!(n.forward_triggers, from)
end


"""
    is_forward_trigger(::JoinNode, from::AbstractReteNode)

returns true if `from` is a forward trigger input of the JoinNode.
"""
is_forward_trigger(n::JoinNode, from::AbstractReteNode) =
    in(from, n.forward_triggers)


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
            if is_forward_trigger(node, from)
                for input in node.inputs[argnumber]
                    askc(input) do i_fact
                        args[argnumber] = i_fact
                        helper(argnumber + 1,
                               hasfact || (i_fact == fact))
                    end
                end
            end
        end
    end
    helper(1, false)    
end

