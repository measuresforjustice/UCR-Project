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
# 5. Historical agency imputation #
###################################

# Data dependencies: 
# 
# 1. data output/4. NAs Filled.csv
#
# This file does the following:
#
# 1. Loads intermediate data: data output/4. NAs Filled.csv
# 2. Uses historical agency data to impute missing values
# 3. Saves output
#
# Libraries 
# install.packages("data.table")

library(data.table)

# **** Provide file path to the location of the github repository ****
origin = ""


#############################
# 1. Load intermediate data #
#############################

ucr = fread(paste0(origin, "/UCR-data-request/data output/4. Filling in NAs.csv"))


####################################
# 2. Historical agency imputations #
####################################

#############################################################################################
# sampler(): this function returns the ORIs (Originating Agency Identifier) of all agencies #
# that are "covered by" another agency in the data.  Sometimes, crime and clearance counts	#
# for an agency are combined with the counts for another agency.  For example, in a small		#
# county, a local police department may have their counts combined with those of the county #
# sheriff, so that a single report is filed to the FBI by the sheriff's office.  In this		#
# case, we would say that the local agency is "covered by" the sheriff.  These occurrences	#
# are recorded by a variable in the offenses known data (V9 - COVERED BY CODE).  This				#
# information is important for the current imputation step, where we use crime and					#
# clearance counts from year (t - 1) to impute values in year t.  This step is accurate			#
# only insofar as the agencies accounted for in (t - 1) are the same as those in t.					#
#############################################################################################

sampler = function(agcy, yr, data=ucr){
	
	# get agencies it covers for
	covers.for = data[covered.by==agcy & year==yr, ori]
	
	# get agencies it's covered by
	covered.by = data[ori==agcy & year==yr, covered.by]
	if(is.na(covered.by[1]) | covered.by[1]==""){
		covered.by = character(0)
	}
	
	# initialize covering, which will ultimately grow
	covering = c(agcy, covers.for, covered.by)
	
	# get new agencies, if there are any
	new_agencies = setdiff(covering, agcy)
	
	if( length(new_agencies) == 0 ){
		
		# if the agcy is uncovered and does not cover for others, return agcy
		return(covering)
		
	} else {
		
		ticker=0
		
		while( length(new_agencies)!=0 ){
			
			if(ticker==0){
				new_covering = covering
			} else {
				covering = new_covering
			}
			
			# loop through new agencies and add onto covering
			for(i in 1:length(new_agencies)){
				
				# get new agency
				nagcy = new_agencies[i]
				
				# get agencies it covers for
				covers.for = data[covered.by==nagcy & year==yr, ori]
				
				# get agencies it's covered by
				covered.by = data[ori==nagcy & year==yr, covered.by]
				if(is.na(covered.by[1]) | covered.by[1]==""){
					covered.by = character(0)
				}
				
				# tack onto covering any agencies that were not there previously
				new_covering = unique(c(new_covering, covers.for, covered.by))
				
			}
			
			# get new agencies from this iteration
			new_agencies = setdiff(new_covering, covering)
			
			# update ticker
			ticker=ticker+1
			
		}
		
		# when the while loop ends, there are no new agencies.  return new_covering
		return(covering)
		
	}
	
}


########################################################################################
# gipper(): this is a function that finds the indexes of all columns whose column name #
# matches user specified regular expression.																					 #
########################################################################################

gipper = function(dat, pat){
	
	# get variable names
	names = names(dat)
	
	# search for pattern among variable names
	cols = which(grepl(names, pattern=pat))
	
	# return
	return(cols)
	
}


#####################################################################################
# The loop below imputes crime and clearance counts for agencies that do not report #
#	in the year X but DO report in years prior to X. The goal is to use this 					#
# historical information to help impute values in the current year. We mostly 			#
# follow the work laid out in "A Comparison of Imputation Methodologies in the			#
# Offenses-Known Crime Reports" (Targonski 2011). But see DeLang et al. (2022) for	#
# for departures from this approach.											 													#
#####################################################################################

# initialize values for loop
base_yr = 2010
same.cover=FALSE

# get crime roots
roots = unique(gsub(names(ucr)[which(grepl(names(ucr), pattern="\\.tot"))], pattern="(\\..*)$", replacement=""))

# impute crime and clearance counts using historical data
for(i in 1:nrow(ucr)){
	
	# no monthly imputations for the base year!  no previous year to look back on
	if(ucr[i, year] != base_yr){
		
		for(j in 1:length(roots)){
			
			# get root
			root = roots[j]
			
			
			#############################
			# First impute crime counts #
			#############################
			
			# pull values for index crime
			tot.cols = gipper(ucr, paste0(root, "\\.tot"))
			vals = as.integer(ucr[i, ..tot.cols])
			
			# count missing values
			na.months = which( is.na(vals) )
			na.count = length(na.months)
			
			# monthly imputations if the agency submits at least three months of data
			if( na.count >= 1 & na.count <= 9 ){
				
				# get agency and previous year
				agcy = ucr[i, ori]
				year.prev = ucr[i, year] - 1
				
				# check to see that the agency covers for the same agencies in both years, or that it does not 
				# cover.  If so, continue.  If not, do not impute (Rule 2, above).
				previous.cover = year.prev %in% ucr[covered.by == agcy, year]
				current.cover = (year.prev + 1) %in% ucr[covered.by == agcy, year]
				
				# If both were covering agencies, see if they covered for the same agencies
				if(previous.cover & current.cover){
					
					# use sampler function to get coverings for the previous and current year
					previous.covering = sampler(agcy=agcy, yr=year.prev)
					current.covering = sampler(agcy=agcy, yr=year.prev+1)
					
					# set same.cover
					same.cover = length(setdiff(previous.covering, current.covering)) == 0 &
						length(setdiff(current.covering, previous.covering)) == 0 &
						length(current.covering) > 0
					
				}
				
				# Case where the agency was not a covering agency for either the current or previous year, OR 
				# where it was a covering agency for both years and had the same covering.  These are the
				# circumstances in which we can use the previous year.
				if( (!previous.cover & !current.cover) | same.cover ){
					
					# pull up values from previous year
					vals.prev = as.integer(ucr[year==year.prev & ori==agcy, ..tot.cols])
					
					# compute change rate by comparing non-missing months in both years (follows Targonski, p. 47-48).
					# we will require at least four non-missing months in common to compute a change rate.  Otherwise
					# we'll mean impute using the current year.
					
					common.months = which( !is.na(vals) & !is.na(vals.prev) )
					
					if( length(common.months) >= 4 ){
						
						# compute change.rate if there are > 0 crimes in previous year.  otherwise, mean impute.
						if( sum(vals.prev[common.months]) == 0 ){
							
							# if the previous years have only zeroes, mean impute
							fill = round( mean(vals, na.rm=TRUE) )
							
							# get columns to fill
							cols = tot.cols[na.months]
							
							# impute!
							ucr[i, (cols) := fill]
							
						} else {
							
							change.rate = sum(vals[common.months]) / sum(vals.prev[common.months])
							
							# loop through missing months and apply change rate to previous year using the window approach.
							for(k in 1:length(na.months)){
								
								# get month
								month = na.months[k]
								
								# get column we're imputing into
								col = tot.cols[month]
								
								# get three month window from previous year.  if january is missing, use jan-mar and if 
								# december is missing use oct-dec.  this can be improved, time is continuous.  
								if(month == 1){
									window = vals.prev[1:3]
								} else {
									if(month == 12){
										window = vals.prev[10:12]
									} else {
										window = vals.prev[(month - 1):(month + 1)]
									}
								}
								
								# if at least one month in this three-month window is available, use change rate approach.  
								# Otherwise mean impute using current year
								
								if( sum(is.na(window)) < 3 ){
									
									# calculate the window mean
									fill = round( mean(window, na.rm=TRUE) * change.rate)
									
								} else {
									
									# calculate current year mean for available ucr
									fill = round( mean(vals, na.rm=TRUE) )
									
								}
								
								# impute!
								ucr[i, (col) := fill]
								
							}
							
							
						}
						
						
					} else {
						
						# if fewer than 4 months in common, mean impute using current year
						fill = round( mean(vals, na.rm=TRUE) )
						
						# get columns to fill
						cols = tot.cols[na.months]
						
						# impute!
						ucr[i, (cols) := fill]
						
					}
					
					
				} else {
					
					# if the coverings are different, the best we can do is mean impute for the current year.
					fill = round( mean(vals, na.rm=TRUE) )
					
					# get columns to fill
					cols = tot.cols[na.months]
					
					# impute!
					ucr[i, (cols) := fill]
					
				}
				
			}
			
			
			###############################
			# Now impute clearance counts #
			###############################
			
			# pull values for index crime
			clr.cols = gipper(ucr, paste0(root, "\\.clr"))
			vals = as.integer(ucr[i, ..clr.cols])
			
			# count missing values
			na.months = which( is.na(vals) )
			na.count = length(na.months)
			
			# monthly imputations if the agency submits at least three months of data
			if( na.count >= 1 & na.count <= 9 ){
				
				# get agency and previous year
				agcy = ucr[i, ori]
				year.prev = ucr[i, year] - 1
				
				# check to see that the agency covers for the same agencies in both years, or that it does not 
				# cover.  If so, continue.  If not, do not impute (Rule 2, above).
				previous.cover = year.prev %in% ucr[covered.by == agcy, year]
				current.cover = (year.prev + 1) %in% ucr[covered.by == agcy, year]
				
				# If both were covering agencies, see if they covered for the same agencies
				if(previous.cover & current.cover){
					
					# use sampler function to get coverings for the previous and current year
					previous.covering = sampler(agcy=agcy, yr=year.prev)
					current.covering = sampler(agcy=agcy, yr=year.prev+1)
					
					# set same.cover
					same.cover = length(setdiff(previous.covering, current.covering)) == 0 &
						length(setdiff(current.covering, previous.covering)) == 0 &
						length(current.covering) > 0
					
				}
				
				# Case where the agency was not a covering agency for either the current or previous year, OR 
				# where it was a covering agency for both years and had the same covering.  These are the
				# circumstances in which we can use the previous year.
				if( (!previous.cover & !current.cover) | same.cover ){
					
					# pull up values from previous year
					vals.prev = as.integer(ucr[year==year.prev & ori==agcy, ..clr.cols])
					
					# compute change rate by comparing non-missing months in both years (follows Targonski, p. 47-48).
					# we will require at least four non-missing months in common to compute a change rate.  Otherwise
					# we'll mean impute using the current year.
					
					common.months = which( !is.na(vals) & !is.na(vals.prev) )
					
					if( length(common.months) >= 4 ){
						
						# compute change.rate if there are > 0 crimes in previous year.  otherwise, mean impute.
						if( sum(vals.prev[common.months]) == 0 ){
							
							# if the previous years have only zeroes, mean impute
							fill = round( mean(vals, na.rm=TRUE) )
							
							# get columns to fill
							cols = clr.cols[na.months]
							
							# impute!
							ucr[i, (cols) := fill]
							
						} else {
							
							change.rate = sum(vals[common.months]) / sum(vals.prev[common.months])
							
							# loop through missing months and apply change rate to previous year using the window approach.
							for(k in 1:length(na.months)){
								
								# get month
								month = na.months[k]
								
								# get column we're imputing into
								col = clr.cols[month]
								
								# get three month window from previous year.  if january is missing, use jan-mar and if 
								# december is missing use oct-dec.  this can be improved, time is continuous.  
								if(month == 1){
									window = vals.prev[1:3]
								} else {
									if(month == 12){
										window = vals.prev[10:12]
									} else {
										window = vals.prev[(month - 1):(month + 1)]
									}
								}
								
								# if at least one month in this three-month window is available, use change rate approach.  
								# Otherwise mean impute using current year
								
								if( sum(is.na(window)) < 3 ){
									
									# calculate the window mean
									fill = round( mean(window, na.rm=TRUE) * change.rate)
									
								} else {
									
									# calculate current year mean for available ucr
									fill = round( mean(vals, na.rm=TRUE) )
									
								}
								
								# impute!
								ucr[i, (col) := fill]
								
							}
							
							
						}
						
						
					} else {
						
						# if fewer than 4 months in common, mean impute using current year
						fill = round( mean(vals, na.rm=TRUE) )
						
						# get columns to fill
						cols = clr.cols[na.months]
						
						# impute!
						ucr[i, (cols) := fill]
						
					}
					
					
				} else {
					
					# if the coverings are different, the best we can do is mean impute for the current year.
					fill = round( mean(vals, na.rm=TRUE) )
					
					# get columns to fill
					cols = clr.cols[na.months]
					
					# impute!
					ucr[i, (cols) := fill]
					
				}
				
			}
			
		}
		
	}
	
	# reset same.cover
	same.cover = FALSE
	
	if(i%%1000==0)
		print(paste0(round(i / nrow(ucr), digits=3) * 100, "% Complete"))
	
}


##################
# 3. Save output #
##################

write.csv(x=ucr, file=paste0(origin, "/UCR-data-request/data output/5. Historical agency imputation.csv"), row.names=FALSE)