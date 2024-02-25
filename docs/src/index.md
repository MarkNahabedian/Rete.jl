```@meta
CurrentModule = Rete
```

# Rete

Documentation for [Rete](https://github.com/MarkNahabedian/Rete.jl).

## Facts

The *facts* in our reasoning system can be arbitrary Julia objects.
It's best to restrict facts to immutable objects though so that they
can't be altered once they're stored in the network or conclusions
have been made.

## The Network

The reasoning is performed by a network of nodes.  *Facts* flow
through the network from node to node.

Some nodes filter the facts and only pass through those that satisfy
some predicate or are instances of a certain type.

Some nodes store *facts*.

Join nodes have two input streams and produce all possible
combinations of facts cming in from the two streams.

Each node has a set of input nodes (those that send it *facts*), and a
set of outputs (those nodes to which it sends *facts*).
[`connect`](@ref) is used to construct the network by linking nodes
together.



That's the theory.  In practice, its simpler if a given node performs
more than one of these roles.  One such example is
[`IsaMemoryNode`](@ref), which filters *facts* that match a type
parameter and remember only those ^facts*.


## Flow of Facts through the Network

A node receives a *fact* via its [`receive`](@ref) method.

A node distributes a *fact* to its outputs using its [`emit`](@ref)
method, which calls [`receive`](@ref) for each of the node's outputs.


```@index
```

```@autodocs
Modules = [Rete]
```
