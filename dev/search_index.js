var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = Rete","category":"page"},{"location":"#Rete","page":"Home","title":"Rete","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for Rete.","category":"page"},{"location":"#Facts","page":"Home","title":"Facts","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The facts in our reasoning system can be arbitrary Julia objects. It's best to restrict facts to immutable objects though so that they can't be altered once they're stored in the network or conclusions have been made.","category":"page"},{"location":"#The-Network","page":"Home","title":"The Network","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The reasoning is performed by a network of nodes.  Facts flow through the network from node to node.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Each node has a set of input nodes (those that send it facts), and a set of outputs (those nodes to which it sends facts). connect is used to construct the network by linking nodes together.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Some nodes filter the facts and only pass through those that satisfy some predicate or are instances of a certain type.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Some nodes store facts.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Join nodes have two input streams.  A function is applied to all possible combinations of facts coming in from the two streams.  The function can call emit to assert a new fact to the network.","category":"page"},{"location":"","page":"Home","title":"Home","text":"That's the theory.  In practice, its simpler if a given node performs more than one of these roles.  One such example is IsaMemoryNode, which filters facts that match a type parameter and remember only those facts.","category":"page"},{"location":"","page":"Home","title":"Home","text":"We assume that the network is fully constructed before any facts are asserted.  Adding inputs to a JoinNode doesn't cause existing facts from those inputs to be processed.","category":"page"},{"location":"#Flow-of-Facts-through-the-Network","page":"Home","title":"Flow of Facts through the Network","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"A node receives a fact via its receive method.","category":"page"},{"location":"","page":"Home","title":"Home","text":"A node distributes a fact to its outputs using its emit method, which calls receive for each of the node's outputs.","category":"page"},{"location":"#Rules","page":"Home","title":"Rules","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The @rule macro makes it easier to create rules and add them to a Rete.","category":"page"},{"location":"","page":"Home","title":"Home","text":"As a contried exanple, lets create a network that creates pairs of letters when the second letter in the pair is the next letter of the alphabet from the first.","category":"page"},{"location":"","page":"Home","title":"Home","text":"using Rete\n\n@rule PairConectutiveLetters(a::Char, b::Char) begin\n    if codepoint(a) + 1 == codepoint(b)\n        emit(a * b)\n    end\nend","category":"page"},{"location":"","page":"Home","title":"Home","text":"@rule will define a singleton type named PairConectutiveLetters to represent the rule.  It @rule defines an install method that will add the rule to a network.  The instance of `PairConectutiveLetters implements the join function of the JoinNode.","category":"page"},{"location":"","page":"Home","title":"Home","text":"root = BasicReteNode(\"root\")\ninstall(root, PairConectutiveLetters())\nensure_IsaMemoryNode(root, String) # to colect the output\n\nfor c in 'a':'e'\n    receive(root, c)\nend\n\ncollect(find_memory_for_type(root, String).memory)","category":"page"},{"location":"#Index","page":"Home","title":"Index","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"#Glossary","page":"Home","title":"Glossary","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Modules = [Rete]","category":"page"},{"location":"#Rete.AbstractMemoryNode","page":"Home","title":"Rete.AbstractMemoryNode","text":"AbstractMemoryNode is the abstract supertype of all Rete memory nodes.\n\n\n\n\n\n","category":"type"},{"location":"#Rete.AbstractReteJoinNode","page":"Home","title":"Rete.AbstractReteJoinNode","text":"AbstractReteJoinNode is the abstract supertype of all Rete join nodes.\n\n\n\n\n\n","category":"type"},{"location":"#Rete.AbstractReteNode","page":"Home","title":"Rete.AbstractReteNode","text":"AbstractReteNode is the abstract supertype of all Rete nodes.\n\n\n\n\n\n","category":"type"},{"location":"#Rete.IsaMemoryNode","page":"Home","title":"Rete.IsaMemoryNode","text":"IsaMemoryNode is a type of memory node that only stores facts of the specified type.  Facts of other types are ignored.\n\n\n\n\n\n","category":"type"},{"location":"#Rete.JoinNode","page":"Home","title":"Rete.JoinNode","text":"JoinNode implements a join operation between two streams of inputs A abd B.  The first argiment of join_function is the JoinNode itself. The second comes from the A stream.  The third comes from the B stream.  join_function should call emit for each new fact it wants to assert.\n\n\n\n\n\n","category":"type"},{"location":"#Rete.Rule","page":"Home","title":"Rete.Rule","text":"Rule is an abstract supertype for all rules.\n\n\n\n\n\n","category":"type"},{"location":"#Rete.askc","page":"Home","title":"Rete.askc","text":"askc(continuation, node)\n\nCalls continuation on each fact available through node.\n\n\n\n\n\n","category":"function"},{"location":"#Rete.collecting-Tuple{Any}","page":"Home","title":"Rete.collecting","text":"collecting(body)\n\nruns body, passing it a continuation of one argument that collects the values it's called with. collecting returns those values.\n\n\n\n\n\n","category":"method"},{"location":"#Rete.connect-Tuple{AbstractReteNode, AbstractReteNode}","page":"Home","title":"Rete.connect","text":"connect(from, to)\n\nmakes to an output of from and from an input of to.\n\n\n\n\n\n","category":"method"},{"location":"#Rete.emit","page":"Home","title":"Rete.emit","text":"emit(node, fact)\n\nDistribute's fact to each of node's outputs by calling receive on the output node and fact.\n\n\n\n\n\n","category":"function"},{"location":"#Rete.ensure_IsaMemoryNode-Tuple{Any, Type}","page":"Home","title":"Rete.ensure_IsaMemoryNode","text":"ensure_IsaMemoryNode(root, typ::Type)::IsaTypeNode\n\nFind the IsaMemoryNode for the specified type, or make one and add it to the network.\n\n\n\n\n\n","category":"method"},{"location":"#Rete.find_memory_for_type-Tuple{Any, Type}","page":"Home","title":"Rete.find_memory_for_type","text":"find_memory_for_type(root, typ::Type)::UnionPNothing, IsaTypeNode}\n\nIf there's a memory node in the Rete represented by root that stores objects of the specified type then return it.  Otherwiaw return nothing.\n\n\n\n\n\n","category":"method"},{"location":"#Rete.inputs","page":"Home","title":"Rete.inputs","text":"inputs(node)\n\nReturns the inputs of node – those nodes which can send it facts.\n\n\n\n\n\n","category":"function"},{"location":"#Rete.install","page":"Home","title":"Rete.install","text":"install(root, rule)\n\nInstalls the rule or rule group into the Rete rooted at root.\n\n\n\n\n\n","category":"function"},{"location":"#Rete.label","page":"Home","title":"Rete.label","text":"label(node)\n\nReturns node's label.\n\n\n\n\n\n","category":"function"},{"location":"#Rete.outputs","page":"Home","title":"Rete.outputs","text":"outputs(node)\n\nReturns the outputs of node – those nodes to which it can send facts.\n\n\n\n\n\n","category":"function"},{"location":"#Rete.receive","page":"Home","title":"Rete.receive","text":"receive(node, fact)\n\nreceive is how node is given a new fact.\n\n\n\n\n\n","category":"function"},{"location":"#Rete.@rule-Tuple{Any, Any}","page":"Home","title":"Rete.@rule","text":"@rule Rulename(a::A_Type, b::B_Type, ...) begin ... end\n\nDefines a rule named Rulename.  A singleton type named Rulename will be defined to represent the rule.  An install method is defined for that type which can be used to add the necessary nodes and connections to a Rete to implement the rule.\n\nThe default supertype of a rule struct is Rule.  When it is desirable to group rules together, one can define an abstract type that is a type descendant of Rule and use that as a dotted prefix to RuleName.  The the RuleName in the @rule invocation is MyGroup.MyRule then the supertype of MyRule will be MyGroup, rather than Rule.\n\nA rule an have arbitrarily many parameters.  The parameter list can also include clauses with no variable name.  Such clauses identify the types of facts that the rule might assert.  Memory nodes for these types will be added to the Rete if not already present.\n\n\n\n\n\n","category":"macro"}]
}
