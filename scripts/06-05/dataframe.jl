using DataFrames

dict=Dict("a"=>Float64[1,2,3], "b"=>[2,3,4])

df = DataFrame(dict)

names(df)

df[1,:]
df[2,"a"]

#you can use === to check if the memory address of two variables is th same

df[!,"a"] === df.a

df[:,"a"] === df.a

df[!, Not(:a)]