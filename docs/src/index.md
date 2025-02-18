```@meta
CurrentModule = Rete
```

# Rete

Documentation for [Rete](https://github.com/MarkNahabedian/Rete.jl).

Rete currently implements memory for Julia types, forward chaining
joins, and backward chaining filter and extrema operations.


## Facts

The *facts* in our reasoning system can be arbitrary Julia objects.
It's best to restrict *facts* to immutable objects though so that they
can't be altered once they're stored in the network or conclusions
have been made.  There is no mechanism for retracting a conclusion if
a fact object is modified.


## The Network

The reasoning is performed by a network of nodes.  *Facts* flow
through the network from node to node.

Each node has a set of input nodes (those that send it *facts*), and a
set of outputs (those nodes to which it sends *facts*).
[`connect`](@ref) is used to construct the network by linking nodes
together.

Some nodes filter the *facts* and only pass through those that satisfy
some predicate or are instances of a certain type.

Some nodes store *facts*.

Join nodes have multiple distinct input streams.  A function is
applied to all possible combinations of facts coming in from these
streams.  The function can call [`emit`](@ref) to assert a new *fact*
to the network.


That's the theory.  In practice, its simpler if a given node performs
more than one of these roles.  One such example is
[`IsaMemoryNode`](@ref), which filters *facts* that match a type
parameter and remember only those *facts*.

We assume that the network is fully constructed before any facts are
asserted.  Adding inputs to a JoinNode doesn't cause existing facts
from those inputs to be processed.


### Layers

The network might best be constructed in layers.  A single root node
forms the top layer.  It serves as the recipient of new facts.  It
distributes those facts to the next layer, which consists of memory
nodes.  A third layer consists of join nodes, typically defined by
rules.  The join nodes might conclude new facts which they pass to the
root node.


## Flow of Facts through the Network

A node receives a *fact* via its [`receive`](@ref) method.

A node distributes a *fact* to its outputs using its [`emit`](@ref)
method, which calls [`receive`](@ref) for each of the node's outputs.


## Rules

The [`@rule`](@ref) macro makes it easier to create rules and add them
to a Rete.

As a contrived exanple, lets create a network that creates pairs of
letters when the second letter in the pair is the next letter of the
alphabet from the first.

```@example rule1
using Rete

@rule PairConsectutiveLettersRule(a::Char, b::Char, ::String) begin
    if codepoint(a) + 1 == codepoint(b)
        emit(a * b)
    end
end
```

[`@rule`](@ref) will define a singleton type named
`PairConsectutiveLettersRule` to represent the rule.  `@rule` defines an
`install` method that will add the rule to a network.  The instance of
`PairConsectutiveLettersRule` implements the join function of the JoinNode.


```@example rule1
# Create the knowledgebase:
root = ReteRootNode("root")
install(root, PairConsectutiveLettersRule())

# Assert the characters 'a' through 'e' into the knowledgebase:
for c in 'a':'e'
    receive(root, c)
end

askc(Collector{String}(), root)
```


## Backward Chaining

Rete currently provides limited support for backward chaining by using
the [`BackwardFilterNode`](@ref) and [`BackwardExtremumNode`](@ref)
node types.

There is not yet any facility to make it easier to integrate these
nodes into the network.  You will need to use the node constructors
and [`connect`](@ref) to add them by hand.



## Querying and Aggregation

The function [`askc`](@ref) can be used to query the network.  `askc`
takes either a continuation function or an [`Aggregator`](@ref) as its
first argument.

`askc` also takes either a node that supports it, e.g. memory nodes or
backweard chaining nodes; or an [`AbstractReteRootNode`](@ref)
representing your knowledge base, and a fact type.  In this latter
case, [`find_memory_for_type`](@ref) is used to find the appropriate
memory node for the specified type.

The continuation function is callled on each fact that `askc` finds.

Normally, askc has no return value.  If an aggregator is passed as the
first argument then it will perform the specified aggregation over the
course of the query and that call to `askc` will return the
aggregation result.

The currenty supported aggregators are:

- [`Counter`](@ref)
- [`Collector`](@ref)

```@example aggewgation
using Rete
kb = ReteRootNode("My Knowledge Base")
connect(kb, IsaMemoryNode{Int}())
receive.([kb], 1:5)
nothing
```

```@example aggewgation
askc(Counter(), kb, Int)
```

```@example aggewgation
askc(Collector{Int}(), kb)
```

Note from the latter example that `askc` can infer the fact type
argument from the `Collector`.


## Customization

All custom node types are expected to inherit from [`AbstractReteNode`](@ref).

We provide some support for the definition of custom node types.


### Connectivity

The discrimination network is built from nodes using [`connect`](@ref).

Most node types have a single set of inputs and single set of outputs.

To simplify node customization, any subtype of
[`AbstractReteNode`](@ref) that includes the field definition

```
    inputs::Set{AbstractReteNode}
```

will be given the [`HasSetOfInputsTrait`](@ref) trait, and as such can
serve as an output for other nodes without additional method support.

Any subtype of [`AbstractReteNode`](@ref) that includes the field definition

```
    outputs::Set{AbstractReteNode}
```

will be given the [`HasSetOfOutputsTrait`](@ref) trait, and as such can
serve as an input for other nodes without additional method support.

This is suitable for most nodes where all of the inputs receive the
same treatment, but is not suitable for join nodes, which inherently
have multiple sets of inputs of different types that are treated
differently.  Currently there is no customization support for join
nodes.


### Custom Root Nodes

All custom root nodes are expected to inherit from
[`AbstractReteRootNode`](@ref).

Custom root nodes should also be given the
[`CanInstallRulesTrait`](@ref) trait:

```
Rete.CanInstallRulesTrait(::Type{<:MyKindOfRootNode}) = CanInstallRulesTrait()
```


### Custom Memory Nodes

You might find it useful to define your own type of memory node.  All
such types should inherit from [`AbstractMemoryNode`](@ref).  See its
documentation for general requirements on memory nodes.

Each custom memory node will need to implement [`receive`](@ref) to
store a new fact in that node.  It will also need a custom method for
[`askc`](@ref).

Custom memory nodes should have their own [`is_memory_for_type`](@ref) method.

Normally, memory nodes are created by [`ensure_memory_node`](@ref)
when a type appears as the input or output of a rule and the network
does not yet include a memory for that type.  Some applications might
include references to custom memory node types in a custom root node.
It this case, it is helpful to define a method for
[`find_memory_for_type`](@ref)

```
function Rete.find_memory_for_type(root::MyTypeOfRootNode,
                                   typ::Type{MyTypeThatNeedsACustomMemoryNode})
    # code to return the custom memory node for MyTypeThatNeedsACustomMemoryNode.
end
```


## Index

```@index
```

## Definitions

```@autodocs
Modules = [Rete]
```

