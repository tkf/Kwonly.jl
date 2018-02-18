if VERSION < v"0.7-"
    # dummy type to be ignored in 0.6
    struct LineNumberNode end
end


"""
    @recon assignment_expr

A helper macro for reconstructing nested immutable struct.

For example,
    new = @recon old.a.b.c = 1
is converted into
    new = recon(old; a=recon(old.a; b=recon(old.a.b; c=1)))
"""
macro recon(ex)
    esc(recon_impl(ex))
end

recon_impl(ex::Expr) = recon_impl(Val{ex.head}, ex)
recon_impl(::Type{Val{:(=)}}, ex) = assign(ex.args...)

assign(ex::Expr, args...) = assign(Val{ex.head}, ex, args...)
function assign(::Type{Val{:.}}, lhs::Expr, rhs)
    # lhs = old.a.b.c
    # rhs = 1
    # inner = recon(old.a.b; c=1)
    inner = :($recon($(lhs.args[1]); $(assymbol(lhs.args[2])) = $rhs))
    return assign(lhs.args[1], inner)
end
assign(::Symbol, rhs) = rhs
assign(::Type{<: Val}, lhs::Expr, _) = error("Unsupported expression: $lhs")

assymbol(x::Symbol) = x
assymbol(x::QuoteNode) = x.value
assymbol(x::Expr) = assymbol(Val{x.head}, x)
function assymbol(::Type{Val{:quote}}, x::Expr)
    @assert length(x.args) == 1
    return assymbol(x.args[1])
end

statements(ex::Expr) = statements(Val{ex.head}, ex)
statements(::Type{Val{:block}}, ex) = vcat(map(statements, ex.args)...)
statements(::Type{Val{:line}}, _) = Expr[]
statements(::LineNumberNode) = Expr[]
statements(::Type{<: Val}, ex) = [ex]
statements(ex) = ex

function recon_impl(::Type{Val{:block}}, ex)
    args = statements(ex)
    if ! all(a.head == :(=) && length(a.args) == 2 for a in args)
        error("All statements in a block must be assignments. Given:\n",
              "$ex")
    end
    # ex = quote
    #     old.x.x.x = 10
    #     old.x.y.y = 20
    # end
    vlhs = [a.args[1] for a in args]
    vrhs = [a.args[2] for a in args]
    return vassign(vlhs, vrhs)
end

ndots(ex::Expr) = ndots(Val{ex.head}, ex)
ndots(::Type{Val{:.}}, ex) = 1 + ndots(ex.args[1])
ndots(::Symbol) = 0

function vassign(vlhs::Vector, vrhs::Vector)
    maxdots = maximum(map(ndots, vlhs))
    if maxdots == 0
        if length(vlhs) > 1
            error("Trying to modify multiple structs: $vlhs")
        end
        @assert length(vlhs) == length(vrhs) == 1
        # vlhs = [:old]
        # vrhs = [:(recon(old; x=recon(old.x; ...)))]
        return vrhs[1]
    end

    # vlhs = [:(old.x.x.x), :(old.x.y.y)]
    # vrhs = [10, 20]
    # inner = recon(old.a.b; c=1)
    inners = Dict()
    next_vlhs = []
    next_vrhs = []
    for (lhs, rhs) in zip(vlhs, vrhs)
        if ndots(lhs) == maxdots
            kwargs = get!(inners, lhs.args[1]) do
                []
            end
            push!(kwargs, assymbol(lhs.args[2]) => rhs)
        else
            push!(next_vlhs, lhs)
            push!(next_vrhs, rhs)
        end
    end
    for (lhs, kwargs) in inners
        push!(next_vlhs, lhs)
        push!(next_vrhs, Expr(:call, recon, Expr(:parameters, (
            Expr(:kw, k, w) for (k, w) in kwargs
        )...), lhs))
        # next_vrhs[end] contains "recon(lhs; kwargs...)"
    end
    return vassign(next_vlhs, next_vrhs)
end
