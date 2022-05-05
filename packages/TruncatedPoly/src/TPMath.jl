#%%
import Base: +, -, *, /


Base.:+(s1::Series{T,N}) where {T,N} = s1
Base.:+(s1::Series{T,N},s2::Series{T,N}) where {T,N} = Series{T,N}(ntuple(i -> s1.c[i]+s2.c[i],N))
#%%

f(x::T) where {T<:Real} = x^2

f(x::Vector{T}) where {T<:Real}

f(x<:Vector{Real})