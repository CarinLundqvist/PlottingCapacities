include("PlottingCapacities.jl")
import .PlottingCapacities as PC

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
# unit = "pers/km\$^2\$"
# for region in regionlist
#     for i in 1: length(values)
#         tot_suffix = suffix * values[i]
#         PC.WindPotential(region,tot_suffix)
#         #PC.plot_supplycurve(region,tot_suffix,savetodisk=true)
#     end
#     PC.plot_supplycurves(region,suffix,values,unit; show_demand=false,savetodisk=true)
#     PC.plot_supplycurves(region,suffix,values,unit; show_demand=true,savetodisk=true)
# end

# LAND TYPE
# regionlist = ["Australia","Brazil","Canada","Germany", "India","Kenya","Netherlands","Saudi Arabia"]
# suffix = "_CapDen10_Landtype"
# values = ["Water","Shrubland","Forest","Grassland","Cropland","Wetland","Urban","Barren and Ice"]
# unit = ""
# for region in regionlist
#     for i in 1: length(values)
#         tot_suffix = suffix * values[i]
#         PC.WindPotential(region,tot_suffix)
#         #PC.plot_supplycurve(region,tot_suffix,savetodisk=true)
#     end
#     PC.plot_supplycurves(region,suffix,values,unit; show_demand=false,savetodisk=true)
#     PC.plot_supplycurves(region,suffix,values,unit; show_demand=true,savetodisk=true)
# end

# PROTECTED AREAS
# regionlist = ["Brazil","Bulgaria","Cambodia","Germany","India","United States","Venezuela","Zambia"]
# suffix = "_CapDen10_ProtectedArea"
# values = ["No restriction","Strict NatRes","WildArea","NatPark","NatMonument","HabitatMang","ProtectedLandscape","MangResProtArea","Not reported","Not applicable","Not assigned"]
# unit = ""
# for region in regionlist
#     for i in 1: length(values)
#         tot_suffix = suffix * values[i]
#         PC.WindPotential(region,tot_suffix)
#         #PC.plot_supplycurve(region,tot_suffix,savetodisk=true)
#     end
#     PC.plot_supplycurves(region,suffix,values,unit; show_demand=false,savetodisk=true)
#     PC.plot_supplycurves(region,suffix,values,unit; show_demand=true,savetodisk=true)
# end

## Table of the change in total capacity

# POPULATION DENSITY
regionlist = ["Australia","Brazil","China","Germany", "India","Netherlands","Nigeria","Uganda","Venezuela"]
filesuffix = "_CapDen10_PopDen"
tablename = "PopDenTotCap10"
values = ["150","500","1000","5000"];
PC.plot_CapacityTable(regionlist,filesuffix,tablename,values,savetodisk=true)

# LAND TYPE
regionlist = ["Australia","Brazil","Canada","Germany", "India","Kenya","Netherlands","Saudi Arabia"]
filesuffix = "_CapDen10_Landtype"
tablename = "LandTypeTotCap10"
values = ["Water","Shrubland","Forest","Grassland","Cropland","Wetland","Urban","Barren and Ice"];
PC.plot_CapacityTable(regionlist,filesuffix,tablename,values,savetodisk=true)

# PROTECTED AREAS
regionlist = ["Brazil","Bulgaria","Cambodia","Germany","India","United States","Venezuela","Zambia"]
filesuffix = "_CapDen10_ProtectedArea"
tablename = "ProtectedAreaTotCap10"
values = ["No restriction","Strict NatRes","WildArea","NatPark","NatMonument","HabitatMang","ProtectedLandscape","MangResProtArea","Not reported","Not applicable","Not assigned"];
PC.plot_CapacityTable(regionlist,filesuffix,tablename,values,savetodisk=true)
