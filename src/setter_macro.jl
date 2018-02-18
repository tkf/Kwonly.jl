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
