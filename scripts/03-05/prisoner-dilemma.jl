#%%
struct PlayResult
    me::Bool
    other::Bool
    payoff::Int
end

import Base.show

function Base.show(io::IO, res::PlayResult)
    println(io, "Me $(res.me)")
    println(io, "Other $(res.other)")
    println(io, "Payoff $(res.payoff)")
    return
end

#%%
