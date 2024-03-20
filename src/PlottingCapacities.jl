module PlottingCapacities

export read_file, plot_capacity, plot_table, plot_CapacityTable, plot_supplycurve, plot_supplycurves, WindPotential, demand

using Plots, DataFrames, HDF5, XLSX, CSV, JLD

function read_file(dataname_modifier)
    datapath = "C:\\Users\\carin\\Documents\\Thesis\\Code\\GISdata\\output"
    dataname_root = "\\GISdata_wind2018_"
    datatype = ".mat"
    total_datapath  = datapath*dataname_root*dataname_modifier*datatype
    windvars = h5open(total_datapath,"r")
    #cf_wind_a = read(windvars,"CFtime_windonshoreA");
    #cf_wind_b = read(windvars,"CFtime_windonshoreB");
    #cf_wind_off = read(windvars,"CFtime_windoffshore");
    capacity_wind_a = read(windvars,"capacity_onshoreA");
    capacity_wind_b = read(windvars,"capacity_onshoreB");
    #capacity_wind_off = read(windvars,"capacity_offshore");
    #Normal arrays with hours x regions x resource classes
    sumdrop(x; dims=dims) = dropdims(sum(x, dims=dims), dims=dims)
    capacity_a = sumdrop(capacity_wind_a, dims=1)
    capacity_b = sumdrop(capacity_wind_b, dims=1)
    #capacity_off = sumdrop(capacity_wind_off, dims=1)
    capacities_wind = DataFrame()
    capacities_wind.Class_A = capacity_a
    capacities_wind.Class_B = capacity_b
    #capacities_wind.Offshore = capacity_off
    #Sums up the capacity for all the regions
    return capacities_wind
end

function plot_capacity(capacities_wind,region,suffix;savetodisk=false)
    x = string.(Int.(LinRange(0,100,(nrow(capacities_wind)+1))))[2:end] .* " %" #of land"
    p1 = bar(x,capacities_wind.Class_A,legend=false,bar_width=1)
    xlabel!("Class A")
    ylabel!("Capacity [GW]")
    p2 = bar(x,capacities_wind.Class_B,legend=false,bar_width=1)
    xlabel!("Class B")
    ylabel!("Capacity [GW]")
    plot(p1, p2, layout=(2,1), legend=false,plot_title="Capacity for $(region)")
    plot!(size=(700,500))
    if savetodisk
        figurepath = "C:\\Users\\carin\\Documents\\Thesis\\Code\\Plots\\Capacities";
        filename = region*suffix;
        savefig("$(figurepath)\\$(filename).png") 
    end
end

function plot_table(reference,region,suffix,values,class;savetodisk=false)
    df = DataFrame()
    df[!,"Area"] = string.(10:10:100) .* " %" 
    for value in values
        capacities_wind = read_file(region*suffix*value)
        if class == "A"
            wind = capacities_wind.Class_A
            ref_wind = reference.Class_A
        elseif class == "B"
            wind = capacities_wind.Class_B
            ref_wind = reference.Class_B
        else
            print("That is not a valid wind class")
            return nothing
        end
        df[!,value*" (%)"] = string.(round.(((wind .- ref_wind) ./ ref_wind)*100,digits=1))
    end
    if savetodisk
        tablepath = "C:\\Users\\carin\\Documents\\Thesis\\Code\\Tables";
        filename = suffix[2:end]*class
        path = "$(tablepath)\\$(filename).xlsx"
        XLSX.openxlsx(path,mode="rw") do xf
            XLSX.addsheet!(xf,region)
            sheet = xf[region]
            c=1
            for name in names(df)
                sheet[XLSX.CellRef(1 , c )] = name
                c += 1
            end
            for r in 1:size(df,1), c in 1:size(df,2)
                sheet[XLSX.CellRef(r + 1, c )] = df[r,c]
            end
        end
    end
end

function plot_CapacityTable(regionlist,filesuffix,tablename,values;savetodisk=false)
    nodenames = copy(values)
    push!(nodenames,"Region")
    df = DataFrame([[] for _ = nodenames] , nodenames)
    for region in regionlist
        row = []
        for value in values
            capacities_wind = read_file(region*filesuffix*value)
            totCapacity = sum(capacities_wind.Class_A .+ capacities_wind.Class_B)
            push!(row,totCapacity)
        end
        push!(row,region)
        push!(df,row)
    end
    if savetodisk
        tablepath = "C:\\Users\\carin\\Documents\\Thesis\\Code\\Tables\\Total capacity";
        path = "$(tablepath)\\$(tablename).csv"
        CSV.write(path,df);
    end
end

include("SupplyCurves.jl")

function plot_supplycurve(region,suffix; savetodisk=false)
    filepath = "C:\\Users\\carin\\Documents\\Thesis\\Code\\SupplyCurveData\\SupplyCurve_wind2018_$(region)$(suffix).csv"
    figurepath = "C:\\Users\\carin\\Documents\\Thesis\\Code\\Plots\\Supply curves"
    df = DataFrame(CSV.File(filepath))
    plot(df[:,2],df[:,1],seriestype=:scatter,legend=false,ms=6,lw=5,markershape=:x)
    title!("Supply Curve for $region")
    xlabel!("Annual Energy [GWh]")
    ylabel!("LCOE [\$/MWh]")
    if savetodisk
        savefig("$figurepath\\$(region)$(suffix).png");
    end 
end

function plot_supplycurves(region,suffix,values,unit; show_demand=false, savetodisk=false)
    figurepath = "C:\\Users\\carin\\Documents\\Thesis\\Code\\Plots\\Supply curves"
    x_demand = demand(region)
    plot(dpi=600)
    for value in values
        filepath = "C:\\Users\\carin\\Documents\\Thesis\\Code\\SupplyCurveData\\SupplyCurve_wind2018_$(region)$(suffix)$(value).csv"
        df = DataFrame(CSV.File(filepath))
        if show_demand
            df[:,2] = df[:,2]./x_demand
        end
        plot!(df[:,2],df[:,1],label="$(value) $(unit)",legend=false,ms=6,lw=2;palette=:tab10)
    end
    title!("Supply Curve for $region")
    xlabel!("Annual Energy [GWh]")
    ylabel!("LCOE [\$/MWh]")
    plot!(legend=:topleft)
    if show_demand
        vline!([1],color=:black,linestyle=:dash,label = "Demand")
        xlims!(0,1.25)
        suffix *= "_Demand"
        xlabel!("Annual energy/Annual demand")
    end
    if savetodisk
        savefig("$figurepath\\$(region)$(suffix).png");
    end 
end

function demand(region)
    datapath = "C:\\Users\\carin\\Documents\\Thesis\\Code\\GISdata\\Demand\\SyntheticDemand_"
    total_path = datapath * region * "_ssp2-26-2050_2018.jld"
    gisdemand = load(total_path, "demand") ./ 1000      # GW per hour = GWh
    total_demand = sum(gisdemand)
    return total_demand     #GWh
end


end # module
