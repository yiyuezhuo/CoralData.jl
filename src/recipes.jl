
@recipe function plot_stp_map(fleet_stp_map::Dict{String, Vector{SpatTempPos}})
    for (fleet_name, stp_vec) in fleet_stp_map
        @series begin
            longitude = map(p -> p.longitude, stp_vec)
            latitude = map(p -> p.latitude, stp_vec)
            label --> fleet_name
            (longitude, latitude)
        end
    end
end

@recipe function plot_sp_map(loc_map::Dict{String, SpatPos}; font=nothing)
    keys_loc_map = Vector{String}(undef, length(loc_map))
    longitude_vec = Vector{Float64}(undef, length(loc_map))
    latitude_vec = Vector{Float64}(undef, length(loc_map))
    for (idx, (name, sp)) in enumerate(loc_map)
        keys_loc_map[idx] = name
        longitude_vec[idx] = sp.longitude
        latitude_vec[idx] = sp.latitude
    end

    seriestype --> :scatter # hack to show text only
    series_annotations := (keys_loc_map, font)
    label --> false
    # seriesalpha --> 0
    (longitude_vec, latitude_vec)
end

@recipe function plot_sp(sp::SpatPos)#; markersize=2)
    seriestype --> :scatter
    # markersize --> markersize
    [sp.longitude], [sp.latitude]
end

@recipe function plot_sp_name(sp::SpatPos, name::String; font=nothing)#, markersize=2)
    seriestype --> :scatter
    # markersize --> markersize
    label --> false
    series_annotations := ([name], font)
    [sp.longitude], [sp.latitude]
end

@recipe function plot_sp_vec(sp_vec::Vector{SpatPos}; add_scatter=true)
    longitude_vec = Vector{Float64}(undef, length(sp_vec))
    latitude_vec = Vector{Float64}(undef, length(sp_vec))
    for i in eachindex(sp_vec)
        longitude_vec[i] = sp_vec[i].longitude
        latitude_vec[i] = sp_vec[i].latitude
    end
    @series begin
        longitude_vec, latitude_vec
    end
    if add_scatter
        @series begin
            seriestype --> :scatter
            longitude_vec, latitude_vec
        end
    end
end
