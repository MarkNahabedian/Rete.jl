
using DataStructures: SortedDict

export collecting

"""
    collecting(body)

runs body, passing it a continuation of one argument that collects the
values it's called with. `collecting` returns those values.
"""
function collecting(body)
    results = []
    function collect(thing)
        push!(results, thing)
    end
    body(collect)
    results
end


"""
    kb_counts(root)

Returns a `Dict{Type, Int}` of the number of facts of each type.
"""
function kb_counts(root)
    result = SortedDict{Type, Int}()
    for node in root.outputs
        @assert node isa IsaMemoryNode
        result[typeof(node).parameters[1]] = length(node.memory)
    end
    result
end

