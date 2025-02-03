module Rete

using InteractiveUtils

include("node_abstraction.jl")
include("sets_as_inputs_and_outputs.jl")
include("root_nodes.jl")
include("memory_nodes.jl")
include("join_nodes.jl")
include("backward.jl")
include("parsed_rules.jl")
include("rules.jl")
include("aggregation.jl")
include("utils.jl")

end
