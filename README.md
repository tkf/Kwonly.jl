# Reconstructables.jl --- helper macros for nested immutable structs

[![Build Status](https://travis-ci.org/tkf/Reconstructables.jl.svg?branch=master)](https://travis-ci.org/tkf/Reconstructables.jl)

[![Coverage Status](https://coveralls.io/repos/tkf/Reconstructables.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/tkf/Reconstructables.jl?branch=master)

[![codecov.io](http://codecov.io/github/tkf/Reconstructables.jl/coverage.svg?branch=master)](http://codecov.io/github/tkf/Reconstructables.jl?branch=master)


Reconstructables.jl provides helper macros to work with immutable
structs in Julia.  For example, using `@recon` macro, you can
reconstruct a new struct where the nested field `.x.y.z` is modified
from the one in `old`:

    new = @recon old.x.y.z = 3

It works even when `old`, `x` and `y` are all immutable, provided that
their constructor have keyword-only version (see below).


## Usage

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

    A(x, y) = new(x, y)                                # original
    A(; x = error("No argument x"), y=2) = new(x, y)   # keyword-only

That is to say, the struct `A` can be constructed only by keyword
arguments:

```julia
@test A(1) == A(x=1)
```

**Important** Note that the name of arguments of the constructor must
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

Macro `@recon` also supports "batch update":

```julia
old = A(A(A(1), A(2, 3)))
new = @recon begin
    old.x.x.x = 10
    old.x.y.y = 20
end
@test new.x.x.x == 10
@test new.x.y.y == 20
```
