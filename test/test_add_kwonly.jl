module TestAddKwonly
using Base.Test
using Reconstructables: @add_kwonly, add_kwonly, UndefKeywordError

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

@test_throws ErrorException add_kwonly(:(i(c=3, d=4) = (c, d)))
end
