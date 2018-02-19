module TestSetterMacro
try
    using Test
catch
    using Base.Test
end
using Reconstructables: @add_kwonly, @recon, statements
include("utils.jl")

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

new = @recon begin
    old.x.x.x = 10
    old.x.x.y = 20
    old.x.y = 30
    old.y = 40
end
@test new.x.x.x == 10
@test new.x.x.y == 20
@test new.x.y == 30
@test new.y == 40

f(x) = 2x

new = @recon begin
    old.x.x.x = f(old.x.x.x)
    old.x.x.y = 1 * 20
    old.x.y.x = let x = old.x.y.x
        10x
    end
end
@test old.x.x.x == 1
@test new.x.x.x == 2
@test new.x.x.y == 20
@test old.x.y.x == 2
@test new.x.y.x == 20

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

invalid_expression_list = statements(quote
    old{:spam}.x.x.x = 10
    old.x{:spam}.x.x = 10
    old.x.x.x{:spam} = 10
end)
append!(invalid_expression_list,
        map(ex -> quote $ex end, invalid_expression_list))

for ex in invalid_expression_list
    @test_error begin
        @eval @recon $ex
    end (err) -> begin
        @test err isa ErrorException
        @test contains(err.msg, "Unsupported expression:")
    end
end

end
