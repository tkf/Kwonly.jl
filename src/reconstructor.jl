constructor_of(::T) where T = constructor_of(T)
constructor_of(T::Type) = getfield(T.name.module, Symbol(T.name.name))
constructor_of(T::UnionAll) = constructor_of(T.body)

struct_as_dict(st) = [(n => getfield(st, n)) for n in fieldnames(typeof(st))]

"""
    recon(thing; <keyword arguments>)

Re-construct `thing` with new field values specified by the keyword
arguments.
"""
function recon(thing; kwargs...)
    constructor = constructor_of(thing)
    return constructor(; struct_as_dict(thing)..., kwargs...)
end
