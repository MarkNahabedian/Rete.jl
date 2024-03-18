```@meta
CurrentModule = Rete
```

# Rete

Documentation for [Rete](https://github.com/MarkNahabedian/Rete.jl).

In its current form, this package only supports forward chaining
rules.


## Facts

The *facts* in our reasoning system can be arbitrary Julia objects.
It's best to restrict *facts* to immutable objects though so that they
can't be altered once they're stored in the network or conclusions
have been made.


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

As a contried exanple, lets create a network that creates pairs of
letters when the second letter in the pair is the next letter of the
alphabet from the first.

```@example rule1
using Rete

@rule PairConectutiveLetters(a::Char, b::Char) begin
    if codepoint(a) + 1 == codepoint(b)
        emit(a * b)
    end
end
```

[`@rule`](@ref) will define a singleton type named
`PairConectutiveLetters` to represent the rule.  `@rule` defines an
`install` method that will add the rule to a network.  The instance of
`PairConectutiveLetters` implements the join function of the JoinNode.


```@example rule1
root = ReteRootNode("root")
install(root, PairConectutiveLetters())
ensure_IsaMemoryNode(root, String) # to colect the output

for c in 'a':'e'
    receive(root, c)
end

collect(find_memory_for_type(root, String).memory)
```



## Index

```@index
```

## Glossary

```@autodocs
Modules = [Rete]
```
