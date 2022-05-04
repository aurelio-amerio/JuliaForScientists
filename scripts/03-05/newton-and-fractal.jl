# Newton's method and multiple dispatch
#%%
using PyPlot
using ForwardDiff
using ProgressMeter
#%%
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
    # error("We failed to reach a solution within $maxiter iterations. Try increasing `maxiter`")
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
    # error("We failed to reach a solution within $maxiter iterations. Try increasing `maxiter`")
    return NaN
end
#%%
f(x) = x^2 - 4
f1(x) = 2*x
#%%
newton(f,f1,3)
newton(f,-4)
print("done")
#%%
g(x) = cos(x)-x
newton.([f,g],1)
#%%
h(x)=x^3 -2*x +2
h1(x)=3*x^2 -2
#%%
newton(h,h1, 5+2im, maxiter=10000)
# the newton method has a problem with cycles, you need to pay attention to the initial guess x0
# %%
newton(f,f1,2+5im)
#%%
points=1000
xr = collect(range(-2,2, length=points))
xi = collect(range(-2,2, length=points)).*1im
#%%
res = zeros(ComplexF64,(points,points))
#%%
nf(x) = (x-1)^7
nf1(x) = 7*(x-1)^6
#%%
@showprogress for j in 1:points
    for i in 1:points
        res[i,j]=newton(h,h1,xr[i]+xi[j])
    end
end
#%%
rounded_mat = round.(res,digits=3)
concrete_mat = real.(rounded_mat)+imag.(rounded_mat)
label_mat = zeros(Int, size(rounded_mat))
labels=unique(concrete_mat)
for (i,label) in enumerate(labels)
    label_mat[abs.(concrete_mat.-label).<1e-3].=i
end
#%%
clf()
plt.imshow(label_mat, cmap="magma")
plt.show()
gcf()
#%%