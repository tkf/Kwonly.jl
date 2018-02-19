module TestAddKwonly
try
    using Test
catch
    using Base.Test
end
using Reconstructables: @add_kwonly, UndefKeywordError

@add_kwonly function f(a, b; c=3, d=4)
  (a, b, c, d)
end
@test f(1, 2) == (1, 2, 3, 4)
@test f(a=1, b=2) == (1, 2, 3, 4)
@test_throws UndefKeywordError f()

@add_kwonly g(a, b; c=3, d=4) = (a, b, c, d)
@test g(1, 2) == (1, 2, 3, 4)
@test g(a=1, b=2) == (1, 2, 3, 4)

@add_kwonly h(; c=3, d=4) = (c, d)
@test h() == (3, 4)

@add_kwonly with_kwargs(a; b=2, kwargs...) =
    (a, b, Any[(k, v) for (k, v) in kwargs])
@test with_kwargs(a=10, x=20) == (10, 2, Any[(:x, 20)])


not_LoadError(x::LoadError) = x.error
not_LoadError(x) = x

macro test_error(testee, tester)
    quote
        ($(esc(tester)))(
            try
                $(esc(testee))
            catch err
               $not_LoadError(err)
            end)
    end
end

@test_error begin
    @eval @add_kwonly i(c=3, d=4) = (c, d)
end (err) -> begin
    @test err isa ErrorException
    @test contains(err.msg,
                   "At least one positional mandatory argument is required")
end

@test_error begin
    @eval @add_kwonly if false
        g(a, b; c=3, d=4) = (a, b, c, d)
    end
end (err) -> begin
    @test err isa ErrorException
    @test contains(err.msg,
                   "add_only does not work with expression if")
end

end
