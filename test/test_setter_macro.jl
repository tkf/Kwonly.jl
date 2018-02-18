module TestSetterMacro
using Base.Test
using Reconstructables: @add_kwonly, @recon

struct A
    x
    @add_kwonly A(x) = new(x)
end

old = A(A(A(1)))
new = @recon old.x.x.x = 2
@test new.x.x.x == 2

struct B
    x
    y
    @add_kwonly B(x, y=nothing) = new(x, y)
end

old = B(B(B(1), B(2, 3)))
new = @recon begin
    old.x.x.x = 10
    old.x.y.y = 20
end
@test new.x.x.x == 10
@test new.x.y.y == 20

__not_implemented__ = """
old = B(B(B(1), B(2, 3)))
new = @recon let f = old.x.x,
                 g = old.x.y
    f.x = 10
    g.y = 20
end
@test new.x.x.x == 10
@test new.x.y.y == 20
"""
end
