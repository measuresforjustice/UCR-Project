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


##############################
# 7. Initial values for MICE #
##############################

# Data dependencies: 
# 
# 1. data output/6. Aggregation and census merge.csv
#
# This file does the following:
#
# 1. Loads intermediate data: data output/6. Aggregation and census merge.csv
# 2. Creates categorical variable for agency type
# 3. Calculates initial values for imputation
# 4. Saves output: data output/7. Initial Values.csv
#
# Libraries 
# install.packages("data.table")

library(data.table)

# **** Provide file path to the location of the github repository ****
origin = ""


#######################################################################################
# NOTE: This file calculates a set of initial values that are fed into the MI method. #
# Initial values can be thought of as best guesses at the missing values based on the #
# data we have.  The final imputed values will depart from the initial values, but		#
# the accuracy of those final imputed values will benefit from good initial guesses.	#
# We calculate initial values in one of three ways, depending on the available data:	#
#																																											#
# 	1. If an agency reports at least one month of data (but not all months, so that		#
# 		 the annual count is missing), we set the initial value for the annual count		#
#			 to be the average count from reported months multiplied by the reciprocal of		#
#			 the fraction of months where the agency reports. (i.e., we get an annual total #
#			 via extrapolation).																														#
#																																											#
# 	2. If an agency does not report any months, then we find all other agencies that	#
#			 fully report and have the same agency type and population grouping.  If there	#
#			 are at least four such agencies, we take the average annual count for those		#
#			 agencies to be the initial value.																							#
#																																											#
#		3. If an agency does not report any months and there are fewer than four agencies #
#			 with the same agency type and population grouping, we find all fully reporting	#
#			 agencies with just the same agency type, and take the average annual count for	#
#			 those agencies to be the initial value.																				#
#######################################################################################


#############################
# 1. Load intermediate data #
#############################

ucr = fread(paste0(origin, "/UCR-data-request/data output/6. Aggregation and census merge.csv"))


##################################################
# 2. Create categorical variable for agency type #
##################################################

ucr[,a.type := NA_character_]

ucr[type.local==1 ,a.type := "local"]
ucr[type.sheriff==1 ,a.type := "sheriff"]
ucr[type.state==1 ,a.type := "state"]
ucr[type.facilities==1 ,a.type := "facilities"]
ucr[type.transportation==1 ,a.type := "transportation"]
ucr[type.parks==1 ,a.type := "parks"]
ucr[type.criminal==1 ,a.type := "criminal"]


###############################################
# 3. Calculates initial values for imputation #
###############################################

# get variable names for annual crime and clearance totals (the things we're eventually imputing)
roots = c("murd", "mans", "rape", "robb", "agga", "burg", "larc", "vhct", "arso")
tot.vars=paste0(roots, ".tot")
clr.vars=paste0(roots, ".clr")
vars = c(tot.vars, clr.vars)

# create monthly aggravated assault counts -- these are needed to get initial values
for(i in 1:12){
	
	assa.tot.col = which(names(ucr) == paste0("assa.tot", i))
	assa.tot.vals = ucr[[assa.tot.col]]
	
	simp.tot.col = which(names(ucr) == paste0("simp.tot", i))
	simp.tot.vals = ucr[[simp.tot.col]]
	
	assa.clr.col = which(names(ucr) == paste0("assa.clr", i))
	assa.clr.vals = ucr[[assa.clr.col]]
	
	simp.clr.col = which(names(ucr) == paste0("simp.clr", i))
	simp.clr.vals = ucr[[simp.clr.col]]
	
	ucr[, paste0("agga.tot", i) := assa.tot.vals - simp.tot.vals]
	ucr[, paste0("agga.clr", i) := assa.clr.vals - simp.clr.vals]
	
}

# initiaize data.init
inits = data.table::copy(ucr)

# use setkey to speed up processing (a little, upcoming code takes a while...)
setkey(inits, a.type, pop.group)

# get initial values
for(i in 1:nrow(inits)){
	
	# loop through totals and clearances
	for(j in 1:length(vars)){
		
		# record variable and count
		var = vars[j]
		count = as.numeric(inits[i, ..var])
		
		# check to see if missing
		if( is.na(count) ){
			
			###################################################################
			# Attempt 1: initialize using months where the agency does report #
			###################################################################
			
			# get monthly cols
			monthly.cols = paste0(var, 1:12)
			
			# see if there's any reporting, and if so, multiply out
			num.reporting = sum(!is.na(inits[i, ..monthly.cols]))
			
			if(num.reporting > 0){
				
				sum.total = sum(inits[i, ..monthly.cols], na.rm=TRUE)
				init.val = round( sum.total * (12 / num.reporting) )
				inits[i, (var) := init.val]
				
			} else {
				
				######################################################
				# Attempt 2: find ucr of the same type and pop.group #
				######################################################
				
				# get pop group and type
				group = inits[i, pop.group]
				agency.type = inits[i, a.type]
				
				# get column associated with variable
				column = which(names(inits)==var)
				
				# get values for similar ucr that fully report
				similar.vals = na.omit( inits[.(agency.type, group)][[column]] )
				
				# if at least 4 such ucr, provide mean for init.val
				if( length(similar.vals)>=4 ){
					
					init.val = round( mean(similar.vals) )
					inits[i, (var) := init.val]
					
				} else {
					
					###########################################################
					# Attempt 3: use all fully reporting ucr of the same type #
					###########################################################
					
					similar.vals = na.omit( inits[agency.type][[column]] )
					init.val = round( mean(similar.vals) )
					inits[i, (var) := init.val]
					
					
				}
				
			}
			
		}
		
	}
	
	if(i%%1000==0){
		print(paste0(round(i / nrow(inits), digits=3) * 100, "% Complete"))
	}
	
}

# reorder rows in inits data.table to align with ucr data.table (using setkey reorders the data.table)
rows = match(ucr[, paste0(ori, year)], inits[, paste0(ori, year)])
inits = inits[rows]


##################
# 4. Save output #
##################

write.csv(x=inits, row.names=FALSE, file=paste0(origin, "/UCR-data-request/data output/7. Initial Values.csv"))