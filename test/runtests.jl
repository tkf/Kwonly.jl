using Base.Test

@testset "$file" for file in [
        "test_add_kwonly.jl",
        "test_reconstructor.jl",
        "test_setter_macro.jl",
        ]
    @time include(file)
end
