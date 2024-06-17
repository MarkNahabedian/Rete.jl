# Some backwad chaining functionality

export BackwardChaining, BackwardFilterNode, BackwardExtremumNode


"""
BackwardChaining is the abstract supertype for all backward chaining
Rete nodes.
"""
abstract type BackwardChaining <: AbstractReteNode end


function receive(::BackwardChaining, fact)
    # no-op
end


"""
     BackwardFilterNode(filter_function, label)

When `askc`ed, passes through from its inputs only those facts which
satisfy `predicate`.
"""
struct BackwardFilterNode <: BackwardChaining
    inputs::Set{AbstractReteNode}
    outputs::Set{AbstractReteNode}
    predicate
    label

    function BackwardFilterNode(predicate, label)
        new(Set{AbstractReteNode}(),
            Set{AbstractReteNode}(),
            predicate, label)
    end
end

inputs(node::BackwardFilterNode) = node.inputs

outputs(node::BackwardFilterNode) = node.outputs

label(node::BackwardFilterNode) = node.label

function Base.show(io::IO, node::BackwardFilterNode)
    print(io, "$(typeof(node)) \"$(label(node))\" with $(length(inputs(node))) inputs, $(length(inputs(node))) outputs.")
end

function askc(continuation, node::BackwardFilterNode)
    for input in node.inputs
        askc(input) do fact
            if node.predicate(fact)
                continuation(fact)
            end
        end
    end
end



"""
   BackwardExtremumNode(comparison, extractor, label)

When `askc`ed, provides one value: the fact with the most extreme
value (based on `comparison`) of `extractor` applied to each input
fact at the time `askc` was called.

"""
struct BackwardExtremumNode <: BackwardChaining
    inputs::Set{AbstractReteNode}
    outputs::Set{AbstractReteNode}
    comparison
    extractor
    label

    function BackwardExtremumNode(comparison, extractor, label)
        new(Set{AbstractReteNode}(),
            Set{AbstractReteNode}(),
            comparison, extractor, label)
    end
end

inputs(node::BackwardExtremumNode) = node.inputs

outputs(node::BackwardExtremumNode) = node.outputs

label(node::BackwardExtremumNode) = node.label


function Base.show(io::IO, node::BackwardExtremumNode)
    print(io, "$(typeof(node)) \"$(label(node))\" with $(length(inputs(node))) inputs, $(length(inputs(node))) outputs.")
end

function askc(continuation, node::BackwardExtremumNode)
    extremum = nothing
    for input in node.inputs
        askc(input) do fact
            if extremum === nothing || node.comparison(node.extractor(fact),
                                                       node.extractor(extremum))
                extremum = fact
            end
        end
    end
    continuation(extremum)
end

