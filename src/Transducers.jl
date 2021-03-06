module Transducers

export Transducer, Map, Filter, Cat, MapCat, TCat, Take, PartitionBy, Scan, Zip,
    Replace, TakeWhile, TakeNth, Drop, DropLast, DropWhile, Keep, Unique,
    Interpose, Dedupe, Partition, Iterated, Count, GroupBy, ReduceIf,
    TakeLast, FlagFirst, MapSplat, ScanEmit, Enumerate, NotA, OfType,
    transduce, eduction, setinput, Reduced, reduced, unreduced, ifunreduced,
    Completing, OnInit, CopyInit, right, reducingfunction, dreduce, dtransduce,
    tcopy, tcollect, dcopy, dcollect, channel_unordered, withprogress,
    AdHocFoldable, TeeRF, ProductRF, Broadcasting

# Deprecated:
export Distinct

using Base.Broadcast: Broadcasted

import Tables
using ArgCheck
using BangBang.Experimental: modify!!, mergewith!!
using BangBang.NoBang: SingletonVector
using BangBang:
    @!, BangBang, Empty, append!!, collector, empty!!, finish!, push!!, setindex!!, union!!
using Distributed: Distributed, @everywhere
using Logging: LogLevel, @logmsg
using Requires
using InitialValues:
    GenericInitialValue,
    Init,
    InitialValue,
    InitialValues,
    SpecificInitialValue,
    asmonoid,
    hasinitialvalue
using SplittablesBase: SplittablesBase, amount, halve

import Setfield
using Setfield: @lens, @set, set

# Dummy `ConstructionBase` module for supporting older `Setfield`:
module ConstructionBase
    using Setfield
    @static if isdefined(Setfield, :constructorof)
        const constructorof = Setfield.constructorof
    else
        const constructorof = Setfield.constructor_of
    end
end

@static if VERSION >= v"1.3-alpha"
    using Base.Threads: @spawn
    function nonsticky!(task)
        task.sticky = false
        return task
    end
else
    # Mock `@spawn` using `@async`:
    @eval const $(Symbol("@spawn")) = $(Symbol("@async"))
    nonsticky!(task) = task
end

# `AbstractArrayOrBroadcasted` is an internal detail of `Base`.  But
# we need this exact type for disambiguation...
if isdefined(Base, :AbstractArrayOrBroadcasted)
    const AbstractArrayOrBroadcasted = Base.AbstractArrayOrBroadcasted
else
    const AbstractArrayOrBroadcasted = Union{AbstractArray, Broadcasted}
end

# Some upstream APIs that are frequently used with Transducers.jl.
# From BangBang.jl:
export Empty, append!!, push!!
# From InitialValue.jl:
export Init

include("AutoObjectsReStacker.jl")
using .AutoObjectsReStacker: restack

include("showutils.jl")
include("basics.jl")
include("core.jl")
include("library.jl")
include("teezip.jl")
include("groupby.jl")
include("broadcasting.jl")
include("combinators.jl")
include("simd.jl")
include("processes.jl")
include("reduce.jl")
include("dreduce.jl")
include("unordered.jl")
include("air.jl")
include("lister.jl")
include("show.jl")
include("comprehensions.jl")
include("progress.jl")
include("deprecated.jl")

include("interop/blockarrays.jl")
include("interop/lazyarrays.jl")

function __init__()
    @require BlockArrays="8e7c35d0-a365-5155-bbbb-fb81a777f24e" begin
        __foldl__(rf, acc, coll::BlockArrays.BlockArray) =
            _foldl_blockarray(rf, acc, coll)
    end
    @require LazyArrays="5078a376-72f3-5289-bfd5-ec5146d43c02" begin
        __foldl__(rf, acc, coll::LazyArrays.Hcat) =
            _foldl_lazy_hcat(rf, acc, coll)
        __foldl__(rf, acc, coll::LazyArrays.Vcat) =
            _foldl_lazy_vcat(rf, acc, coll)
    end
    @require OnlineStatsBase="925886fa-5bf2-5e8e-b522-a9147a512338" begin
        include("interop/onlinestats.jl")
    end
    @require DataFrames="a93c6f00-e57d-5684-b7b6-d8193f3e46c0" begin
        include("interop/dataframes.jl")
    end
end

end # module
