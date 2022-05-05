using BenchmarkTools
using StaticArrays

typeof((1,2,3))
NTuple<:Tuple

f(x) = x^2

points=100
@benchmark ntuple($f,$points)

a=collect(1:10)
b=zeros(Int, length(a))

@benchmark $f.($a)

@benchmark map($f,$a)

@benchmark map!($f,$a,$b)

@benchmark $b .= $f.($a)

a=SVector{points,Int}(collect(1:points))
b= zeros(Int, length(a))

@benchmark $b .= $f.($a)

@benchmark $f.($a)

Type