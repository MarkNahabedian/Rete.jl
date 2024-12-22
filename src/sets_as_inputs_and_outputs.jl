# Connectivity among nodes that have normal sets of inputs and
# outputs.

export connect, HasSetOfInputsTrait, HasSetOfOuputsTrait,
    _add_input, _add_output

# Most node types have a single set of inputs and single set of
# outputs.  Inputs and outputs are each stored in a
# Set{AbstractReteNode}

# Join nodes have named inputs with some way of collecting by name.

# Might we need to support other ways of storing inputs and outputs?


"""
    connect(from::AbstractReteNode, to::AbstractReteNode)

makes `to` an output of `from` and `from` an input of `to`.

`connect` calls [`_add_input`](@ref) and [`_add_output`](@ref) to do
this.
"""
function connect(from::AbstractReteNode, to::AbstractReteNode)
    _add_input(from, to)
    _add_output(from, to)
    nothing
end


"""
    _add_input(from, to)

adds `from` as an input to `to`.

User code should never call `_add_input` directly, only through
`connect`.  Users might specialize `_add_input` if implementing a node
that needs to specialize how it stores its inputs.
"""
function _add_input end


"""
    _add_output(from, to)

adds `to` as an output of `from`.

User code should never call `_add_output` directly, only through
`connect`.  Users might specialize `_add_output` if implementing a
node that needs to specialize how it stores its outputs.
"""
function _add_output end


"""
    HasSetOfInputsTrait(type)

A Rete node type with the HasSetOfInputsTrait stores its inputs as a
set.

Any struct that is a subtype of AbstractReteNode with the field

```
    inputs::Set{AbstractReteNode}
```

will have this trait.
"""
struct HasSetOfInputsTrait end

function HasSetOfInputsTrait(::Type{T}) where (T <: AbstractReteNode)
    i = findfirst(x -> x == :inputs, fieldnames(T))
    if i isa Int && fieldtypes(T)[i] == Set{AbstractReteNode}
        HasSetOfInputsTrait()
    end
end

function _add_input(from::AbstractReteNode, to::AbstractReteNode)
    _add_input(HasSetOfInputsTrait(typeof(to)), from, to)
end

function _add_input(::HasSetOfInputsTrait,
                    from::AbstractReteNode, to::AbstractReteNode)
    push!(to.inputs, from)
end


"""
    HasSetOfOuputsTrait(type)

A Rete node type with the HasSetOfOutputsTrait stores its outputs as
a set.

Any struct that is a subtype of AbstractReteNode with the field

```
    outputs::Set{AbstractReteNode}
```

will have this trait.
"""
struct HasSetOfOutputsTrait end

function HasSetOfOutputsTrait(::Type{T}) where (T <: AbstractReteNode)
    i = findfirst(x -> x == :outputs, fieldnames(T))
    if i isa Int && fieldtypes(T)[i] == Set{AbstractReteNode}
        HasSetOfOutputsTrait()
    end
end

function _add_output(from::AbstractReteNode, to::AbstractReteNode)
    _add_output(HasSetOfOutputsTrait(typeof(from)), from, to)
end

function _add_output(::HasSetOfOutputsTrait,
                    from::AbstractReteNode, to::AbstractReteNode)
    push!(from.outputs, to)
end

