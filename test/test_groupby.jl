module TestGroupBy
include("preamble.jl")
using Transducers: DefaultInit

@testset begin
    @test foldl(right, GroupBy(string, Map(last), push!!), [1, 2, 1, 2, 3]) ==
          Dict("1" => [1, 1], "2" => [2, 2], "3" => [3])

    @test foldl(
        right,
        GroupBy(identity, Map(last) |> Scan(+), (_, x) -> x > 3 ? reduced(x) : x, nothing),
        [1, 2, 1, 2, 3],
    ) == Dict(2 => 4, 1 => 2)
end

@testset "post-groupby filtering" begin
    d = foldl(right, GroupBy(isodd, Map(last) |> Filter(isodd), +), 1:10)
    @test d == Dict(true => 25)
    @test d.state == Dict(true => 25, false => DefaultInit(+))
    @test valtype(d) <: Int
    @test valtype(d.state) <: Union{Int,typeof(DefaultInit(+))}
end

@testset "automatic asmonoid" begin
    @test foldl(right, GroupBy(identity, Map(first), (a, b) -> a + b), [1, 2, 1, 2, 3]) ==
          Dict(1 => 2, 2 => 4, 3 => 3)

    @test foldl(right, GroupBy(identity, (_, x) -> x), [1, 2, 1, 2, 3]) ==
          Dict(1 => 1 => 1, 2 => 2 => 2, 3 => 3 => 3)
end

end  # module
