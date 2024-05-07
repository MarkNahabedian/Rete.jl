
export counting, collecting, kb_counts


"""
    counting(body)

Runs `body`, passing it a continuation of one argument (which is
ignored), that counts the number of times the continuation is called.
One `body` is fnished, `counting` returns that count.
"""
function counting(body)
    count = 0
    function counter(_)
        count += 1
    end
    body(counter)
    count
end


"""
    collecting(body)

runs `body`, passing it a continuation of one argument that collects the
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
    kb_counts(root::ReteRootNode)

Returns a `Dict{Type, Int}` of the number of facts of each type.
"""
function kb_counts(root::ReteRootNode)
    result = Dict{Type, Int}()
    function walk(node)
        if node isa IsaMemoryNode
            result[typeof(node).parameters[1]] = length(node.memory)
        end
        for o in node.outputs
            if o !== root
                walk(o)
            end
        end
    end
    walk(root)
    result
end

