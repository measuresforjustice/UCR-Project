# This file is part of the UCR imputation project.
# Copyright 2023 Measures for Justice Institute.
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License version 3 as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE.  See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along
# with this program.  If not, see <https://www.gnu.org/licenses/>.


###################################
# 6. Aggregation and census merge #
###################################

# Data dependencies: 
# 
# 1. data output/5. Geocoding.csv
# 2. data dependencies/UCR data/Police Employee Data (2010-2013)
# 3. data dependencies/Auxiliary data/Census.csv
#
# This file does the following:
#
# 1. Loads intermediate data: data output/5. Historical agency imputation.csv
# 2. Aggregates to annual totals
# 3. Merges in police employee data
# 4. Merges in census data
# 5. Saves output: /data output/6. Aggregation and census merge.csv
#
# Libraries 
# install.packages("data.table")
# install.packages("stringr")
# install.packages("bit64)

library(data.table)
library(stringr)
library(bit64)

# **** Provide file path to the location of the github repository ****
origin = ""


#############################
# 1. Load intermediate data #
#############################

ucr = fread(paste0(origin, "/UCR-data-request/data output/5. Historical agency imputation.csv"))


#################################
# 2. Aggregate to annual totals #
#################################

# Get roots to part I crimes
roots = c("murd", "mans", "rape", "robb", "assa", "simp", "burg", "larc", "vhct", "arso")

# Function to help get column indexes for specific variables
gipper = function(dat, pat){
	
	# get variable names
	names = names(dat)
	
	# search for pattern among variable names
	cols = which(grepl(names, pattern=pat))
	
	# return
	return(cols)
	
}

# loop through roots and create yearly aggregates
for(i in 1:length(roots)){
	
	# get aggregate columns
	clr.col = paste(roots[i], "clr", sep=".")
	tot.col = paste(roots[i], "tot", sep=".")
	
	# get monthly cols
	monthly.clr.cols = gipper(ucr, paste0(roots[i], ".clr", "[0-9]"))
	monthly.tot.cols = gipper(ucr, paste0(roots[i], ".tot", "[0-9]"))
	
	# sum across months
	y.clr = apply(ucr[, ..monthly.clr.cols], 1, sum)
	y.tot = apply(ucr[, ..monthly.tot.cols], 1, sum)
	
	# create column
	ucr[, (clr.col) := y.clr]
	ucr[, (tot.col) := y.tot]
	
}


#########################################################################################
# NOTE: One of the Part I crimes is aggravated assault.  However, aggravated assault is #
# not recorded in the UCR data.  To get these numbers, we must subtract simple assaults #
# from total assaults (for both offenses and clearances).																#
#########################################################################################

# create yearly aggregates for aggravated assault totals and clearances
ucr[, agga.tot := assa.tot - simp.tot]
ucr[, agga.clr := assa.clr - simp.clr]


####################################
# 3. Merge in police employee data #
####################################

# Load police employee data
ped2010 = fread(paste0(origin, "/UCR-data-request/data dependencies/UCR data/Police Employee Data (2010-2013)/2010 (ICPSR_33525)/DS0001/33525-0001-Data.tsv"))[, c("V3", "V6", "V19", "V20")]
ped2011 = fread(paste0(origin, "/UCR-data-request/data dependencies/UCR data/Police Employee Data (2010-2013)/2011 (ICPSR_34584)/DS0001/34584-0001-Data.tsv"))[, c("V3", "V6", "V19", "V20")]
ped2012 = fread(paste0(origin, "/UCR-data-request/data dependencies/UCR data/Police Employee Data (2010-2013)/2012 (ICPSR_35020)/DS0001/35020-0001-Data.tsv"))[, c("V3", "V6", "V19", "V20")]
ped2013 = fread(paste0(origin, "/UCR-data-request/data dependencies/UCR data/Police Employee Data (2010-2013)/2013 (ICPSR_36119)/DS0001/36119-0001-Data.tsv"))[, c("V3", "V6", "V19", "V20")]

# combine police employee data into a single file
ped = rbind(ped2010, ped2011, ped2012, ped2013)

# rename the variables
names(ped) = c("ori", "year", "officers", "employees")

# merge into ucr
ucr=merge(ucr, ped, by=c("ori", "year"), all.x=TRUE)


###########################
# 4. Merge in census data #
###########################

# load census data
census = fread(paste0(origin, "/UCR-data-request/data dependencies/Auxiliary data/Census.csv"))

# create a geoid_place in census
census[which(nchar(as.character(geoid))>5), geoid_place := geoid]

# turn geoid_place and county1_fips into characters
ucr$geoid_place = as.character(ucr$geoid_place)
census$geoid_place = as.character(census$geoid_place)

ucr$county1_fips = as.character(ucr$county1_fips)
census$county1_fips = as.character(census$geoid)   # copy geoid into a new variable, county1_fips, so we can merge

# split ucr into two groups
local.le = ucr[type.local==1 & !is.na(geoid_place)]     								# local LE with place fips
other.le = ucr[type.local!=1 | (type.local==1 & is.na(geoid_place))]    # local LE without place fips AND other le

census_places = census[area.type!="county"]
census_counties = census[area.type=="county"]

# merge census place vars
local.le = merge(local.le, census_places[, 4:19], by="geoid_place", all.x=TRUE)

# merge county vars into other.le
other.le = merge(other.le, census_counties[, c(4:18, 20)], by="county1_fips", all.x=TRUE)


#################################################################################################
# Some census variables have the value -666666666, -1999999998, or -1333333332.  These occur in #
# census places or county subdivisions where the population or number of households (i.e. the		#
# denominator) is zero.  For these, we will retain the place or subdivision *population* but		#
# substitute in county averages for the other variables.																				#
#################################################################################################

# loop to handle negative census values indicating zero households
for(i in 1:ncol(census)){
	
	# get variable
	var = names(census)[i]
	
	# exclude non-numeric variables -- don't need to check these
	if( ! var %in% c("geoid", "area.name", "area.type", "geoid_place", "county1_fips") ){
		
		# get column in ucr and census
		col.ucr = which(names(local.le)==var) 
		col.census = which(names(census)==var)
		
		# rows with values less than 0
		rows = which(local.le[[col.ucr]] < 0)
		
		if( length(rows)>0 ){
			
			# loop through, find corresponding county, and use census to fill in the county value
			for(j in 1:length(rows)){

				# get row
				row = rows[j]
				
				# find county1_fips
				fips = local.le[row, county1_fips]
				
				# get value for the county
				val = census[geoid==fips][[col.census]]
				
				# substitute into local.le
				local.le[row, (col.ucr) := val]
				
			}
			
		}
		
	}
	
}


###################################################################################################
# Some agencies have cross-county jurisdiction.  We now loop through those agencies and fill in   #
# values for census variables.  Total population (pop.tot) will equal the sum of the county 			#
# populations where an agency has jurisdiction.  Other census variables will be weighted averages	#
# across counties where an agency has jurisdiction (weights according to county populations). 	  #
###################################################################################################

# agencies with cross county jurisdiction
cc_agencies = unique(other.le[!county1_fips %in% census$county1_fips, ori])

# loop to fill in
for(agcy in cc_agencies){
	
	# get counties for which the agency has jurisdiction
	fips = str_split(unique(other.le[ori==agcy, county1_fips]), pattern="; ")[[1]]
	
	# subset census_counties to those counties
	c_counties = census_counties[county1_fips %in% fips]
	
	# create aggregate stats, and record these in other.le.
	#
	# 1) aggregate stat for pop.tot: sum of all populations
	# 2) aggregate stat for other census variables: weighted mean
	
	for(i in c(4:18)){
		
		# get column name and corresponding column number in other.le
		col.name = names(c_counties)[i]
		col.num = which(names(other.le)==col.name)
		
		if(col.name=="pop.tot"){
			
			val = sum(c_counties[[i]])
			other.le[ori==agcy][[col.num]] = val
			
		} else {
			
			val = weighted.mean(c_counties[[i]], c_counties$pop.tot)
			other.le[ori==agcy][[col.num]] = val
			
		}
		
	}
	
	
}

# recombine agency files
ucr = rbind(other.le, local.le)

# sort ucr
ucr = ucr[order(county1_fips, year)]


##################
# 6. Save output #
##################

write.csv(x=ucr, row.names=FALSE, file=paste0(origin, "/UCR-data-request/data output/6. Aggregation and census merge.csv"))