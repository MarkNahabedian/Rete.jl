cd(@__DIR__)
using Pkg
Pkg.activate(".")

using Rete
using Documenter

DocMeta.setdocmeta!(Rete, :DocTestSetup, :(using Rete); recursive=true)

makedocs(;
    modules=[Rete],
    authors="MarkNahabedian <naha@mit.edu> and contributors",
    repo="https://github.com/MarkNahabedian/Rete.jl/blob/{commit}{path}#{line}",
    sitename="Rete.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://MarkNahabedian.github.io/Rete.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/MarkNahabedian/Rete.jl",
    devbranch="main",
)
