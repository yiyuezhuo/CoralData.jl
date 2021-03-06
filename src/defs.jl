
const mi = 1.852 # 1 nautical miles = 1.852km
const p = 1/60 # 1°=60′=3600′′   
const pp = 1/3600 # 1 == 60p == 3600pp

# We will use something like `300mi` to match literature.
# Note in Naval Battle literature, `mi` denote nautical mile instead of mile.

struct SpatPos
    longitude::Float64 # longitude
    latitude::Float64 # latitude
end

#=

# Representing lazy computing data structure explicitly requires extra complexity, 
# we would rather just use `(forward_deg, get_pos) -> ...`.

"""
    struct ForwardDeg

Denote a location which is relative to another location. 
Delegate the `forward_deg` calculation to other package.
"""
struct ForwardDeg
    longitude::Float64 # longitude
    latitude::Float64 # latitude
    degree::Float64
    distance::Float64
end

"""
    struct GetPos

A "lazy" symbol denoting `get_pos` in `CoralTools`, or leave space to leverage varying implementations.
"""
struct GetPos
    target::String
    time::DateTime
end
=#

# https://www.reddit.com/r/Julia/comments/cipz46/broadcasting_with_a_custom_struct/
Base.broadcastable(sp::SpatPos) = Ref(sp)

abstract type AbstractSearchPlan end

struct SectorSearchPlan <: AbstractSearchPlan
	base::SpatPos
	bearing::Tuple{Float64, Float64}
	distance::Float64
	num::Int # number of used planes
end

Base.convert(::Type{SectorSearchPlan}, t::Tuple) = SectorSearchPlan(t...)

function Base.getindex(ssp::SectorSearchPlan, idx_vec::AbstractVector)
    # support ssp[1:3] style "indexing"
    left, right = ssp.bearing
    if right < left
        right += 360
    end
    h = (right - left) / ssp.num
    min_idx = minimum(idx_vec)
    max_idx = maximum(idx_vec)
    left_new = (left + (min_idx - 1) * h) % 360
    right_new = (left + max_idx * h) % 360
    return SectorSearchPlan(ssp.base, (left_new, right_new), ssp.distance, max_idx - min_idx + 1)
end

struct CounterClockwise end # trait

function Base.getindex(ssp::SectorSearchPlan, ::CounterClockwise, idx_vec::AbstractVector)
    idx_vec_trans = reverse(ssp.num .- (idx_vec .- 1))
    return ssp[idx_vec_trans]
end

function set_distance(ssp::SectorSearchPlan, distance)
    return SectorSearchPlan(ssp.base, ssp.bearing, distance, ssp.num)
end

# We may add a specific struct for early Noumean's parallel plan

# Helper

CT(day, hour, min) = DateTime(1942, 5, day, hour, min, 0) # The battle of coral sea related time
CT(t::Tuple) = CT(t...)

struct SpatTempPos
    longitude::Float64 # longitude
    latitude::Float64 # latitude
    time::DateTime # time stamp
    has_time::Bool
end

SpatTempPos(longtitude, latitude, time::DateTime) = SpatTempPos(longtitude, latitude, time, true)
# SpatTempPos(longtitude, latitude, time) = SpatTempPos(longtitude, latitude, CT(time))
SpatTempPos(longtitude, latitude) = SpatTempPos(longtitude, latitude, DateTime(0), false)
SpatTempPos(t::T) where T <: Tuple = SpatTempPos(t...)

Base.convert(::Type{SpatTempPos}, t::Tuple) = SpatTempPos(t...)

SpatPos(stp::SpatTempPos) = SpatPos(stp.longitude, stp.latitude)

# Action state

abstract type Action end

struct MoveTo{TP, TT} <: Action
    pos::TP # SpatPos or String
    time::TT # DateTime or Nothing
end

MoveTo(pos) = MoveTo(pos, nothing)
MoveTo(pos::Tuple, time) = MoveTo(SpatPos(pos[1], pos[2]), time) # (longitude, latitude) -> SpatPos

struct TurnAngleTo <: Action
    angle::Float64
end

struct TurnAngle <: Action
    angle::Float64
end

struct MoveForward{TT} <: Action
    distance::Float64
    time::TT
end

MoveForward(distance) = MoveForward{Nothing}(distance, nothing)

struct RelPos{T <: Union{SpatPos, String}}
    base::T
    angle::Float64
    dist::Float64
end

RelPos(base, angle, dist) = RelPos(base, Float64(angle), Float64(dist))

struct ContactReport{T <: Union{SpatPos, RelPos, Missing}}
    cancelled_plan::Tuple{String, Int}
    time_recv::DateTime
    time_begin::DateTime
    time_end::DateTime
    pos::T
    angle::Float64 # degree
    speed::Float64 # km / hour
end

function ContactReport(cancelled_plan, time_recv, time_begin, time_end, pos, angle, speed)
    return ContactReport(cancelled_plan, time_recv, time_begin, time_end, pos, Float64(angle), Float64(speed))
end

function ContactReport(cancelled_plan, time_recv, time_begin, time_end, pos)
    return ContactReport(cancelled_plan, time_recv, time_begin, time_end, pos, 0, 0)
end

function ContactReport(cancelled_plan, time_recv, time_begin, time_end)
    return ContactReport(cancelled_plan, time_recv, time_begin, time_end, missing)
end

# ContactReport(t::Tuple) = ContactReport(t...)
Base.convert(::Type{ContactReport}, t::Tuple) = ContactReport(t...)
