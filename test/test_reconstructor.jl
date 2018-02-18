module TestReconstructor
try
    using Test
catch
    using Base.Test
end
using Reconstructables: @add_kwonly, recon, constructor_of, statements

@test constructor_of(Vector) == Array
@test constructor_of([0]) == Array

struct A
    x
    @add_kwonly A(x) = new(x)
end
a1 = A(1)
a2 = recon(a1, x=2)
@test a2.x == 2


""" List of calls inferable by Julia 0.6. """
inferable_by_v06 = statements(quote
    A(1)
end)

""" List of calls *not* inferable by Julia 0.6 but (hopefully) in ≥ 0.7. """
non_inferable_by_v06 = statements(quote
    A(x=1)
    recon(a2, x=2)
end)

for (broken, expressions) in [(false, inferable_by_v06),
                              (true, non_inferable_by_v06)]
    for call in expressions
        # At the moment, it is broken even in 0.7:
        if broken  # && VERSION < v"0.7-"
            @eval @test_broken begin
                @inferred $call
                true
            end
        else
            @eval @test begin
                @inferred $call
                true
            end
        end
    end
end

end
