export Aggregator, Counter, Collector


"""
Aggergator is the abstract supertype for all query aggregators.
"""
abstract type Aggregator end

function (a::Aggregator)(continuation)
    continuation(x -> aggregate(a, x))
    value(a)
end

function askc(a::Aggregator, source)
    askc(x -> aggregate(a, x), source)
    value(a)
end

function askc(a::Aggregator, kb::ReteRootNode, t::Type)
    askc(x -> aggregate(a, x), kb, t)
    value(a)
end


"""
    Counter()

returns an Aggregator that can be passed as the "continuation"
function of `askc` so that `askc` will return the number of objects
that it found.
"""
mutable struct Counter <: Aggregator
    count::Int

    Counter() = new(0)
end

value(a::Counter) = a.count

function aggregate(a::Counter, fact)
    a.count += 1
end


"""
    Collector{T}()

returns an Aggregator that can be passed as the "continuation"
function of `askc` so that `askc` will return a vector of the objects
that it found.
"""
struct Collector{T} <: Aggregator
    collection::Vector{T}

    Collector{T}() where T = new{T}(Vector{T}())
end

value(a::Collector) = a.collection

function aggregate(a::Collector, thing)
    push!(a.collection, thing)
end

# We can infer the query type from the Collector:
function askc(a::Collector{T}, kb::ReteRootNode) where T
    askc(x -> aggregate(a, x), kb, T)
    value(a)
end

