	
CRF(r,T) = r / (1 - 1/(1+r)^T)
meandrop(x; dims=dims) = dropdims(mean(x, dims=dims), dims=dims)
sumdrop(x; dims=dims) = dropdims(sum(x, dims=dims), dims=dims)

function WindPotential(region,suffix)
	annualEnergy_A, annualEnergy_B, lcoe_A, lcoe_B = supply_wind(region*suffix)
	energy = [annualEnergy_A ;annualEnergy_B]
	lcoe = [lcoe_A; lcoe_B]

	ws = sortperm(lcoe)
	wx = cumsum(energy[ws])
	Wind = DataFrame()
	Wind.LCOE = sort(lcoe)
	Wind.Energy = wx
	filepath = "C:\\Users\\carin\\Documents\\Thesis\\Code\\SupplyCurveData"
	CSV.write("$(filepath)\\SupplyCurve_wind2018_$(region)$(suffix).csv",Wind);
end

function supply_wind(filename)
	datapath = "C:\\Users\\carin\\Documents\\Thesis\\Code\\GISdata\\output"
    dataname_root = "\\GISdata_wind2018_"
    datatype = ".mat"
    total_datapath  = datapath*dataname_root*filename*datatype
	wind = h5open(total_datapath,"r")

	# Getting one CF capacity value per region and resource class
	cf_A=read(wind,"CFtime_windonshoreA");
	cf_B=read(wind,"CFtime_windonshoreB");
	#cf_Off=read(wind,"CFtime_windoffshore");
	cap_per_region_A=read(wind,"capacity_onshoreA");
	cap_per_region_B= read(wind,"capacity_onshoreB");
	#cap_per_region_Off=read(wind,"capacity_offshore");

	meanCF_A = mean_skipNaN_dim12(cf_A)
	meanCF_B = mean_skipNaN_dim12(cf_B)
	#meanCF_Off = mean_skipNaN_dim12(cf_Off)
	capacity_A = sumdrop(cap_per_region_A, dims=1)
	capacity_B = sumdrop(cap_per_region_B, dims=1)
	#capacity_Off = sumdrop(cap_per_region_Off, dims=1)

	# The economic bit
	WACC = 0.05		#Weighted average capital cost, typically set to 5 %
	#Where do these constants come from?
	totalcost_A = capacity_A .* (825 * CRF(WACC, 25) + 33)
	totalcost_B = capacity_B .* ((825+200) * CRF(WACC, 25) + 33)
	#totalcost_Off = capacity_Off .* (1500 * CRF(WACC, 25) + 55)
	hours = 8760
	annualEnergy_A = capacity_A .* meanCF_A .* hours
	annualEnergy_B = capacity_B .* meanCF_B .* hours
	#annualEnergy_Off = capacity_Off .* meanCF_Off .* hours
	lcoe_A = totalcost_A ./ annualEnergy_A .* 1000
	lcoe_B = totalcost_B ./ annualEnergy_B .* 1000
	#lcoe_Off = totalcost_Off ./ annualEnergy_Off .* 1000
	return annualEnergy_A, annualEnergy_B, lcoe_A, lcoe_B
end


# Gives an average hourly CF for all regions together and each resource class
function mean_skipNaN_dim12(xx)
	hours, regs, classes = size(xx)
	out = Vector{Float64}(undef,classes)
	for c = 1:classes
		hourtot = 0.0
		hourcount = 0
		for h = 1:hours
			regtot = 0.0
			regcount = 0
			for r = 1:regs
				x = xx[h,r,c]
				if !isnan(x)
					regtot += x
					regcount += 1
				end
			end
			if regcount != 0
				hourtot += regtot / regcount
				hourcount += 1
			end
		end
		out[c] = hourtot / hourcount
	end
	return out
end
