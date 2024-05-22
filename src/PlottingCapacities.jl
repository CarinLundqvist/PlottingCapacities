module PlottingCapacities

export read_file, plot_capacity, plot_table, plot_CapacityTable, plot_supplycurve, plot_supplycurves, plot_two_supplycurves,
        WindPotential, demand, plotSupergrid, plotAllSupergrid, plotRelativeSupergrid, plotRegression, DataFrameTest

using Plots, DataFrames, HDF5, XLSX, CSV, JLD, DelimitedFiles, Measures, StatsPlots, LaTeXStrings, PlotThemes, Statistics, GLM

plot_font = "Computer Modern"
default(fontfamily=plot_font)

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
    HDF5.close(windvars)
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

function plot_supplycurves(region,suffix,values,unit,legend_text; show_demand=true, show_legend = true, savetodisk=true)
    Plots.theme(:default)
    plot_font = "Computer Modern"
    default(fontfamily=plot_font)

    figurepath = "C:\\Users\\carin\\Documents\\Thesis\\Code\\Plots\\Supply curves\\Adept"
    x_demand = demand(region)

    xtick_pos = 25:25:100
    xtick_labels = string.(xtick_pos) .* " %"
    y_max = 60  # A typical value is 50
    p = plot(xlims = (0,120), xticks = (xtick_pos,xtick_labels), ylims = (0,y_max), size = (800,400), titlefontsize = 18,
            tickfontsize = 14, guidefontsize = 16, legendfontsize=13, grid=false, dpi=600, left_margin=5mm, bottom_margin=5mm)
    for i in 1:length(values)
        filepath = "C:\\Users\\carin\\Documents\\Thesis\\Code\\SupplyCurveData\\SupplyCurve_wind2018_$(region)$(suffix)$(values[i]).csv"
        df = DataFrame(CSV.File(filepath))
        if show_demand
            df[:,2] = df[:,2]./x_demand
        end
        if length(values) > 10
            graph_palette = :tab20
            # tab20, BrBG_11, Paired_10, RdYlBu_11, Set3_11, :Spectral_11
        else
            graph_palette = :tab10
        end
        if show_legend
            label_text = "$(legend_text[i]) $(unit)"
        else
            label_text = ""
        end
        plot!(df[:,2].*100,df[:,1],label=label_text,legend=false,lw=2;palette=graph_palette)
    end
    title!("Supply Curve for $region")
    xlabel!("Annual Energy [GWh]")
    ylabel!("LCOE [\$/MWh]")
    if show_demand
        if show_legend
            demand_label = "Demand"
        else
            demand_label = ""
        end
        vline!([100],color=:gray,linestyle=:dot,lw=2,label=demand_label,legend=false)
        xlabel!("Annual energy/Annual demand")
    end
    if show_legend
        plot!(legend=:outertopright)
    else
        plot!(legend=false)
    end
    #display(p)
    if savetodisk
        split_suffix = split(suffix[2:end],"_")
        savefig("$figurepath\\$(split_suffix[2])$(region)$(split_suffix[1]).png");
        savefig("$figurepath\\pdf\\$(split_suffix[2])$(region)$(split_suffix[1]).pdf");
    end 
    return p
end

function plot_two_supplycurves(regions,suffix,values,unit,legend_text; savetodisk=true)
    p1 = plot_supplycurves(regions[1],suffix,values,unit,legend_text; show_demand=true, show_legend=false, savetodisk=false)
    p2 = plot_supplycurves(regions[2],suffix,values,unit,legend_text; show_demand=true, show_legend=true, savetodisk=false)
    p = plot(p1, p2, layout=grid(1,2,widths=[0.41, 0.59]), size=(1600,600), legendfontsize = 14, titlefontsize=16,
                dpi = 600,left_margin=10mm, bottom_margin=10mm)
    if savetodisk
        figurepath = "C:\\Users\\carin\\Documents\\Thesis\\Code\\Plots\\Supply curves\\Adept"
        split_suffix = split(suffix[2:end],"_")
        savefig(p,"$figurepath\\$(split_suffix[2])$(split_suffix[1]).png");
        savefig("$figurepath\\pdf\\$(split_suffix[2])$(split_suffix[1]).pdf");
    end 
end

function demand(region)
    datapath = "C:\\Users\\carin\\Documents\\Thesis\\Code\\GISdata\\output\\SyntheticDemand_"
    total_path = datapath * region * "_ssp2-34-2050_2018.jld"
    gisdemand = load(total_path, "demand") ./ 1000      # GW per hour = GWh
    total_demand = sum(gisdemand)
    return total_demand     #GWh
end

# For big datasets, like all the countries in the world
function plotAllSupergrid(tablename, plotname, figurepath, regionlist; box, capacity_mix, saveplottodisk)
    Plots.theme(:dao)
    
    # Enter an empty regionlist to get all countries
    df = CreateDataframe(tablename,regionlist)

    #Basic parameters
    nr_scenarios = Int(nrow(filter(:region => ==(df[!,:region][1]), df)))
    nr_countries = Int(nrow(df)/nr_scenarios)
    regions = df[!,:region][1:nr_scenarios:end]
    capden = ["CapDen1.0","CapDen1.0","CapDen0.35","CapDen0.35"]
    allocation = ["Opt","Heur","Opt","Heur"]

    # Creates a plot with a dot for each country and each scenario
    unit = L"\textrm{W/m^2}"
    x_tick_labels = ["Optimization\n1.0 "*unit,"Heuristic\n1.0 "*unit,"Optimization\n0.35 "*unit,"Heuristic\n0.35 "*unit]
    max_cost = 80
    if capacity_mix
        max_share = 55
    else
        max_share = 75
    end
    max_share = 35
    ytick_pos = 0:10:max_share
    ytick_labels = string.(ytick_pos) .* " %"

    if capacity_mix
        y_text = "Share of Onshore Wind in Capacity Mix"
    else
        y_text = "Share of Onshore Wind in TES"
    end

    # Prepares both a scatter plot and a box plot
    pCost = plot(ylims = (0,max_cost), ylabel = "System Cost [€/MWh]", xticks = (1:4,x_tick_labels))
    pShare = plot(ylabel = y_text, ylims = (-5,max_share+5), yticks = (ytick_pos,ytick_labels), xticks = (1:4,x_tick_labels))
    
    pCost_box = plot(ylims = (0,max_cost+5), ylabel = "System Cost [€/MWh]", xticks = (1:4,x_tick_labels))
    pShare_box = plot(ylabel = y_text, ylims = (-5,max_share+5), yticks = (ytick_pos,ytick_labels), xticks = (1:4,x_tick_labels))

    # Plots each country in the scatter plot
    remaining_regions = []
    colorindex = 1
    vline!(pShare,[0],color=:gray,linestyle=:dot,lw=2,legend=false,label="")
    for region in regions
        df_region = filter(:region => ==(region), df)
        region_costs = []
        region_shares =[]
        for i in 1:nr_scenarios
            scenario = filter(:allocation => ==(allocation[i]),filter(:suffix => ==(capden[i]),df_region))
            scenario_cost = scenario[!,:cost][1]
            region_costs = vcat(region_costs,scenario_cost)
            if capacity_mix
                scenario_share = scenario[!,:windcapacity][1] / scenario[!,:capacity][1]
            else
                scenario_share = scenario[!,:windshare][1]
            end
            region_shares = vcat(region_shares,scenario_share)
        end
        if sum(isnan.(region_costs)) == 0 && sum(region_costs .> max_cost) == 0
            scatter!(pCost,(1:4,region_costs), mc = palette(:tab10)[colorindex], ms=10, ma=0.6, markerstrokewidth=0, label = "")
            scatter!(pShare,(1:4,region_shares.*100), mc = palette(:tab10)[colorindex], ms=10, ma=0.6, markerstrokewidth=0, label = region)
            if length(regions) <= 10
                colorindex += 1
            end
            remaining_regions = vcat(remaining_regions,region)
        end
    end
    df_filtered = DataFrame()
    for region in remaining_regions
        df_reg = filter(:region => ==(region), df)
        append!(df_filtered,df_reg)
    end
    # Calculating averages for each scenario
    avgCost = []
    avgShare = []
    for i in 1:nr_scenarios
        avgCost_scen = mean(filter(:allocation => ==(allocation[i]),filter(:suffix => ==(capden[i]),df_filtered))[!,:cost])
        if capacity_mix
            wind_capacity = filter(:allocation => ==(allocation[i]),filter(:suffix => ==(capden[i]),df_filtered))[!,:windcapacity]
            total_capacity = filter(:allocation => ==(allocation[i]),filter(:suffix => ==(capden[i]),df_filtered))[!,:capacity]
            avgShare_scen = mean(wind_capacity./total_capacity)
        else
            avgShare_scen = mean(filter(:allocation => ==(allocation[i]),filter(:suffix => ==(capden[i]),df_filtered))[!,:windshare])
        end
        avgCost = vcat(avgCost,avgCost_scen)
        avgShare = vcat(avgShare,avgShare_scen)
    end
    #scatter!(pCost,(1:4,avgCost), mc=:black, markershape = :cross, ms=12, markerstrokewidth=2)
    #scatter!(pShare,(1:4,avgShare.*100), mc=:black, markershape = :cross, ms=12, markerstrokewidth=2)´
    rounding = 1
    println("Averages for scenarios")
    println("Opt. 1.0 W/m2\tCost: $(round(avgCost[1],digits=rounding))\tShare: $(round(avgShare[1],digits=rounding+2))")
    println("Heur. 1.0 W/m2\tCost: $(round(avgCost[2],digits=rounding))\tShare: $(round(avgShare[2],digits=rounding+2))")
    println("Opt. 0.35 W/m2\tCost: $(round(avgCost[3],digits=rounding))\tShare: $(round(avgShare[3],digits=rounding+2))")
    println("Heur. 0.35 W/m2\tCost: $(round(avgCost[4],digits=rounding))\tShare: $(round(avgShare[4],digits=rounding+2))")

    tablepath = "C:\\Users\\carin\\Documents\\Thesis\\Code\\PlottingCapacities\\src";
    path = "$(tablepath)\\Run5_Opt1.csv"
    df_ref, header = readdlm(path,',',header=true)
    df_ref = DataFrame(df_ref,vec(header))

    println("Weighted average: Wind capacity [GW]")
    #scenario_ref = filter(:allocation => ==(allocation[1]),filter(:suffix => ==(capden[1]),df_filtered))
    for i in 1:nr_scenarios
        scenario = filter(:allocation => ==(allocation[i]),filter(:suffix => ==(capden[i]),df_filtered))
        avg_cost = sum(scenario.cost .* df_ref.windshare) / sum(df_ref.windshare)
        #avg_share = sum(scenario.windshare .* scenario.windcapacity) / sum(scenario.windcapacity)
        println("$(allocation[i]) $(capden[i])\tCost: $(round(avg_cost,digits=rounding))")#\tShare: $(round(avg_share  ,digits=rounding+2))")
    end

    # Creating the scatter plots in their final form
    p = plot(pCost, pShare, layout=(1,2), size=(1600,600), dpi = 600, grid=false, legend=:topright, left_margin=10mm, bottom_margin=10mm,
            tickfontsize=16, guidefontsize=18, legendfontsize = 16, xlims = (0.4,4.6), foreground_color_minor_grid=:white)

    # Moving on to the box plots
    println("The number of countries included: $(length(remaining_regions))")

    length_whisker = 10
    for i = 1:nr_scenarios
        scenario = filter(:allocation => ==(allocation[i]),filter(:suffix => ==(capden[i]),df_filtered))
        scenario_cost = scenario[!,:cost]
        # Actually creates the box plots
        boxplot!(pCost_box, (i,scenario_cost), whisker_range = length_whisker, lw=1, lc=:black)
        if capacity_mix
            scenario_share = scenario[!,:windcapacity] ./ scenario[!,:capacity]
        else
            scenario_share = scenario[!,:windshare]
        end
        boxplot!(pShare_box, (i,scenario_share.*100), whisker_range = length_whisker, lw=1, lc=:black)
    end
    p_box = plot(pCost_box, pShare_box, layout=(1,2), size=(1600,600), dpi = 600, grid=false, foreground_color_minor_grid=:white,
                legend=false, left_margin=10mm, bottom_margin=10mm, tickfontsize=16, guidefontsize=18, xlims = (0.4,4.6))
    #display(p_box)

    # Saves the plots
    if saveplottodisk
        if capacity_mix
            suffix = "Cap"
        else
            suffix = "Gen"
        end
        if box
            savefig(p_box, "$figurepath\\$(plotname)"*suffix*".png")
            savefig(p_box, "$figurepath\\pdf\\$(plotname)"*suffix*".pdf")
        else
            savefig(p, "$figurepath\\$(plotname)"*suffix*".png")
            savefig(p, "$figurepath\\pdf\\$(plotname)"*suffix*".pdf")
            ## For looking at only the share of wind
            #plot!(pShare, size=(800,600), dpi = 600, grid=false, legend=:outertop, left_margin=5mm, bottom_margin=5mm, legend_columns=-1,
            #        tickfontsize=16, guidefontsize=18, legendfontsize = 16, xlims = (0.4,4.6), foreground_color_minor_grid=:white)
            #savefig(pShare, "$figurepath\\WindCapacity"*suffix*".png")
            #savefig(pShare, "$figurepath\\pdf\\WindCapacity"*suffix*".pdf")
        end
    end
end

function plotRelativeAllSupergrid(tablename, geodata, plotname, figurepath, regionlist; capacity_mix, saveplottodisk)
    #Read results
    tablepath = "C:\\Users\\carin\\Documents\\Thesis\\Code\\Tables\\Supergrid";
    path = "$(tablepath)\\$(tablename).csv"
    df = readdlm(path,',')
    Plots.theme(:dao)

    # Enter an empty regionlist to get all countries
    df = CreateDataframe(tablename,regionlist)

    #Basic parameters
    nr_scenarios = Int(nrow(filter(:region => ==(df[!,:region][1]), df)))
    nr_countries = Int(nrow(df)/nr_scenarios)
    regions = df[!,:region][1:nr_scenarios:end]
    capden = ["CapDen1.0","CapDen1.0","CapDen0.35","CapDen0.35"]
    allocation = ["Opt","Heur","Opt","Heur"]

    max_cost = 80
    unit = L"\textrm{W/m^2}"
    xtick_labels = ["Heur. vs. Opt.\n1.0 "*unit,
                    "Heur. vs. Opt.\n0.35 "*unit,
                    "0.35 vs. 1.0 "*unit*"\nOptimization",
                    "0.35 vs. 1.0 "*unit*"\nHeuristic"]

    if capacity_mix
        y_text = "Change in Onshore Wind Capacity "
    else
        y_text = "Change in Onshore Wind Generation"
    end

    ylims_cost = (-2,40)
    ytick_pos_cost = (ceil(ylims_cost[1]/10)*10):5:(floor(ylims_cost[2]/10)*10)
    ytick_labels_cost = string.(Int.(ytick_pos_cost)) .* " %"
    if capacity_mix
        ylims_share = (-30,9)
    else
        ylims_share = (-40,9) 
    end
    ytick_pos_share = (ceil(ylims_share[1]/10)*10):5:(floor(ylims_share[2]/10)*10+5)
    ytick_labels_share = string.(Int.(ytick_pos_share)) .* " %"
    
    pCost = plot(ylabel = "Change in System Cost", xticks = ([1,2,3.5,4.5],xtick_labels), 
                    ylims = (ylims_cost[1],ylims_cost[2]), yticks = (ytick_pos_cost,ytick_labels_cost))
    pShare = plot(ylabel = y_text, xticks = ([1,2,3.5,4.5],xtick_labels), 
                    ylims = (ylims_share[1],ylims_share[2]), yticks = (ytick_pos_share,ytick_labels_share))

    # Adding demand density, capacity density and population density to the dataframe
    df[!, :demanddensity] = rand(nrow(df))
    df[!, :capacitydensity] = rand(nrow(df))
    df[!, :populationdensity] = rand(nrow(df))
    df[!, :windcapacitydensity] = rand(nrow(df))
    df[!, :windpotentialdensity] = rand(nrow(df))
    df[!, :area] = rand(nrow(df))
    df[!, :windgeneration] = rand(nrow(df))
    Geodata = DataFrame(geodata,:auto)
    labels = [:region,:area,:populationdensity]
    rename!(Geodata,labels)

    for row in eachrow(df)
        row.area = filter(:region => ==(row.region), Geodata).area[1]
        row.populationdensity = filter(:region => ==(row.region), Geodata).populationdensity[1]
        row.demanddensity = row.demand/row.area * 1e6 # MWh/yr/km2
        row.capacitydensity = row.capacitydensity/row.area
        row.windcapacitydensity = row.windcapacity/row.area * 1000   #MW/km2
        row.windpotentialdensity = row.windpotential/row.area * 1000   #MW/km2
        row.windgeneration = row.windshare .* row.generation 
    end

    # Only keeps the regions with suitable system cost
    remaining_regions = []
    for region in regions
        df_region = filter(:region => ==(region), df)
        region_costs = []
        region_shares =[]
        for i in 1:nr_scenarios
            scenario = filter(:allocation => ==(allocation[i]),filter(:suffix => ==(capden[i]),df_region))
            scenario_cost = scenario[!,:cost][1]
            region_costs = vcat(region_costs,scenario_cost)
        end
        if sum(isnan.(region_costs)) == 0 && sum(region_costs .> max_cost) == 0
            remaining_regions = vcat(remaining_regions,region)
        end
    end
    df_filtered = DataFrame()
    for region in remaining_regions
        df_reg = filter(:region => ==(region), df)
        append!(df_filtered,df_reg)
    end
    nr_countries_left = length(remaining_regions)
    println("Number of countries included: ",nr_countries_left)

    #Graph settings
    length_whisker = 100
    xlimits = (0.4,5.1)
    printStats = false

    #Picking put the cost scenarios
    scenario_Opt1 = filter(:allocation => ==(allocation[1]),filter(:suffix => ==(capden[1]),df_filtered))
    scenario_Heur1 = filter(:allocation => ==(allocation[2]),filter(:suffix => ==(capden[2]),df_filtered))
    scenario_Opt035 = filter(:allocation => ==(allocation[3]),filter(:suffix => ==(capden[3]),df_filtered))
    scenario_Heur035 = filter(:allocation => ==(allocation[4]),filter(:suffix => ==(capden[4]),df_filtered))
    all_scenarios = [scenario_Opt1, scenario_Heur1, scenario_Opt035, scenario_Heur035]

    Allocation1 = (scenario_Heur1[!,:cost] - scenario_Opt1[:,:cost])./scenario_Opt1[:,:cost]
    Allocation035 = (scenario_Heur035[!,:cost] - scenario_Opt035[:,:cost])./scenario_Opt035[:,:cost]
    CapDenOpt = (scenario_Opt035[!,:cost] - scenario_Opt1[:,:cost])./scenario_Opt1[:,:cost]
    CapDenHeur = (scenario_Heur035[!,:cost] - scenario_Heur1[:,:cost])./scenario_Heur1[:,:cost]
    WorstCase = (scenario_Heur035[!,:cost] - scenario_Opt1[:,:cost])./scenario_Opt1[:,:cost]
    Scenario_comparisons = [Allocation1,Allocation035,CapDenOpt,CapDenHeur]

    #Identifying countries based on constraints for cost
    #comparison = WorstCase
    #criteria = (comparison .> 0.15) #.* (comparison .< 0.06)
    #show(stdout, "text/plain", hcat(remaining_regions[criteria],comparison[criteria]))

    for i = 1:nr_scenarios
        j = i
        if i > 2
            j += 0.5
        end
        # Prints statistical measurements
        k = [1,3,1,2]
        if printStats
            println("\nCost statistics for $(xtick_labels[i])")
            println("The capacity is $(capacity_mix)")
            println("Median: ", median(Scenario_comparisons[i].*100))
            println("Average: ", mean(Scenario_comparisons[i].*100))
            println("Weighted Average (Land Area): ", sum(100*Scenario_comparisons[i].*all_scenarios[k[i]].area) / sum(all_scenarios[k[i]].area))
            println("Weighted Average (TES): ", sum(100*Scenario_comparisons[i].*all_scenarios[k[i]].generation) / sum(all_scenarios[k[i]].generation))
            println("Weighted Average (Capacity Density): ", sum(100*Scenario_comparisons[i].*all_scenarios[k[i]].capacitydensity) / sum(all_scenarios[k[i]].capacitydensity))
            println("Weighted Average (Wind Density): ", sum(100*Scenario_comparisons[i].*all_scenarios[k[i]].windcapacitydensity) / sum(all_scenarios[k[i]].windcapacitydensity))
            println("Weighted Average (Wind Share): ", sum(100*Scenario_comparisons[i].*all_scenarios[k[i]].windshare)./sum(all_scenarios[k[i]].windshare))
        end
        boxplot!(pCost, (j,Scenario_comparisons[i].*100), whisker_range = length_whisker, lw=1, lc=:black)
    end
    plot!(pCost,([2.75,2.75],[ylims_cost[1],ylims_cost[2]]), lc=:black, lw=1)
    plot!(pCost, size=(900,600), dpi = 600, grid=false, foreground_color_minor_grid=:white,
            legend=false, left_margin=5mm, bottom_margin=5mm, tickfontsize=12, guidefontsize=18, xlims = xlimits)

    #Comparing cost for share of wind power
    #(S0,S1,T0,T1)
    if capacity_mix
        windvar = :windcapacity
        totvar = :capacity
    else
        windvar = :windgeneration
        totvar = :generation
    end
    Allocation1 = Change.(scenario_Opt1[!,windvar],scenario_Heur1[!,windvar],scenario_Opt1[!,totvar],scenario_Heur1[!,totvar])
    Allocation035 = Change.(scenario_Opt035[!,windvar],scenario_Heur035[!,windvar],scenario_Opt035[!,totvar],scenario_Heur035[!,totvar])
    CapDenOpt = Change.(scenario_Opt1[!,windvar],scenario_Opt035[!,windvar],scenario_Opt1[!,totvar],scenario_Opt035[!,totvar])
    CapDenHeur = Change.(scenario_Heur1[!,windvar],scenario_Heur035[!,windvar],scenario_Heur1[!,totvar],scenario_Heur035[!,totvar])
    WorstCase = Change.(scenario_Opt1[!,windvar],scenario_Heur035[!,windvar],scenario_Opt1[!,totvar],scenario_Heur035[!,totvar])
    Scenario_comparisons = [Allocation1,Allocation035,CapDenOpt,CapDenHeur]

    #Identifying countries based on constraints for wind share
    #comparison = Allocation035
    #criteria = (comparison .<0) #.* (comparison .< 0.06)
    #show(stdout, "text/plain", hcat(remaining_regions[criteria],comparison[criteria]))

    plot!(pShare,([xlimits[1],xlimits[2]],[0,0]), lc=:lightgray, ls=:dash)
    for i = 1:nr_scenarios
        j = i
        if i > 2
            j += 0.5
        end
        if printStats
            k = [1,3,1,2]
            #windshare = remaining_wind[:,k[i]]./remaining_total[:,k[i]]
            #totCapacityDensity = remaining_total[:,k[i]]./remaining_area
            #windCapacityDensity = remaining_wind[:,k[i]]./remaining_area
            println("\nShare statistics for $(xtick_labels[i])")
            println("The capacity is $(capacity_mix)")
            println("Median: ", median(Scenario_comparisons[i].*100))
            println("Average: ", mean(Scenario_comparisons[i].*100))
            println("Weighted Average (Land Area): ", sum(100*Scenario_comparisons[i].*all_scenarios[k[i]].area) / sum(all_scenarios[k[i]].area))
            println("Weighted Average (TES): ", sum(100*Scenario_comparisons[i].*all_scenarios[k[i]].generation) / sum(all_scenarios[k[i]].generation))
            println("Weighted Average (Capacity Density): ", sum(100*Scenario_comparisons[i].*all_scenarios[k[i]].capacitydensity) / sum(all_scenarios[k[i]].capacitydensity))
            println("Weighted Average (Wind Density): ", sum(100*Scenario_comparisons[i].*all_scenarios[k[i]].windcapacitydensity) / sum(all_scenarios[k[i]].windcapacitydensity))
            println("Weighted Average (Wind Share): ", sum(100*Scenario_comparisons[i].*all_scenarios[k[i]].windshare)./sum(all_scenarios[k[i]].windshare))
        end
        boxplot!(pShare, (j,Scenario_comparisons[i].*100), whisker_range = length_whisker, color=i, lw=1, lc=:black)
    end
    plot!(pShare,([2.75,2.75],[ylims_share[1],ylims_share[2]]), lc=:black, lw=1)
    plot!(pShare, size=(900,600), dpi = 600, grid=false, foreground_color_minor_grid=:white,
            legend=false, left_margin=5mm, bottom_margin=5mm, tickfontsize=12, guidefontsize=18, xlims = xlimits)

    if saveplottodisk
        savefig(pCost, "$figurepath\\$(plotname)_Cost.png")
        savefig(pCost, "$figurepath\\pdf\\$(plotname)_Cost.pdf")
        if capacity_mix
            suffix = "Cap"
        else
            suffix = "Gen"
        end
        savefig(pShare, "$figurepath\\$(plotname)_Share"*suffix*".png")
        savefig(pShare, "$figurepath\\pdf\\$(plotname)_Share"*suffix*".pdf")
    end
end

function plotCapacityMix(tablename, plotname, figurepath, regionlist; capacity_mix, saveplottodisk)
    #Read results
    tablepath = "C:\\Users\\carin\\Documents\\Thesis\\Code\\Tables\\Supergrid";
    path = "$(tablepath)\\$(tablename).csv"
    df = readdlm(path,',')
    Plots.theme(:dao)

    # Enter an empty regionlist to get all countries
    df = CreateDataframe(tablename,regionlist)

    #Basic parameters
    nr_scenarios = Int(nrow(filter(:region => ==(df[!,:region][1]), df)))
    nr_countries = Int(nrow(df)/nr_scenarios)
    regions = df[!,:region][1:nr_scenarios:end]
    capden = ["CapDen1.0","CapDen1.0","CapDen0.35","CapDen0.35"]
    allocation = ["Opt","Heur","Opt","Heur"]

    max_cost = 80
    xtick_labels = ["Wind\n Dominated","Solar PV\n Dominated", "Other"]

    if capacity_mix
        y_text = "Change in Onshore Wind Capacity "
    else
        y_text = "Change in Onshore Wind Generation"
    end

    ylims_cost = (-2,40)
    ytick_pos_cost = (ceil(ylims_cost[1]/10)*10):5:(floor(ylims_cost[2]/10)*10)
    ytick_labels_cost = string.(Int.(ytick_pos_cost)) .* " %"
    ylims_share = (-30,9)
    ytick_pos_share = (ceil(ylims_share[1]/10)*10):5:(floor(ylims_share[2]/10)*10+5)
    ytick_labels_share = string.(Int.(ytick_pos_share)) .* " %"
    
    pCost = plot(ylabel = "Change in System Cost", xticks = ([1,2,3.5,4.5],xtick_labels), 
                    ylims = (ylims_cost[1],ylims_cost[2]), yticks = (ytick_pos_cost,ytick_labels_cost))
    pShare = plot(ylabel = y_text, xticks = ([1,2,3.5,4.5],xtick_labels), 
                    ylims = (ylims_share[1],ylims_share[2]), yticks = (ytick_pos_share,ytick_labels_share))

    # Only keeps the regions with suitable system cost
    remaining_regions = []
    for region in regions
        df_region = filter(:region => ==(region), df)
        region_costs = []
        region_shares =[]
        for i in 1:nr_scenarios
            scenario = filter(:allocation => ==(allocation[i]),filter(:suffix => ==(capden[i]),df_region))
            scenario_cost = scenario[!,:cost][1]
            region_costs = vcat(region_costs,scenario_cost)
        end
        if sum(isnan.(region_costs)) == 0 && sum(region_costs .> max_cost) == 0
            remaining_regions = vcat(remaining_regions,region)
        end
    end
    df_filtered = DataFrame()
    for region in remaining_regions
        df_reg = filter(:region => ==(region), df)
        append!(df_filtered,df_reg)
    end
    nr_countries_left = length(remaining_regions)
    println("Number of countries included:  ",nr_countries_left)

    #Graph settings
    length_whisker = 100
    xlimits = (0,4)
    printStats = false

    #Picking put the cost scenarios
    scenario_Opt1 = filter(:allocation => ==(allocation[1]),filter(:suffix => ==(capden[1]),df_filtered))
    #scenario_Heur1 = filter(:allocation => ==(allocation[2]),filter(:suffix => ==(capden[2]),df_filtered))
    #scenario_Opt035 = filter(:allocation => ==(allocation[3]),filter(:suffix => ==(capden[3]),df_filtered))
    scenario_Heur035 = filter(:allocation => ==(allocation[4]),filter(:suffix => ==(capden[4]),df_filtered))

    BestWorstComparison_costs = (scenario_Heur035[!,:cost] - scenario_Opt1[:,:cost])./scenario_Opt1[:,:cost]

    WindDominated = []
    SolarDominated = []
    OtherDominated = []
    for i in 1:nrow(scenario_Opt1)
        if (scenario_Opt1[!,:windcapacity][i]+scenario_Opt1[!,:solarcapacity][i])/scenario_Opt1[!,:windcapacity][i] < 0.4
            OtherDominated = vcat(OtherDominated,BestWorstComparison_costs[i])
            println("Other")
        else
            if scenario_Opt1[!,:windcapacity][i] > scenario_Opt1[!,:solarcapacity][i]
                WindDominated = vcat(WindDominated,BestWorstComparison_costs[i])
                println("Wind")
            else
                SolarDominated = vcat(SolarDominated,BestWorstComparison_costs[i])
                println("Solar")
            end
        end
    end
    Scenario_comparisons = [WindDominated,SolarDominated,OtherDominated]

    for i = 1:(length(xtick_labels)-1)
        boxplot!(pCost, (i,Scenario_comparisons[i].*100), whisker_range = length_whisker, lw=1, lc=:black)
    end
    #plot!(pCost,([2.75,2.75],[ylims_cost[1],ylims_cost[2]]), lc=:black, lw=1)
    plot!(pCost, size=(900,600), dpi = 600, grid=false, foreground_color_minor_grid=:white,
            legend=false, left_margin=5mm, bottom_margin=5mm, tickfontsize=12, guidefontsize=18, xlims = xlimits)

    #Comparing cost for share of wind power
    #(S0,S1,T0,T1)
    # Allocation1 = Change.(scenario_Opt1[!,:windcapacity],scenario_Heur1[!,:windcapacity],scenario_Opt1[!,:capacity],scenario_Heur1[!,:capacity])
    # Allocation035 = Change.(scenario_Opt035[!,:windcapacity],scenario_Heur035[!,:windcapacity],scenario_Opt035[!,:capacity],scenario_Heur035[!,:capacity])
    # CapDenOpt = Change.(scenario_Opt1[!,:windcapacity],scenario_Opt035[!,:windcapacity],scenario_Opt1[!,:capacity],scenario_Opt035[!,:capacity])
    # CapDenHist = Change.(scenario_Heur1[!,:windcapacity],scenario_Heur035[!,:windcapacity],scenario_Heur1[!,:capacity],scenario_Heur035[!,:capacity])
    # Scenario_comparisons = [Allocation1,Allocation035,CapDenOpt,CapDenHist]

    # #Identifying countries based on constraints for cost
    # #comparison = CapDenOpt
    # #criteria = (comparison .>0) #.* (comparison .< 0.06)
    # #show(stdout, "text/plain", hcat(remaining_regions[criteria],comparison[criteria]))

    # plot!(pShare,([xlimits[1],xlimits[2]],[0,0]), lc=:lightgray, ls=:dash)
    # for i = 1:nr_scenarios
    #     j = i
    #     if i > 2
    #         j += 0.5
    #     end
    #     if printStats
    #         k = [1,3,1,2]
    #         #windshare = remaining_wind[:,k[i]]./remaining_total[:,k[i]]
    #         #totCapacityDensity = remaining_total[:,k[i]]./remaining_area
    #         #windCapacityDensity = remaining_wind[:,k[i]]./remaining_area
    #         println("\nShare statistics for $(xtick_labels[i])")
    #         println("The capacity is $(capacity_mix)")
    #         println("Median: ", median(Scenario_comparisons[i].*100))
    #         println("Average: ", mean(Scenario_comparisons[i].*100))
    #         #println("Weighted Average (Land Area): ", sum(100*Scenario_comparisons[i].*remaining_area)./sum(remaining_area))
    #         #println("Weighted Average (TES): ", sum(100*Scenario_comparisons[i].*remaining_total[:,k[i]])./sum(remaining_total[:,k[i]]))
    #         #println("Weighted Average (Capacity/Generation Density): ", sum(100*Scenario_comparisons[i].*totCapacityDensity)./sum(totCapacityDensity))
    #         #println("Weighted Average (Wind Density): ", sum(100*Scenario_comparisons[i].*windCapacityDensity)./sum(windCapacityDensity))
    #         #println("Weighted Average (Wind Share): ", sum(100*Scenario_comparisons[i].*windshare)./sum(windshare))
    #     end
    #     boxplot!(pShare, (j,Scenario_comparisons[i].*100), whisker_range = length_whisker, color=i, lw=1, lc=:black)
    # end
    # plot!(pShare,([2.75,2.75],[ylims_share[1],ylims_share[2]]), lc=:black, lw=1)
    # plot!(pShare, size=(900,600), dpi = 600, grid=false, foreground_color_minor_grid=:white,
    #         legend=false, left_margin=5mm, bottom_margin=5mm, tickfontsize=12, guidefontsize=18, xlims = xlimits)

    if saveplottodisk
        savefig(pCost, "$figurepath\\$(plotname)_Cost.png")
        savefig(pCost, "$figurepath\\pdf\\$(plotname)_Cost.pdf")
        # if capacity_mix
        #     suffix = "Cap"
        # else
        #     suffix = "Gen"
        # end
        # savefig(pShare, "$figurepath\\$(plotname)_Share"*suffix*".png")
        # savefig(pShare, "$figurepath\\pdf\\$(plotname)_Share"*suffix*".pdf")
    end
end

function plotRegression(tablename, geodata, plotname, figurepath, regionlist; capacity_mix, saveplottodisk)
    Plots.theme(:default)
    plot_font = "Computer Modern"
    default(fontfamily=plot_font)
    palettename = :Blues_5

    # Enter an empty regionlist to get all countries
    df = CreateDataframe(tablename,regionlist)

    #Basic parameters
    max_cost = 80
    nr_scenarios = Int(nrow(filter(:region => ==(df[!,:region][1]), df)))
    nr_countries = Int(nrow(df)/nr_scenarios)
    regions = df[!,:region][1:nr_scenarios:end]
    capden = ["CapDen1.0","CapDen1.0","CapDen0.35","CapDen0.35"]
    allocation = ["Opt","Heur","Opt","Heur"]

    

    # OBS! Remember to change the x_label depending on the x-axis variable
    x_label = "Share of Onshore Wind in the Capacity Mix"
    #units = L"\textrm{[MWh/yr/km^2]}"
    #x_label = "Demand Density " * units
    #x_label = "Density of Installed Wind Capacity [MW/km2]"
    #x_label = "Density of Potential Wind Capacity [MW/km2]"

    # Formatting plots
    xlims = (-2,55)
    xtick_pos = (ceil(xlims[1]/10)*10):10:(floor(xlims[2]/10)*10+5) 
    xtick_labels = string.(Int.(xtick_pos)) .* " %"
    ylims_cost = (-2,27)
    ytick_pos_cost = (ceil(ylims_cost[1]/10)*10):5:(floor(ylims_cost[2]/10)*10+5)
    ytick_labels_cost = string.(Int.(ytick_pos_cost)) .* " %"
    unit = L"\textrm{W/m^2}"
    pCost = plot(title = "Heuristic vs. Optimization 1 "*unit, ylims = (ylims_cost[1],ylims_cost[2]), yticks = (ytick_pos_cost,ytick_labels_cost), 
                    ylabel = "Increase in System Cost", tickfontsize=9, xlabel = x_label, 
                    xlims = (xlims[1],xlims[2]), xticks = (xtick_pos,xtick_labels))

    # Adding demand density, capacity density and population density to the dataframe
    df[!, :demanddensity] = rand(nrow(df))
    df[!, :capacitydensity] = rand(nrow(df))
    df[!, :populationdensity] = rand(nrow(df))
    df[!, :windcapacitydensity] = rand(nrow(df))
    df[!, :windpotentialdensity] = rand(nrow(df))
    df[!, :area] = rand(nrow(df))
    Geodata = DataFrame(geodata,:auto)
    labels = [:region,:area,:populationdensity]
    rename!(Geodata,labels)

    for row in eachrow(df)
        row.area = filter(:region => ==(row.region), Geodata).area[1]
        row.populationdensity = filter(:region => ==(row.region), Geodata).populationdensity[1]
        row.demanddensity = row.demand/row.area * 1e6 # MWh/yr/km2
        row.capacitydensity = row.capacitydensity/row.area
        row.windcapacitydensity = row.windcapacity/row.area * 1000   #MW/km2
        row.windpotentialdensity = row.windpotential/row.area * 1000   #MW/km2
    end
    # country = "Zimbabwe"
    # println(country)
    # test = filter(:suffix => ==("CapDen1.0"),filter(:region => ==(country),df))
    # println(test)
    # println("Solar share: ",test.solarcapacity./test.capacity)
    # println("Wind share: ",test.windcapacity./test.capacity)

    # Only keeps the regions with suitable system cost
    remaining_regions = []
    for region in regions
        df_region = filter(:region => ==(region), df)
        region_costs = []
        region_shares =[]
        for i in 1:nr_scenarios
            scenario = filter(:allocation => ==(allocation[i]),filter(:suffix => ==(capden[i]),df_region))
            scenario_cost = scenario[!,:cost][1]
            region_costs = vcat(region_costs,scenario_cost)
            if capacity_mix
                scenario_share = scenario[!,:windcapacity][1] / scenario[!,:capacity][1]
            else
                scenario_share = scenario[!,:windshare][1]
            end
            region_shares = vcat(region_shares,scenario_share)
        end
        if sum(isnan.(region_costs)) == 0 && sum(region_costs .> max_cost) == 0
            remaining_regions = vcat(remaining_regions,region)
        end
    end
    df_filtered = DataFrame()
    for region in remaining_regions
        df_reg = filter(:region => ==(region), df)
        append!(df_filtered,df_reg)
    end
   
    # Picking out all the scenarios
    capden = ["CapDen1.0","CapDen1.0","CapDen0.35","CapDen0.35"]
    allocation = ["Opt","Heur","Opt","Heur"]
    scenario_Opt1 = filter(:allocation => ==(allocation[1]),filter(:suffix => ==(capden[1]),df_filtered))
    scenario_Heur1 = filter(:allocation => ==(allocation[2]),filter(:suffix => ==(capden[2]),df_filtered))
    scenario_Opt035 = filter(:allocation => ==(allocation[3]),filter(:suffix => ==(capden[3]),df_filtered))
    scenario_Heur035 = filter(:allocation => ==(allocation[4]),filter(:suffix => ==(capden[4]),df_filtered))

    #Selecting scenarios
    scenario_new = scenario_Heur1
    scenario_ref = scenario_Opt1
    systemcost_change = (scenario_new[!,:cost] - scenario_ref[:,:cost])./scenario_ref[:,:cost]


    percentile_quarter = quantile(scenario_ref.demanddensity,0.25)
    percentile_half = quantile(scenario_ref.demanddensity,0.5)
    percentile_threequarter = quantile(scenario_ref.demanddensity,0.75)
    for i in 1:nrow(scenario_ref)
        # Choose which variable that determines the color of the markers
        # colorvariable_country = scenario_ref.demanddensity[i]
        # if colorvariable_country >= 0 && colorvariable_country < percentile_quarter
        #     color =  palette(palettename)[2]
        # elseif colorvariable_country >= percentile_quarter && colorvariable_country < percentile_half
        #     color =  palette(palettename)[3]
        # elseif colorvariable_country >= percentile_half && colorvariable_country < percentile_threequarter
        #     color =  palette(palettename)[4]
        # elseif colorvariable_country >= percentile_threequarter
        #     color =  palette(palettename)[5]
        # else
        #     color = :black
        # end
        # Determine what is one the x-axis
        if capacity_mix
            xvalue = (scenario_ref.windcapacity./scenario_ref.capacity)[i]
        else
            xvalue = scenario_ref.windshare[i]
        end
        #xvalue = scenario_ref.demanddensity[i]
        #xvalue = scenario_ref.solarshare[i]
        #xvalue = scenario_ref.windcapacitydensity[i]
        #xvalue = scenario_ref.windpotentialdensity[i]

        color = palette(:Blues_4)[4]
        scatter!(pCost,(xvalue*100,systemcost_change[i]*100), mc=color,
                    markershape=:xcross, markerstrokewidth=0, ms=10, ma=1, label = "")
    end
    dfr = DataFrame()
    dfr.x = (scenario_ref.windcapacity./scenario_ref.capacity) *100
    dfr.y = systemcost_change * 100
    model = lm(@formula(y ~ x), dfr)
    println(r2(model))
    k = coef(model)
    plot!(pCost,(dfr.x,k[1]*dfr.x), color=palette(:Reds_4)[4], lw = 2, label = "Linear Fit")

    # Creating the plots properly
    #MakeHistogram(scenario_Heur1.windcapacitydensity, figurepath, "Hist_WindCapDen_Heur", savetodisk=true)
    p = plot(pCost, size=(900,600), dpi = 600, grid=false, legend=:topleft,
            left_margin=5mm, bottom_margin=5mm, tickfontsize=14, guidefontsize=16, titlefontsize=18, legendfontsize=16)
    #display(p)
    if saveplottodisk
        savefig(p, "$figurepath\\$(plotname).png")
        savefig(p, "$figurepath\\pdf\\$(plotname).pdf")
    end
end

function Cost_And_Shares(df,nr_scenarios,nr_countries)
    all_costs = zeros(nr_countries,nr_scenarios)
    all_shares = zeros(nr_countries,nr_scenarios)
    all_generation = zeros(nr_countries,nr_scenarios)
    all_demand = zeros(nr_countries,nr_scenarios)
    all_capacity = zeros(nr_countries,nr_scenarios)
    all_capwind = zeros(nr_countries,nr_scenarios)
    all_capmix = zeros(nr_countries,nr_scenarios)
    x_label = 1
    for i in 2:length(df[1,:])
        index_coun = ((i-2) % nr_countries) + 1
        all_costs[index_coun,x_label] = df[5,i]
        all_shares[index_coun,x_label] = df[7,i]
        all_generation[index_coun,x_label] = df[6,i]
        all_demand[index_coun,x_label] = df[4,i]
        all_capacity[index_coun,x_label] = df[9,i]
        all_capwind[index_coun,x_label] = df[10,i]
        all_capmix[index_coun,x_label] = df[10,i]/df[9,i]
        if (i-1) % nr_countries == 0
            x_label += 1
        end
    end
    return all_costs, all_shares, all_generation, all_demand, all_capacity, all_capwind, all_capmix
end

function Solardata(df,nr_scenarios,nr_countries)
    all_solarshares = zeros(nr_countries,nr_scenarios)
    all_capsolar = zeros(nr_countries,nr_scenarios)
    x_label = 1
    for i in 2:length(df[1,:])
        index_coun = ((i-2) % nr_countries) + 1
        all_solarshares[index_coun,x_label] = df[8,i]
        all_capsolar[index_coun,x_label] = df[11,i]
        if (i-1) % nr_countries == 0
            x_label += 1
        end
    end
    return all_solarshares, all_capsolar
end

#For when the total generation/capacity changes as well as the share
function Change(S0,S1,T0,T1)
    R = 2*(S1-S0)/(T0+T1)
    return R
end

function CreateDataframe(tablename,regionlist)
    tablepath = "C:\\Users\\carin\\Documents\\Thesis\\Code\\Tables\\Supergrid";
    path = "$(tablepath)\\$(tablename).csv"
    df = readdlm(path,',')
    df = DataFrame(df,:auto)
    labels = [:region,:suffix,:allocation,:demand,:cost,:generation,:windshare,:solarshare,
                :capacity,:windcapacity,:solarcapacity,:windpotential]
    rename!(df,labels)
    deleteat!(df,1)
    if length(regionlist) > 0
        df_selection = DataFrame()
        for region in regionlist
            df_reg = filter(:region => ==(region), df)
            append!(df_selection,df_reg)
        end
        return df_selection
    else
        return df
    end
end

function FilterAndUpgradeDataframe(df)

end

function MakeHistogram(data, figurepath, plotname; savetodisk=false)
    xmax = 1.4
    b_range = range(0, xmax, length=141)
    h = histogram(data,bins=b_range,xticks = 0:0.2:xmax,legend=false,dpi=600,grid=false)
    unit = L"\textrm{[MW/km^2]}"
    xlabel!("Installed Wind Capacity "*unit)
    ylabel!("Number of Regions")
    #legend!(false)
    if savetodisk
        savefig(h, "$figurepath\\$(plotname).png")
        savefig(h, "$figurepath\\pdf\\$(plotname).pdf")
    end
end


end # module
