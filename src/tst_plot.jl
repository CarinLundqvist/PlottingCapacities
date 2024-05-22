include("PlottingCapacities.jl")
import .PlottingCapacities as PC

## Creating the final plots for the results: System cost and Share of onshore wind power in TES
# regionsRun4 = [:Brazil,:Canada,:China,:Germany,:Kenya,:Netherlands,:Nigeria,:Venezuela,:Vietnam]
path = "C:\\Users\\carin\\Documents\\Thesis\\Code\\regions_sorted.csv"
geodata = PC.DelimitedFiles.readdlm(path,',')[:,2:4]
tablename = "Run7_BatteryCost_sort"
figurepath = "C:\\Users\\carin\\Documents\\Thesis\\Code\\Plots\\Supergrid\\Expert"
regionlist = []#["India","Malaysia","Netherlands"]#["Algeria","Cameroon","Chile"]#["India","Malaysia","Netherlands"]
# regionlist = ["Argentina", "Azerbaijan", "Bolivia", "Côte d'Ivoire", "China", "Croatia", "Democratic Republic of the Congo", 
#                     "Ecuador", "Eritrea", "France", "Greece", "Iceland", "Iraq", "Jamaica", "Kenya", "Latvia", "Libya", "Mongolia", 
#                     "Myanmar", "Nigeria", "Pakistan", "Paraguay", "Portugal", "Romania", "Saudi Arabia", "Slovakia", "South Africa", 
#                     "Sri Lanka", "Sweden", "Tajikistan", "Togo", "Turkmenistan", "United Kingdom", "Yemen", "Albania", "Armenia", 
#                     "Bosnia and Herzegovina", "Bulgaria", "Cambodia", "Colombia", "Cuba", "Denmark", "Egypt", "Estonia", "Georgia", 
#                     "Guatemala", "Haiti", "India", "Ireland", "Lithuania", "Mauritius", "Montenegro", "Namibia", "North Korea", "Peru", 
#                     "Senegal", "Slovenia", "Sudan", "Switzerland", "Tanzania", "Trinidad and Tobago", "Venezuela", "Zambia", "Algeria", 
#                     "Australia", "Bangladesh", "Benin", "Botswana", "Cameroon", "Cyprus", "El Salvador", "Ethiopia", "Germany", "Honduras", 
#                     "Indonesia", "Jordan", "Kyrgyzstan", "Malaysia", "Mexico", "Morocco", "Nepal", "Nicaragua", "Norway", "Panama", 
#                     "Philippines", "Serbia", "South Sudan", "Suriname", "Syria", "Thailand", "Tunisia", "Ukraine", "Uruguay", "Vietnam", 
#                     "Zimbabwe", "Angola", "Austria", "Belarus", "Brazil", "Canada", "Chile", "Costa Rica", "Dominican Republic", "Finland", 
#                     "Gabon", "Ghana", "Hungary", "Iran", "Italy", "Kazakhstan", "Macedonia", "Moldova", "Mozambique", "Netherlands", "Niger", 
#                     "Oman", "Poland", "Spain", "Turkey", "United Arab Emirates"]

## Plotting the absolute cost and wind share
#PC.plotAllSupergrid(tablename, "Run5_EXAMPLE", figurepath, regionlist, box=false, capacity_mix=true, saveplottodisk = false)

## Plotting the relative cost and wind share
PC.plotRelativeAllSupergrid(tablename, geodata, "Run7Rel_BatteryCost", figurepath, regionlist, capacity_mix=true, saveplottodisk = true)
#PC.plotCapacityMix(tablename, "Run5_CapMix", figurepath, regionlist, capacity_mix=true, saveplottodisk = true)

## Doing a regression analysis with demand density
#PC.plotRegression(tablename, geodata,"Run5Regression_DemDen", figurepath, regionlist, 
#                    capacity_mix=true, saveplottodisk = false)

#PC.DataFrameTest("Run5_solar_sort",["Australia","Sweden"])

## For plotting a bar plot with capacitites
# regionlist = ["Germany", "India", "Tanzania","United States","Venezuela"]
# suffix = "_ProtArea"
# values = ["NatRes","WildArea","NatPark","NatMon","HabMan","ProtLand", "ManRes","NotRep","NotApp","NotAss"]
# for i in 1:length(regionlist)
#     regionname = regionlist[i]
#     for value in values
#         capacities_wind = PC.read_file(regionname*suffix*value)
#         PC.plot_capacity(capacities_wind,regionname,suffix*value,savetodisk=true)
#     end
# end

## For creating a table where the capacities for each country are compared in a table for different parameter values
## LAND TYPE
# regionlist = ["Brazil","Germany", "Kenya", "India"]
# suffix = "_Landtype"
# values = ["Water","Shrubland","Forest","Grassland","Cropland","Wetland","Urban","Barren_Ice"]
# ref = "Water"
# wind_class = "A"
# for region in regionlist
#     capacities_wind_ref = PC.read_file(region*suffix*ref)
#     PC.plot_table(capacities_wind_ref,region,suffix,values,wind_class,savetodisk=true)
# end

## PROTECTED AREAS
# regionlist = ["Germany", "India", "Tanzania","United States","Venezuela"]
# suffix = "_ProtArea"
# values = ["NatRes","WildArea","NatPark","NatMon","HabMan","ProtLand", "ManRes","NotRep","NotApp","NotAss"]
# ref = "Water"
# wind_class = "B"
# for region in regionlist
#     capacities_wind_ref = PC.read_file(region*"_Landtype"*ref)
#     PC.plot_table(capacities_wind_ref,region,suffix,values,wind_class,savetodisk=true)
# end

## POPULATION DENSITY
# regionlist = ["Australia","Brazil","China","Germany", "India","Kenya","Malaysia","Nigeria","Serbia","South Korea","United States","Pakistan","Uganda","Vietnam"]
# suffix = "_PopDen"
# values = ["150","500","1000","5000"];
# ref = "150"
# wind_class = "A"
# for region in regionlist
#     capacities_wind_ref = PC.read_file(region*suffix*ref)
#     PC.plot_table(capacities_wind_ref,region,suffix,values,wind_class,savetodisk=true)
# end

## DISTANCE TO ELECTRICTY ACCESS
# regionlist = ["Australia","Brazil","China","India","Kenya","Vietnam"]
# suffix = "_ElecAcc"
# values = ["5","50","150","300"];
# ref = "150"
# wind_class = "B"
# for region in regionlist
#     capacities_wind_ref = PC.read_file(region*suffix*ref)
#     PC.plot_table(capacities_wind_ref,region,suffix,values,wind_class,savetodisk=true)
# end

## For plotting supply curves
# POPULATION DENSITY
# regionlist = ["Australia","Brazil","China","Germany", "India","Netherlands","Nigeria","Uganda","Venezuela"]
# suffix = "_CapDen10_PopDen"
# values = ["150","500","1000","5000"]
# legend_text = values
# unit = "pers/km\$^2\$"
# for region in regionlist
#     for i in 1: length(values)
#         tot_suffix = suffix * values[i]
#         PC.WindPotential(region,tot_suffix)
#         #PC.plot_supplycurve(region,tot_suffix,savetodisk=true)
#     end
#     #PC.plot_supplycurves(region,suffix,values,unit; show_demand=false,savetodisk=true)
#     PC.plot_supplycurves(region,suffix,values,unit,legend_text; show_demand=true,show_legend=true,savetodisk=true)
# end

# # LAND TYPE
# regionlist = ["Australia","Brazil","Canada","Germany", "India","Kenya","Netherlands","Saudi Arabia"]
# suffix = "_CapDen10_Landtype"
# values = ["Water","Shrubland","Forest","Grassland","Cropland","Wetland","Urban","Barren and Ice"]
# legend_text = values
# unit = ""
# for region in regionlist
#     for i in 1: length(values)
#         tot_suffix = suffix * values[i]
#         PC.WindPotential(region,tot_suffix)
#         #PC.plot_supplycurve(region,tot_suffix,savetodisk=true)
#     end
#     #PC.plot_supplycurves(region,suffix,values,unit; show_demand=false,savetodisk=true)
#     PC.plot_supplycurves(region,suffix,values,unit,legend_text; show_demand=true,show_legend=true,savetodisk=true)
# end

# # PROTECTED AREAS
# regionlist = ["Brazil","Bulgaria","Cambodia","Germany","India","United States","Venezuela","Zambia"]
# suffix = "_CapDen10_ProtectedArea"
# values = ["No restriction","Strict NatRes","WildArea","NatPark","NatMonument","HabitatMang","ProtectedLandscape","MangResProtArea","Not reported","Not applicable","Not assigned"]
# legend_text = ["No restriction","Ia","Ib","II","III","IV","V","VI","Not reported","Not applicable","Not assigned"]
# unit = ""
# for region in regionlist
#     for i in 1: length(values)
#         tot_suffix = suffix * values[i]
#         PC.WindPotential(region,tot_suffix)
#         #PC.plot_supplycurve(region,tot_suffix,savetodisk=true)
#     end
#     #PC.plot_supplycurves(region,suffix,values,unit; show_demand=false,savetodisk=true)
#     PC.plot_supplycurves(region,suffix,values,unit,legend_text; show_demand=true,show_legend=true,savetodisk=true)
# end

# For combining tables in one graph
#regionlist = ["Australia","Brazil","China","Germany", "India","Netherlands","Nigeria","Uganda","Venezuela"]
# regions = ("Australia", "Germany") #Two regions and two regions only!
# suffix = "_CapDen10_PopDen"
# values = ["150","500","1000","5000"]
# unit = "pers/km\$^2\$"
# legend_text = values

# regions = ("Cambodia","Germany")
# suffix = "_CapDen10_ProtectedArea"
# values = ["No restriction","Strict NatRes","WildArea","NatPark","NatMonument","HabitatMang","ProtectedLandscape","MangResProtArea","Not reported","Not applicable","Not assigned"]
# unit = ""
# legend_text = ["No restriction","Ia","Ib","II","III","IV","V","VI","Not reported","Not applicable","Not assigned"]

# regions = ("Brazil","Germany")
# suffix = "_CapDen10_Landtype"
# values = ["Water","Shrubland","Forest","Grassland","Cropland","Wetland","Urban","Barren and Ice"]
# unit = ""
# legend_text = values

# for i in 1: length(values)
#     tot_suffix = suffix * values[i]
#     PC.WindPotential(regions[1],tot_suffix)
#     PC.WindPotential(regions[2],tot_suffix)
#     #PC.plot_supplycurve(region,tot_suffix,savetodisk=true)
# end
# PC.plot_two_supplycurves(regions,suffix,values,unit,legend_text,savetodisk=true)

## Table of the change in total capacity
# POPULATION DENSITY
#regionlist = ["Australia","Brazil","China","Germany", "India","Netherlands","Nigeria","Uganda","Venezuela"]
#regionlist = PC.readdlm(path,',')[:,2]
#filesuffix = "_CapDen10_PopDen"
# filesuffix = "_Final_PopDen"
# tablename = "PopDen_Final_TotCap"
# values = ["150","500","1000","5000"];
# PC.plot_CapacityTable(regionlist,filesuffix,tablename,values,savetodisk=true)

# # LAND TYPE
# regionlist = ["Australia","Brazil","Canada","Germany", "India","Kenya","Netherlands","Saudi Arabia"]
# regionlist = PC.readdlm(path,',')[:,2]
# filesuffix = "_CapDen10_Landtype"
# filesuffix = "_Final_Landtype"
# tablename = "LandType_Final_TotCap"
# values = ["Water","Shrubland","Forest","Grassland","Cropland","Wetland","Urban","Barren and Ice"];
# PC.plot_CapacityTable(regionlist,filesuffix,tablename,values,savetodisk=true)

# # PROTECTED AREAS
# regionlist = ["Brazil","Bulgaria","Cambodia","Germany","India","United States","Venezuela","Zambia"]
# regionlist = PC.readdlm(path,',')[:,2]
# filesuffix = "_CapDen10_ProtectedArea"
# filesuffix = "_Final_ProtectedArea"
# tablename = "ProtectedAreaTotCap10"
# tablename = "ProtectedArea_Final_TotCap"
# values = ["No restriction","Strict NatRes","WildArea","NatPark","NatMonument","HabitatMang","ProtectedLandscape","MangResProtArea","Not reported","Not applicable","Not assigned"];
# PC.plot_CapacityTable(regionlist,filesuffix,tablename,values,savetodisk=true)

