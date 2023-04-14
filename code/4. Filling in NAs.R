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


#####################
# 4. Filling in NAs #
#####################

# Data dependencies: 
# 
# 1. data output/3. Geocoding.csv
#
# This file does the following:
#
# 1. Loads intermediate data: data output/3. Geocoding.csv
# 2. Gets column indexes for CARD P/T columns, crime totals, and clearance totals
# 3. Fills in missing values
# 4. Saves output: /data output/4. Filling in NAs.csv
#
# Libraries 
# install.packages("data.table")
# install.packages("rlist")

library(data.table)
library(rlist)

# **** Provide file path to the location of the github repository ****
origin = ""


#############################
# 1. Load intermediate data #
#############################

ucr=fread(paste0(origin, "/UCR-data-request/data output/3. Geocoding.csv"))


##################################################################################
# 2. Get column indexes for CARD P/T columns, crime totals, and clearance totals #
##################################################################################

####################################################################################
# NOTE: Crime and clearance totals are stored as non-negative integers.  However,  #
# missing values are also stored as 0's.  Therefore, the number 0 can have two		 #
# different meanings: 0 total crimes (or clearances), or it can also mean "missing #
# value."  Other columns, which we call "CARD columns", indicate whether or not a  #
# value of 0 indicates a true zero count or a missing value.  For example,				 #
# variable V41 in the offenses known codebook indicates whether the total number	 #
# of offenses in January of the given year is missing (the label for this variable #
# is "JAN: CARD 1 P/T", hence why we call these the CARD variables).  These				 #
# variables are used to identify missing values.																	 #
####################################################################################

# get "card columns" for arson -- these columns tell us when arson ucr is missing
arson_tot_cards = which(grepl(names(ucr), pattern="arson_tot_card"))
arson_clr_cards = which(grepl(names(ucr), pattern="arson_clr_card"))

# get "card columns" for all other Part 1 crimes -- these columns tell us when all other Part 1 crimes are missing
other_tot_cards = which(grepl(names(ucr), pattern="other_tot_card"))
other_clr_cards = which(grepl(names(ucr), pattern="other_clr_card"))

# get columns for arson totals and clearances -- this is where we'll fill in NAs for missing arson ucr
arson_tot_cols = which(grepl(names(ucr), pattern="arso.tot"))
arson_clr_cols = which(grepl(names(ucr), pattern="arso.clr"))

# get total and clearance columns for all other crimes -- this is where we'll fill in NAs for other Part I offenses...

# ... first initialize lists to hold column numbers
other_tot_cols = list()
other_clr_cols = list()

# now a loop to fill in those lists of column numbers
for(i in 1:12){
	
	# we'll do a regex search to find monthly total and clearance columns
	tot.pattern = paste0( "(\\.tot", i, ")$")
	clr.pattern = paste0( "(\\.clr", i, ")$")
	
	# picking up those columns and storing in a list
	other_tot_cols = list.append(other_tot_cols, which(grepl(names(ucr), pattern=tot.pattern) & ! grepl(names(ucr), pattern="arso")))
	other_clr_cols = list.append(other_clr_cols, which(grepl(names(ucr), pattern=clr.pattern) & ! grepl(names(ucr), pattern="arso")))
	
}


#############################
# 3. Fill in missing values #
#############################

# Loop through rows in UCR and fill in missing values
for(i in 1:nrow(ucr)){
	
	for(j in 1:12){
		
		###########################
		# NAs for reported arsons #
		###########################
		
		# get card column and associated column of ucr
		c.col = arson_tot_cards[j]
		d.col = arson_tot_cols[j]
		
		# get card value
		c.val = ucr[i][[c.col]]
		
		# if card value is not "P" or "T" then set total arson to missing.
		if(! c.val %in% c("P", "T")){
			
			ucr[i, (d.col):=NA_integer_]
			
		}
		
		
		##########################
		# NAs for cleared arsons #
		##########################
		
		# get card column and associated column of ucr
		c.col = arson_clr_cards[j]
		d.col = arson_clr_cols[j]
		
		# get card value
		c.val = ucr[i][[c.col]]
		
		# if card value is not "P" or "T" then set total arson to missing.
		if(! c.val %in% c("P", "T")){
			
			ucr[i, (d.col):=NA_integer_]
			
		}
		
		
		############################################
		# NAs for reported crimes other than arson #
		############################################
		
		# get card column and associated columns of ucr
		c.col = other_tot_cards[j]
		d.cols = other_tot_cols[[j]]
		
		# get card value
		c.val = ucr[i][[c.col]]
		
		# if card value is not "P" or "T" then set total arson to missing.
		if(! c.val %in% c("P", "T")){
			
			ucr[i, (d.cols):=NA_integer_]
			
		}
		

		################################################
		# NAs for reported clearances other than arson #
		################################################
		
		# get card column and associated columns of ucr
		c.col = other_clr_cards[j]
		d.cols = other_clr_cols[[j]]
		
		# get card value
		c.val = ucr[i][[c.col]]
		
		# if card value is not "P" or "T" then set total arson to missing.
		if(! c.val %in% c("P", "T")){
			
			ucr[i, (d.cols):=NA_integer_]
			
		}
		
		
	}
	
	if(i%%1000==0)
		print(paste0(round(i / nrow(ucr), digits=3) * 100, "% Complete"))
	
}


######################################################
# 4. Save output: /data output/4. Filling in NAs.csv #
######################################################

write.csv(ucr, file=paste0(origin, "/UCR-data-request/data output/4. Filling in NAs.csv"), row.names=FALSE)