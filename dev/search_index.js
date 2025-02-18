var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = Rete","category":"page"},{"location":"#Rete","page":"Home","title":"Rete","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for Rete.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Rete currently implements memory for Julia types, forward chaining joins, and backward chaining filter and extrema operations.","category":"page"},{"location":"#Facts","page":"Home","title":"Facts","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The facts in our reasoning system can be arbitrary Julia objects. It's best to restrict facts to immutable objects though so that they can't be altered once they're stored in the network or conclusions have been made.  There is no mechanism for retracting a conclusion if a fact object is modified.","category":"page"},{"location":"#The-Network","page":"Home","title":"The Network","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The reasoning is performed by a network of nodes.  Facts flow through the network from node to node.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Each node has a set of input nodes (those that send it facts), and a set of outputs (those nodes to which it sends facts). connect is used to construct the network by linking nodes together.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Some nodes filter the facts and only pass through those that satisfy some predicate or are instances of a certain type.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Some nodes store facts.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Join nodes have multiple distinct input streams.  A function is applied to all possible combinations of facts coming in from these streams.  The function can call emit to assert a new fact to the network.","category":"page"},{"location":"","page":"Home","title":"Home","text":"That's the theory.  In practice, its simpler if a given node performs more than one of these roles.  One such example is IsaMemoryNode, which filters facts that match a type parameter and remember only those facts.","category":"page"},{"location":"","page":"Home","title":"Home","text":"We assume that the network is fully constructed before any facts are asserted.  Adding inputs to a JoinNode doesn't cause existing facts from those inputs to be processed.","category":"page"},{"location":"#Layers","page":"Home","title":"Layers","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The network might best be constructed in layers.  A single root node forms the top layer.  It serves as the recipient of new facts.  It distributes those facts to the next layer, which consists of memory nodes.  A third layer consists of join nodes, typically defined by rules.  The join nodes might conclude new facts which they pass to the root node.","category":"page"},{"location":"#Flow-of-Facts-through-the-Network","page":"Home","title":"Flow of Facts through the Network","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"A node receives a fact via its receive method.","category":"page"},{"location":"","page":"Home","title":"Home","text":"A node distributes a fact to its outputs using its emit method, which calls receive for each of the node's outputs.","category":"page"},{"location":"#Rules","page":"Home","title":"Rules","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The @rule macro makes it easier to create rules and add them to a Rete.","category":"page"},{"location":"","page":"Home","title":"Home","text":"As a contrived exanple, lets create a network that creates pairs of letters when the second letter in the pair is the next letter of the alphabet from the first.","category":"page"},{"location":"","page":"Home","title":"Home","text":"using Rete\n\n@rule PairConsectutiveLettersRule(a::Char, b::Char, ::String) begin\n    if codepoint(a) + 1 == codepoint(b)\n        emit(a * b)\n    end\nend","category":"page"},{"location":"","page":"Home","title":"Home","text":"@rule will define a singleton type named PairConsectutiveLettersRule to represent the rule.  @rule defines an install method that will add the rule to a network.  The instance of PairConsectutiveLettersRule implements the join function of the JoinNode.","category":"page"},{"location":"","page":"Home","title":"Home","text":"# Create the knowledgebase:\nroot = ReteRootNode(\"root\")\ninstall(root, PairConsectutiveLettersRule())\n\n# Assert the characters 'a' through 'e' into the knowledgebase:\nfor c in 'a':'e'\n    receive(root, c)\nend\n\naskc(Collector{String}(), root)","category":"page"},{"location":"#Backward-Chaining","page":"Home","title":"Backward Chaining","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Rete currently provides limited support for backward chaining by using the BackwardFilterNode and BackwardExtremumNode node types.","category":"page"},{"location":"","page":"Home","title":"Home","text":"There is not yet any facility to make it easier to integrate these nodes into the network.  You will need to use the node constructors and connect to add them by hand.","category":"page"},{"location":"#Querying-and-Aggregation","page":"Home","title":"Querying and Aggregation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The function askc can be used to query the network.  askc takes either a continuation function or an Aggregator as its first argument.","category":"page"},{"location":"","page":"Home","title":"Home","text":"askc also takes either a node that supports it, e.g. memory nodes or backweard chaining nodes; or an AbstractReteRootNode representing your knowledge base, and a fact type.  In this latter case, find_memory_for_type is used to find the appropriate memory node for the specified type.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The continuation function is callled on each fact that askc finds.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Normally, askc has no return value.  If an aggregator is passed as the first argument then it will perform the specified aggregation over the course of the query and that call to askc will return the aggregation result.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The currenty supported aggregators are:","category":"page"},{"location":"","page":"Home","title":"Home","text":"Counter\nCollector","category":"page"},{"location":"","page":"Home","title":"Home","text":"using Rete\nkb = ReteRootNode(\"My Knowledge Base\")\nconnect(kb, IsaMemoryNode{Int}())\nreceive.([kb], 1:5)\nnothing","category":"page"},{"location":"","page":"Home","title":"Home","text":"askc(Counter(), kb, Int)","category":"page"},{"location":"","page":"Home","title":"Home","text":"askc(Collector{Int}(), kb)","category":"page"},{"location":"","page":"Home","title":"Home","text":"Note from the latter example that askc can infer the fact type argument from the Collector.","category":"page"},{"location":"#Customization","page":"Home","title":"Customization","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"All custom node types are expected to inherit from AbstractReteNode.","category":"page"},{"location":"","page":"Home","title":"Home","text":"We provide some support for the definition of custom node types.","category":"page"},{"location":"#Connectivity","page":"Home","title":"Connectivity","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The discrimination network is built from nodes using connect.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Most node types have a single set of inputs and single set of outputs.","category":"page"},{"location":"","page":"Home","title":"Home","text":"To simplify node customization, any subtype of AbstractReteNode that includes the field definition","category":"page"},{"location":"","page":"Home","title":"Home","text":"    inputs::Set{AbstractReteNode}","category":"page"},{"location":"","page":"Home","title":"Home","text":"will be given the HasSetOfInputsTrait trait, and as such can serve as an output for other nodes without additional method support.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Any subtype of AbstractReteNode that includes the field definition","category":"page"},{"location":"","page":"Home","title":"Home","text":"    outputs::Set{AbstractReteNode}","category":"page"},{"location":"","page":"Home","title":"Home","text":"will be given the HasSetOfOutputsTrait trait, and as such can serve as an input for other nodes without additional method support.","category":"page"},{"location":"","page":"Home","title":"Home","text":"This is suitable for most nodes where all of the inputs receive the same treatment, but is not suitable for join nodes, which inherently have multiple sets of inputs of different types that are treated differently.  Currently there is no customization support for join nodes.","category":"page"},{"location":"#Custom-Root-Nodes","page":"Home","title":"Custom Root Nodes","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"All custom root nodes are expected to inherit from AbstractReteRootNode.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Custom root nodes should also be given the CanInstallRulesTrait trait:","category":"page"},{"location":"","page":"Home","title":"Home","text":"Rete.CanInstallRulesTrait(::Type{<:MyKindOfRootNode}) = CanInstallRulesTrait()","category":"page"},{"location":"#Custom-Memory-Nodes","page":"Home","title":"Custom Memory Nodes","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"You might find it useful to define your own type of memory node.  All such types should inherit from AbstractMemoryNode.  See its documentation for general requirements on memory nodes.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Each custom memory node will need to implement receive to store a new fact in that node.  It will also need a custom method for askc.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Custom memory nodes should have their own is_memory_for_type method.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Normally, memory nodes are created by ensure_memory_node when a type appears as the input or output of a rule and the network does not yet include a memory for that type.  Some applications might include references to custom memory node types in a custom root node. It this case, it is helpful to define a method for find_memory_for_type","category":"page"},{"location":"","page":"Home","title":"Home","text":"function Rete.find_memory_for_type(root::MyTypeOfRootNode,\n                                   typ::Type{MyTypeThatNeedsACustomMemoryNode})\n    # code to return the custom memory node for MyTypeThatNeedsACustomMemoryNode.\nend","category":"page"},{"location":"#Index","page":"Home","title":"Index","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"#Definitions","page":"Home","title":"Definitions","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Modules = [Rete]","category":"page"},{"location":"#Rete.AbstractMemoryNode","page":"Home","title":"Rete.AbstractMemoryNode","text":"AbstractMemoryNode is the abstract supertype of all Rete memory nodes.\n\nEach concrete subtype should implement is_memory_for_type to determine if it stores that type of fact.\n\nA memory node should remember exactly one copy of each fact it receives and return each fact it has remembered exactly once for any given call to askc.\n\nA memory node should only remember facts which match the type that the memory node is defined to store.  Not any of its subtypes.\n\n\n\n\n\n","category":"type"},{"location":"#Rete.AbstractReteJoinNode","page":"Home","title":"Rete.AbstractReteJoinNode","text":"AbstractReteJoinNode is the abstract supertype of all Rete join nodes.\n\n\n\n\n\n","category":"type"},{"location":"#Rete.AbstractReteNode","page":"Home","title":"Rete.AbstractReteNode","text":"AbstractReteNode is the abstract supertype of all Rete nodes.\n\n\n\n\n\n","category":"type"},{"location":"#Rete.AbstractReteRootNode","page":"Home","title":"Rete.AbstractReteRootNode","text":"AbstractReteRootNode\n\nAbstractReteRootNode is the abstract supertype for all root nodes of a Rete.\n\n\n\n\n\n","category":"type"},{"location":"#Rete.Aggregator","page":"Home","title":"Rete.Aggregator","text":"Aggergator is the abstract supertype for all query aggregators.\n\n\n\n\n\n","category":"type"},{"location":"#Rete.BackwardChaining","page":"Home","title":"Rete.BackwardChaining","text":"BackwardChaining is the abstract supertype for all backward chaining Rete nodes.\n\n\n\n\n\n","category":"type"},{"location":"#Rete.BackwardExtremumNode","page":"Home","title":"Rete.BackwardExtremumNode","text":"BackwardExtremumNode(comparison, extractor, label)\n\nWhen askced, provides one value: the fact with the most extreme value (based on comparison) of extractor applied to each input fact at the time askc was called.\n\n\n\n\n\n","category":"type"},{"location":"#Rete.BackwardFilterNode","page":"Home","title":"Rete.BackwardFilterNode","text":" BackwardFilterNode(filter_function, label)\n\nWhen askced, passes through from its inputs only those facts which satisfy predicate.\n\n\n\n\n\n","category":"type"},{"location":"#Rete.CanInstallRulesTrait","page":"Home","title":"Rete.CanInstallRulesTrait","text":"CanInstallRulesTrait\n\nHaving this trait gives the root node of a knowledge base the install method to facilitate adding rules to the network.\n\nYou can add this trait to YourType with\n\nCanInstallRulesTrait(::Type{<:YourType}) = CanInstallRulesTrait())\n\n\n\n\n\n","category":"type"},{"location":"#Rete.Collector","page":"Home","title":"Rete.Collector","text":"Collector{T}()\n\nreturns an Aggregator that can be passed as the \"continuation\" function of askc so that askc will return a vector of the objects that it found.\n\n\n\n\n\n","category":"type"},{"location":"#Rete.Counter","page":"Home","title":"Rete.Counter","text":"Counter()\n\nreturns an Aggregator that can be passed as the \"continuation\" function of askc so that askc will return the number of objects that it found.\n\n\n\n\n\n","category":"type"},{"location":"#Rete.HasSetOfInputsTrait","page":"Home","title":"Rete.HasSetOfInputsTrait","text":"HasSetOfInputsTrait(type)\n\nA Rete node type with the HasSetOfInputsTrait stores its inputs as a set.\n\nAny struct that is a subtype of AbstractReteNode with the field\n\n    inputs::Set{AbstractReteNode}\n\nwill have this trait.\n\n\n\n\n\n","category":"type"},{"location":"#Rete.HasSetOfOutputsTrait","page":"Home","title":"Rete.HasSetOfOutputsTrait","text":"HasSetOfOuputsTrait(type)\n\nA Rete node type with the HasSetOfOutputsTrait stores its outputs as a set.\n\nAny struct that is a subtype of AbstractReteNode with the field\n\n    outputs::Set{AbstractReteNode}\n\nwill have this trait.\n\n\n\n\n\n","category":"type"},{"location":"#Rete.IsaMemoryNode","page":"Home","title":"Rete.IsaMemoryNode","text":"IsaMemoryNode{T}()\n\nIsaMemoryNode is a type of memory node that only stores facts of the specified type (or subtype, as tested by isa).  Facts of other types are ignored.\n\n\n\n\n\n","category":"type"},{"location":"#Rete.JoinNode","page":"Home","title":"Rete.JoinNode","text":"JoinNode implements a join operation between multiple streams of inputs.  The first argiment of join_function is the JoinNode itself. The remaining arguments come from the input streams of the join node. join_function should call emit for each new fact it wants to assert.\n\n\n\n\n\n","category":"type"},{"location":"#Rete.ReteRootNode","page":"Home","title":"Rete.ReteRootNode","text":"ReteRootNode\n\nReteRootNode serves as the root node of a Rete network.\n\nIf you need a specialized root node for your application, see AbstractReteRootNode and CanInstallRulesTrait.\n\n\n\n\n\n","category":"type"},{"location":"#Rete.Rule","page":"Home","title":"Rete.Rule","text":"Rule is an abstract supertype for all rules.\n\n\n\n\n\n","category":"type"},{"location":"#Rete._add_input","page":"Home","title":"Rete._add_input","text":"_add_input(from, to)\n\nadds from as an input to to.\n\nUser code should never call _add_input directly, only through connect.  Users might specialize _add_input if implementing a node that needs to specialize how it stores its inputs.\n\n\n\n\n\n","category":"function"},{"location":"#Rete._add_output","page":"Home","title":"Rete._add_output","text":"_add_output(from, to)\n\nadds to as an output of from.\n\nUser code should never call _add_output directly, only through connect.  Users might specialize _add_output if implementing a node that needs to specialize how it stores its outputs.\n\n\n\n\n\n","category":"function"},{"location":"#Rete.add_forward_trigger-Tuple{JoinNode, AbstractReteNode}","page":"Home","title":"Rete.add_forward_trigger","text":"add_forward_trigger(n::JoinNode, from::AbstractReteNode)\n\nadds from as a forward trigger of the JoinNode.\n\nWhen a JoinNode receives a fact from one of its forward trigger inputs, it joins that input with all combinations of facts from other inputs and performs its join_function.  Otherwise the JoinNode is not triggered.\n\n\n\n\n\n","category":"method"},{"location":"#Rete.askc","page":"Home","title":"Rete.askc","text":"askc(continuation::Function, node)\n\nCalls continuation on each fact available from node.\n\n\n\n\n\n","category":"function"},{"location":"#Rete.askc-Tuple{Any, AbstractReteRootNode, Type}","page":"Home","title":"Rete.askc","text":"askc(continuation, root::AbstractReteRootNode, t::Type)\n\ncalls continuation on every fact of the specified type that are stored in the network rooted at root.\n\nDoes not consider subtypes because that could lead to continuation being called on the same fact more than once (from the memory node for the type itself and from the memory nodes of subtypes).\n\nAssumes all memory nodes are direct outputs of root.\n\nAlso assumes that every output of root implements is_memory_for_type.\n\n\n\n\n\n","category":"method"},{"location":"#Rete.connect-Tuple{AbstractReteNode, AbstractReteNode}","page":"Home","title":"Rete.connect","text":"connect(from::AbstractReteNode, to::AbstractReteNode)\n\nmakes to an output of from and from an input of to.\n\nconnect calls _add_input and _add_output to do this.\n\n\n\n\n\n","category":"method"},{"location":"#Rete.copy_facts-Tuple{AbstractReteRootNode, AbstractReteRootNode, Any}","page":"Home","title":"Rete.copy_facts","text":"copy_facts(from_kb::AbstractReteRootNode, to_kb::AbstractReteRootNode, fact_types)\n\nCopues facts if the specified fact_type from from_kb to to_kb.\n\nfor multiple fact types, one can broadcast over a collection of fact types.\n\n\n\n\n\n","category":"method"},{"location":"#Rete.emit","page":"Home","title":"Rete.emit","text":"emit(node, fact)\n\nDistribute's fact to each of node's outputs by calling receive on the output node and fact.\n\n\n\n\n\n","category":"function"},{"location":"#Rete.emits-Tuple{Any}","page":"Home","title":"Rete.emits","text":"emits(rule::Type)\n\nReturns a Tuple of the types which rule is declared to emit.\n\n\n\n\n\n","category":"method"},{"location":"#Rete.ensure_memory_node-Tuple{AbstractReteRootNode, Type}","page":"Home","title":"Rete.ensure_memory_node","text":"ensure_memory_node(root::AbstractReteRootNode, typ::Type)::IsaTypeNode\n\nFind a memory node for the specified type, or make one and add it to the network.\n\nThe default is to make an IsaMemoryNode.  Specialize this function for a Type to control what type of memory node should be used for that type.\n\n\n\n\n\n","category":"method"},{"location":"#Rete.fact_count-Tuple{AbstractReteNode}","page":"Home","title":"Rete.fact_count","text":"fact_count(node)\n\nFor memory nodes, return the number of facts currently stored in the node's memory, otherwise return nothing.\n\n\n\n\n\n","category":"method"},{"location":"#Rete.find_memory_for_type-Tuple{AbstractReteRootNode, Type}","page":"Home","title":"Rete.find_memory_for_type","text":"find_memory_for_type(root, typ::Type)::Union(Nothing, AbstractMemoryNode}\n\nIf there's a memory node in the Rete represented by root that stores objects of the specified type then return it.  Otherwise return nothing.\n\n\n\n\n\n","category":"method"},{"location":"#Rete.input_count-Tuple{AbstractReteNode}","page":"Home","title":"Rete.input_count","text":"input_count(node)\n\nreturns the number of inputs to the node.\n\nNote that for join nodes, this is the number of parameters rather than the number of nodes that emit facts to the join.\n\n\n\n\n\n","category":"method"},{"location":"#Rete.inputs","page":"Home","title":"Rete.inputs","text":"inputs(node)\n\nReturns the inputs of node – those nodes which can send it facts – as an iterable collection.\n\n\n\n\n\n","category":"function"},{"location":"#Rete.install-Union{Tuple{T}, Tuple{T, Type}} where T","page":"Home","title":"Rete.install","text":"install(root, rule::Type)\n\nInstalls the rule or rule group into the Rete rooted at root.\n\n\n\n\n\n","category":"method"},{"location":"#Rete.is_forward_trigger-Tuple{JoinNode, AbstractReteNode}","page":"Home","title":"Rete.is_forward_trigger","text":"is_forward_trigger(::JoinNode, from::AbstractReteNode)\n\nreturns true if from is a forward trigger input of the JoinNode.\n\n\n\n\n\n","category":"method"},{"location":"#Rete.is_memory_for_type-Tuple{IsaMemoryNode, Type}","page":"Home","title":"Rete.is_memory_for_type","text":"is_memory_for_type(node, typ::Type)::Bool\n\nreturns true if node stores objects of the specified type.\n\nUsed by find_memory_for_type.\n\n\n\n\n\n","category":"method"},{"location":"#Rete.kb_counts-Tuple{AbstractReteRootNode}","page":"Home","title":"Rete.kb_counts","text":"kb_counts(root::AbstractReteRootNode)\n\nReturns a Dict{Type, Int} of the number of facts of each type.\n\n\n\n\n\n","category":"method"},{"location":"#Rete.kb_stats-Tuple{Any, Any}","page":"Home","title":"Rete.kb_stats","text":"kb_stats(io, root)\n\nShow the input count, output count, fact count and label for each node.\n\n\n\n\n\n","category":"method"},{"location":"#Rete.label","page":"Home","title":"Rete.label","text":"label(node)\n\nReturns node's label.\n\n\n\n\n\n","category":"function"},{"location":"#Rete.output_count-Tuple{AbstractReteNode}","page":"Home","title":"Rete.output_count","text":"output_count(node)\n\nreturns the number of outputs from the node.\n\n\n\n\n\n","category":"method"},{"location":"#Rete.outputs","page":"Home","title":"Rete.outputs","text":"outputs(node)\n\nReturns the outputs of node – those nodes to which it can send facts – as an iterable collection.\n\n\n\n\n\n","category":"function"},{"location":"#Rete.receive","page":"Home","title":"Rete.receive","text":"receive(node, fact)\n\nreceive is how node is given a new fact.\n\nAn application calls receive on the root node to assert a new fact to the network.\n\n\n\n\n\n","category":"function"},{"location":"#Rete.walk_by_outputs-Tuple{Any, AbstractReteNode}","page":"Home","title":"Rete.walk_by_outputs","text":"walkbyoutputs(func, node::AbstractReteNode)\n\nWalks the network rooted at `root', applying func to each node.\n\n\n\n\n\n","category":"method"},{"location":"#Rete.@rule-Tuple{Any, Any}","page":"Home","title":"Rete.@rule","text":"@rule Rulename(a::A_Type, b::B_Type, ...) begin ... end\n\nDefines a rule named Rulename.  A singleton type named Rulename will be defined to represent the rule.  An install method is defined for that type which can be used to add the necessary nodes and connections to a Rete to implement the rule.\n\nThe default supertype of a rule struct is Rule.  When it is desirable to group rules together, one can define an abstract type that is a type descendant of Rule and use that as a dotted prefix to RuleName.  The RuleName in the @rule invocation is MyGroup.MyRule then the supertype of MyRule will be MyGroup, rather than Rule.\n\nA rule can have arbitrarily many parameters.  The parameter list can also include clauses with no variable name.  Such clauses identify the types of facts that the rule might assert.  Memory nodes for these types will be added to the Rete if not already present.  They will be added by the automatically generated install method.  See CUSTOM_INSTALL below.  There is no enforcement that all types that are emitted by the rule are listed here, but various introspective tools, as well as proper rule installation depend on this.\n\nThe body of the @rule expression implements the behavior of the rule.  It can perform any tests that are necessary to determine which, if any facts should be asserted.  This code is included in a function that has the same name as the rule itself.  This function is used as the join_function of the JoinNode that implements the rule.  The function declares a keyword argument named emit whose default value calls emit. For testing and debugging purposes, the rule function can be invoked from the Julia REPL, perhaps passing emit=println to try the rule function independent of the rest of the network.\n\nWithin the body, @reject, @rejectif and @continueif can be used.\n\n@reject will exit the rule body unconditionally and issue a debug log message.\n\nThe other two take a conditional expression.\n\n@rejectif will exit the rule body and log a message if the condition succeeds.\n\n@continueif will exit and log if the condition returns false.\n\nThe first expression of the rule can be a call-like expression of RULE_DECLARATIONS.  Its \"parameters\" can be declarations of one of the forms\n\nFORWARDTRIGGERS(argumentnames...)`\n\nOnly the inputs for the specified argument names will serve as forward triggers.  For backward compatibility, if there is no RULE_DECLARATIONS expression then all inputs are forward triggers.\n\nNote that if a RULE_DECLARATIONS clause is included then any forwarde triggers must be explicitly declared.\n\nCUSTOM_INSTALL()`\n\nNo install method will be automatically generated.  The developer must implement an install method for this rule.\n\n\n\n\n\n","category":"macro"}]
}
