
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

