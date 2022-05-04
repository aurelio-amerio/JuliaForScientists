using StaticArrays

a = [1,2,3]

isbits(a)

b = SVector{3}(a)

isbits(a)

c = (1,2,3)

isbits(c)

b

#%%
mutable struct Person{T<:Real}
    name::String
    height::T
    age::Int
    data::T
    # inner constructor
    Person{T}(name,height,age) where {T<:Real} = new(name, height,age,height*age)

end

# outer constructor
Person(name,height::T,age) where {T<:Real} = Person{T}(name, height, age)

struct Point{T<:Real}
    x::T
    y::T
    Point{T}(x,y) where {T<:Real} = new(x,y)
end
#%%
point = Point{Int64}(1,2)

p1=Person("Aure",164,26)