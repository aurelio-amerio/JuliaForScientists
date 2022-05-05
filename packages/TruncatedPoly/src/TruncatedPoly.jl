module TruncatedPoly

export Series

struct Series{T,N}
    c::NTuple{N,T}
end

include("TPMath.jl")
include("TPFunctions.jl")

end # module
