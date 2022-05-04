using MixedUtils
using Test

@testset "JuliaForScientists" begin
    f(x) = x^2-4
    f1(x) = 2*x
    @test isapprox(newton(f, 3.0),2.0)
    @test isapprox(newton(f, f1, 3.0),2.0)
end
