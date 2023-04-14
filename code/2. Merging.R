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


################
# 2. Merging.R #
################

# Data dependencies: 
# 
# 1. data output/1a. Add variable names (2010).csv
# 2. data output/1b. Add variable names (2011).csv
# 3. data output/1c. Add variable names (2012).csv
# 4. data output/1d. Add variable names (2013).csv
# 5. data dependencies/UCR data/Arson (2010-2013)
# 6. data dependencies/UCR data/Agency identifiers crosswalk
# 7. data dependencies/Auxiliary data/Variable names.csv
#
# This file does the following:
#
# 1. Loads output data from previous step: 
#					- data output/1a. Add variable names (2010).csv
#					- data output/1b. Add variable names (2011).csv
#					- data output/1c. Add variable names (2012).csv
#					- data output/1d. Add variable names (2013).csv
# 2. Merges agency data from the Agency identifiers crosswalk into the Offenses Known data
# 3. Merges arson related offenses and arrests into the Offenses Known data
# 4. Combines yearly Offenses Known data into a single file
# 5. Creates agency type variables
# 6. Removes variables we don't need and assigns new variable names
# 7. Saves output: /data output/2. Merging.csv
#
#
# Libraries 
# install.packages("data.table")
# install.packages("bit64")

library(data.table)
library(bit64)

# **** Provide file path to the location of the github repository ****
origin = ""


#############################
# 1. Load intermediate data #
#############################

ucr2010=fread(paste0(origin, "/UCR-data-request/data output/1a. Add variable names (2010).csv"))
ucr2011=fread(paste0(origin, "/UCR-data-request/data output/1b. Add variable names (2011).csv"))
ucr2012=fread(paste0(origin, "/UCR-data-request/data output/1c. Add variable names (2012).csv"))
ucr2013=fread(paste0(origin, "/UCR-data-request/data output/1d. Add variable names (2013).csv"))


###########################################################################################
# 2. Merge agency data from the Agency identifiers crosswalk into the Offenses Known data #
###########################################################################################

# rename `ORI CODE` to ORI7 and coerce to a character vector so we can merge
names(ucr2010)[which(names(ucr2010)=="ORI CODE")]="ORI7"
ucr2010$ORI7=as.character(ucr2010$ORI7)

names(ucr2011)[which(names(ucr2011)=="ORI CODE")]="ORI7"
ucr2011$ORI7=as.character(ucr2011$ORI7)

names(ucr2012)[which(names(ucr2012)=="ORI CODE")]="ORI7"
ucr2012$ORI7=as.character(ucr2012$ORI7)

names(ucr2013)[which(names(ucr2013)=="ORI CODE")]="ORI7"
ucr2013$ORI7=as.character(ucr2013$ORI7)

# Load the crosswalk
crosswalk = fread(paste0(origin, "/UCR-data-request/data dependencies/UCR data/Agency identifiers crosswalk/ICPSR_35158/DS0001/35158-0001-Data.tsv"))

# turn fplace and fcounty into a character vector
crosswalk$FPLACE = as.character(crosswalk$FPLACE)
crosswalk$FCOUNTY = as.character(crosswalk$FCOUNTY)

# and merge
ucr2010=merge(ucr2010, crosswalk, by="ORI7", all.x=TRUE, sort=FALSE)
ucr2011=merge(ucr2011, crosswalk, by="ORI7", all.x=TRUE, sort=FALSE)
ucr2012=merge(ucr2012, crosswalk, by="ORI7", all.x=TRUE, sort=FALSE)
ucr2013=merge(ucr2013, crosswalk, by="ORI7", all.x=TRUE, sort=FALSE)


############################################################################
# 3. Merge arson related offenses and arrests into the Offenses Known data #
############################################################################

# load arson data 
arson10 = fread(paste0(origin, "/UCR-data-request/data dependencies/UCR data/Arson (2010-2013)/2010 (ICPSR_33528)/DS0001/33528-0001-Data.tsv"))
arson11 = fread(paste0(origin, "/UCR-data-request/data dependencies/UCR data/Arson (2010-2013)/2011 (ICPSR_34579)/DS0001/34579-0001-Data.tsv"))
arson12 = fread(paste0(origin, "/UCR-data-request/data dependencies/UCR data/Arson (2010-2013)/2012 (ICPSR_35016)/DS0001/35016-0001-Data.tsv"))
arson13 = fread(paste0(origin, "/UCR-data-request/data dependencies/UCR data/Arson (2010-2013)/2013 (ICPSR_36114)/DS0001/36114-0001-Data.tsv"))

# function that creates arson variable names
varson = function(start){
	nums = c(start, rep(NA, times=11))
	for(i in 2:12){
		nums[i] = nums[i-1] + 103
	}
	vars = paste0("V", nums)
}

# variables we need to label, including those we want to bring over from arson data
card_actual = varson(29)
card_clearances = varson(30)

actual_grand_total = varson(72)
cleared_grand_total = varson(85)

# label ORIs
names(arson10)[3]="ORI7"
names(arson11)[3]="ORI7"
names(arson12)[3]="ORI7"
names(arson13)[3]="ORI7"

# label actual grand totals
gt.cols = which(names(arson10) %in% actual_grand_total)
for(i in 1:length(gt.cols)){
	
	col = gt.cols[i]
	
	names(arson10)[col] = paste0("tot_arson", i)
	names(arson11)[col] = paste0("tot_arson", i)
	names(arson12)[col] = paste0("tot_arson", i)
	names(arson13)[col] = paste0("tot_arson", i)
	
}

# label cleared grand totals
clr.cols = which(names(arson10) %in% cleared_grand_total)
for(i in 1:length(clr.cols)){
	
	col = clr.cols[i]
	
	names(arson10)[col] = paste0("clr_arson", i)
	names(arson11)[col] = paste0("clr_arson", i)
	names(arson12)[col] = paste0("clr_arson", i)
	names(arson13)[col] = paste0("clr_arson", i)
	
}

# card variables used to identify missingness
card.actual.cols = which(names(arson10) %in% card_actual)
for(i in 1:length(card.actual.cols)){
	
	col = card.actual.cols[i]
	
	names(arson10)[col] = paste0("tot_card", i)
	names(arson11)[col] = paste0("tot_card", i)
	names(arson12)[col] = paste0("tot_card", i)
	names(arson13)[col] = paste0("tot_card", i)
	
}

card.clearance.cols = which(names(arson10) %in% card_clearances)
for(i in 1:length(card.clearance.cols)){
	
	col = card.clearance.cols[i]
	
	names(arson10)[col] = paste0("clr_card", i)
	names(arson11)[col] = paste0("clr_card", i)
	names(arson12)[col] = paste0("clr_card", i)
	names(arson13)[col] = paste0("clr_card", i)
	
}

# empty out unwanted variables
cols = which(grepl(names(arson10), pattern="^V"))

arson10[, (cols):=NULL]
arson11[, (cols):=NULL]
arson12[, (cols):=NULL]
arson13[, (cols):=NULL]

# merge data
ucr2010=merge(ucr2010, arson10, by="ORI7", all.x=TRUE, sort=FALSE)
ucr2011=merge(ucr2011, arson11, by="ORI7", all.x=TRUE, sort=FALSE)
ucr2012=merge(ucr2012, arson12, by="ORI7", all.x=TRUE, sort=FALSE)
ucr2013=merge(ucr2013, arson13, by="ORI7", all.x=TRUE, sort=FALSE)


############################################################
# 4. Combine yearly Offenses Known data into a single file #
############################################################

ucr=rbind(ucr2010, ucr2011, ucr2012, ucr2013)


##################################
# 5. Create agency type variable #
##################################

type.vars = paste0("type.", c("local", "sheriff", "state", "marshal", "facilities", "parks", "transportation", "criminal", "special"))

# loop to create variables and fill them in
for(i in 1:length(type.vars)){
	
	type = type.vars[i]
	
	# create variable
	ucr[, (type):=0]

	# fill in
	if(type=="type.local"){
		ucr[AGCYTYPE==0, (type):=1]
	}
	
	if(type=="type.sheriff"){
		ucr[AGCYTYPE==1, (type):=1]
	}
	
	if(type=="type.state"){
		ucr[AGCYTYPE==5, (type):=1]
	}
	
	if(type=="type.marshal"){
		ucr[AGCYTYPE==7, (type):=1]
	}
	
	if(type=="type.facilities"){
		ucr[SUBTYPE1==1, (type):=1]
	}
	
	if(type=="type.parks"){
		ucr[SUBTYPE1==2, (type):=1]
	}
	
	if(type=="type.transportation"){
		ucr[SUBTYPE1==3, (type):=1]
	}
	
	if(type=="type.criminal"){
		ucr[SUBTYPE1==4, (type):=1]
	}
	
	if(type=="type.special"){
		ucr[SUBTYPE1==5, (type):=1]
	}
	
}

# account for missing agency type.  First get ORIs where agency type is missing.
missing.oris = unique(ucr[AGCYTYPE==997, ORI7])

ucr[ORI7==missing.oris[1], type.transportation:=1]
ucr[ORI7==missing.oris[2], type.special:=1]
ucr[ORI7==missing.oris[3], type.parks:=1]
ucr[ORI7==missing.oris[4], type.transportation:=1]
ucr[ORI7==missing.oris[5], type.facilities:=1]
ucr[ORI7==missing.oris[6], type.facilities:=1]
ucr[ORI7==missing.oris[7], type.local:=1]


###################################################################
# 6. Remove variables we don't need and assign new variable names #
###################################################################

# Load Variable names.csv from Auxiliary data
varnames=fread(paste0(origin, "/UCR-data-request/data dependencies/Auxiliary data/Variable names.csv"))

# Remove columns from UCR that we do not need
cols = intersect(names(ucr), varnames$orig)
ucr = ucr[, ..cols]

# Loop to reassign variable names
for(i in 1:nrow(varnames)){
	
	# get original and new
	orig = varnames$orig[i]
	new = varnames$new[i]
	
	# find column in ucr
	col = which(names(ucr) == orig)
	
	if(length(col)==1){
		
		# rename column
		names(ucr)[col] = new
		
	} else {
		
		print(orig)
		
	}
	
	
}

# re-order variables as they appear in Variable names.csv
setcolorder(ucr, varnames$new)


################################################
# 7. Saves output: /data output/2. Merging.csv #
################################################

write.csv(x=ucr, file=paste0(origin, "/UCR-data-request/data output/2. Merging.csv"), row.names=FALSE)