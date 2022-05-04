# Newton's method and multiple dispatch
#%%
using ForwardDiff
#%%
"""
    update(f::Function, f1::Function, x0::Number)
  
The description    
"""
function update(f::Function, f1::Function, x0::Number)
    return x0 - f(x0)/f1(x0)
end

function update(f::Function, x0)
    return x0 - f(x0)/ForwardDiff.derivative(f, x0::Number)
end

function newton(f::Function, f1::Function, x0::Number; rtol::Float64=1e-6, maxiter::Int=1000)
    x1 = x0
    diff=0.0
    for _ in 1:maxiter 
        x1 = update(f,f1,x0)
        diff = abs((x1-x0)/(x0+eps(Float64)))
        if diff <= rtol
            return x1
        else
            x0=x1
        end
    end
    @error "We failed to reach a solution within $maxiter iterations. Try increasing `maxiter`"
    return NaN
end

function newton(f::Function, x0::Number; rtol::Float64=1e-6, maxiter::Int=1000)
    x1 = x0
    diff=0.0
    for _ in 1:maxiter 
        x1 = update(f,x0)
        diff = abs((x1-x0)/(x0+eps(Float64)))
        if diff <= rtol
            return x1
        else
            x0=x1
        end
    end
    @error "We failed to reach a solution within $maxiter iterations. Try increasing `maxiter`"
    return NaN
end