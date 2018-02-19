# Reconstructables.jl --- Tools for easy "modification" of nested immutable structs

[![Build Status][travis-img]](travis-url)
[![Coverage Status][coveralls-img]](coveralls-url)
[![codecov.io][codecov-img]](codecov-url)


Reconstructables.jl provides helper functions and macros to work with
immutable structs in Julia.  For example, using `@recon` macro, you
can reconstruct a new struct where the nested field `.x.y.z` is
modified from the one in `old` by:

    new = @recon old.x.y.z = 3

It works even when `old`, `x` and `y` are all immutable, provided that
their constructor have keyword-only version (see below).


## Basic Usage

First tool Reconstructables.jl provides is `@add_kwonly`.  It creates
a keyword-only version of the given function.  Example:

```julia
using Reconstructables: @add_kwonly

struct A
    x
    y
    @add_kwonly A(x, y=2) = new(x, y)
end
```

This macro add keyword-only constructor by expands `A(x) = new(x)` into:

    A(x, y) = new(x, y)                                      # original
    A(; x = throw(UndefKeywordError(:x)), y=2) = new(x, y)   # keyword-only

That is to say, the struct `A` can be constructed only by keyword
arguments:

```julia
@test A(1) == A(x=1)
```

**[Important]** Note that the name of arguments of the constructor must
be exactly same as the name of struct fields for it to work with other
tools in Reconstructables.jl.

When struct constructor has keyword-only version, the struct can be
"modified" by `recon`:

```julia
using Reconstructables: recon

a1 = A(1)
a2 = recon(a1, x=2)
@test a2.x == 2
```

Here `recon(a1, x=2)` is equivalent to `A(x=2, y=a1.y)`.

`recon` is handy for shallow structs but it's hard to use when
modifying a nested field.  Macro `@recon` can be used in this case:

```julia
using Reconstructables: @recon

old = A(A(A(1)))
new = @recon old.x.x.x = 2
@test new.x.x.x == 2
```

Here, `@recon old.x.x.x = 2` is just a syntactic sugar of
`recon(old; x=recon(old.x; x=recon(old.x.x; x=2)))`.

Macro `@recon` also supports "batch update":

```julia
old = A(A(A(5), A(6, 7)))
new = @recon begin
    old.x.x.x = 10
    old.x.y.y = 20
end
@test new.x.x.x == 10
@test new.x.y.y == 20
@test new.x.y.x == old.x.y.x == 6
```

## How to use type parameters

Consider inner constructor with type parameter:

```julia
struct B{T, X, Y}
    x::X
    y::Y
    @add_kwonly B{T}(x::X, y::Y = 2) where {T, X, Y} = new{T, X, Y}(x, y)
end
```

This struct does not work well with `recon` because it does not know
how to fill the type parameter.  In this case, you need to extend
`Reconstructables.constructor_of` to map the type of the struct to
appropriate type with the keyword-only constructor.

```julia
import Reconstructables
Reconstructables.constructor_of(::Type{<: B{T}}) where T = B{T}
```

It tells `recon` to "drop" type parameters `X` and `Y`, but not `T`,
since otherwise the keyword-only constructor cannot be called.

```julia
b1 = B{true}(1)
b2 = recon(b1, x=2.0)
@test b2.x == 2.0
@test b2 isa B{true}
```

## Parameters.jl

[Parameters.jl](https://github.com/mauro3/Parameters.jl) provides a
very convenient way of defining keyword-only struct constructor.  The
structs created by `Parameters.@with_kw` work perfectly well with
`recon` and `@recon`:

```julia
using Parameters: @with_kw

@with_kw struct C
    a::A = A(0)
    b::B{false} = B{false}(1)
    x::Int = 6
end

c1 = C()
c2 = @recon c1.b.x = 2.0
@test c2.b.x == 2.0
```


[travis-img]: https://travis-ci.org/tkf/Reconstructables.jl.svg?branch=master
[travis-url]: https://travis-ci.org/tkf/Reconstructables.jl
[coveralls-img]: https://coveralls.io/repos/tkf/Reconstructables.jl/badge.svg?branch=master&service=github
[coveralls-url]: https://coveralls.io/github/tkf/Reconstructables.jl?branch=master
[codecov-img]: http://codecov.io/github/tkf/Reconstructables.jl/coverage.svg?branch=master
[codecov-url]: http://codecov.io/github/tkf/Reconstructables.jl?branch=master
