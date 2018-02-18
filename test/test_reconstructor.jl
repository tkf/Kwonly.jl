module TestReconstructor
using Base.Test
using Reconstructables: @add_kwonly, recon, constructor_of

@test constructor_of(Vector) == Array
@test constructor_of([0]) == Array

struct A
    x
    @add_kwonly A(x) = new(x)
end
a1 = A(1)
a2 = recon(a1, x=2)
@test a2.x == 2
end
