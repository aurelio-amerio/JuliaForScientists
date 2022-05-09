using DataFrames

dict=Dict("a"=>Float64[1,2,3], "b"=>[2,3,4], "mask"=>[true, false, true])

df = DataFrame(dict)

names(df)

df[1,:]
df[2,"a"]

#you can use === to check if the memory address of two variables is th same

df[!,"a"] === df.a

df[:,"a"] === df.a

df[!, Not(:a)]

subset(df, :mask)

test = let 
    me="in"
end

using CSV

df_iris = let 
    df_dir = dirname(pathof(DataFrames))
    iris_file=joinpath(df_dir,"..","docs","src","assets","iris.csv")
    CSV.read(iris_file,DataFrame)
    
end


describe(df_iris)

df_grouped = groupby(df_iris, :Species)

using Statistics

cov_list = []

for df in df_grouped
    push!(cov_list, cov(Matrix(df[!,Not(:Species)])))
end

cov_list[2]

3 |> sin |> sin