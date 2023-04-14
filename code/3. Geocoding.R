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


##################
# 3. Geocoding.R #
##################

# Data dependencies: 
# 
# 1. data output/2. Merging.csv
# 2. data dependencies/Auxiliary data/Geocodes.csv
# 3. data dependencies/Auxiliary data/New agencies.csv
# 4. data dependencies/Auxiliary data/Fbi2fips.csv
# 5. data dependencies/Auxiliary data/Census.csv
# 6. data dependencies/UCR data/Agency identifiers crosswalk
#
# This file does the following:
#
# 1. Loads intermediate data: data output/2. Merging.csv
# 2. Supplements information for agencies that are missing from the crosswalk 
# 3. Removes agencies from US territories and tribal lands
# 4. Obtains valid county FIPS for each agency
# 5. Obtains valid place FIPS for local law enforcement and other local agencies
# 6. Final check that all FIPS codes are in census
# 7. Saves output: /data output/3. Geocoding.csv
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

# intermediate file after 2. Merging.R
ucr = fread(paste0(origin, "/UCR-data-request/data output/2. Merging.csv"))


###############################################################################
# 2. Supplements information for agencies that are missing from the crosswalk #
###############################################################################

################################################################################################
# NOTE: In the previous R script, we merged the Agency identifiers crosswalk into the Offenses #
# Known data. The crosswalk provides state, county, and place FIPS codes for agencies, which   #
# we use for geocoding and ultimately for merging in census data. Because the crosswalk was 	 #
# last updated in 2012, all newly established agencies in 2013 do not appear there.  Several	 #
# agencies established prior to 2013 are also missing from the crosswalk.  For each of these,  #
# we did our own research to identify FIPS codes for each agency.  This section fills in the	 #
# missing FIPS codes (as well as agency type) with the information obtained in our research.	 # 
################################################################################################

# load geocodes from census -- we will use this later
geocodes = fread(paste0(origin, "/UCR-data-request/data dependencies/Auxiliary data/Geocodes.csv"))

# first turn fcounty and fplace into character vectors
ucr$fcounty=as.character(ucr$fcounty)
ucr$fplace=as.character(ucr$fplace)

# Newark City, AR
ucr[ori=="AR03203", state.name:="ARKANSAS"]
ucr[ori=="AR03203", fstate:=5]
ucr[ori=="AR03203", county.name:="INDEPENDENCE"]
ucr[ori=="AR03203", fcounty:="63"]
ucr[ori=="AR03203", fplace:="49010"]
ucr[ori=="AR03203", type.local:=1]

# Butte County, CA
ucr[ori=="CA00411", state.name:="CALIFORNIA"]
ucr[ori=="CA00411", fstate:=6]
ucr[ori=="CA00411", county.name:="BUTTE"]
ucr[ori=="CA00411", fcounty:="7"]
ucr[ori=="CA00411", fplace:=NA_character_]
ucr[ori=="CA00411", type.transportation:=1]

# Marin County, CA
ucr[ori=="CA02116", state.name:="CALIFORNIA"]
ucr[ori=="CA02116", fstate:=6]
ucr[ori=="CA02116", county.name:="MARIN"]
ucr[ori=="CA02116", fcounty:="41"]
ucr[ori=="CA02116", fplace:=NA_character_]
ucr[ori=="CA02116", type.transportation:=1]
	
# American Canyon, CA
ucr[ori=="CA02809", state.name:="CALIFORNIA"]
ucr[ori=="CA02809", fstate:=6]
ucr[ori=="CA02809", county.name:="NAPA"]
ucr[ori=="CA02809", fcounty:="55"]
ucr[ori=="CA02809", fplace:="1640"]
ucr[ori=="CA02809", type.local:=1]

# Sacramento County, CA
ucr[ori=="CA03499", state.name:="CALIFORNIA"]
ucr[ori=="CA03499", fstate:=6]
ucr[ori=="CA03499", county.name:="SACRAMENTO"]
ucr[ori=="CA03499", fcounty:="67"]
ucr[ori=="CA03499", fplace:=NA_character_]
ucr[ori=="CA03499", type.state:=1]

# San Diego County, CA
ucr[ori=="CA03718", state.name:="CALIFORNIA"]
ucr[ori=="CA03718", fstate:=6]
ucr[ori=="CA03718", county.name:="SAN DIEGO"]
ucr[ori=="CA03718", fcounty:="73"]
ucr[ori=="CA03718", fplace:=NA_character_]
ucr[ori=="CA03718", type.transportation:=1]

# Buellton, CA
ucr[ori=="CA04212", state.name:="CALIFORNIA"]
ucr[ori=="CA04212", fstate:=6]
ucr[ori=="CA04212", county.name:="SANTA BARBARA"]
ucr[ori=="CA04212", fcounty:="83"]
ucr[ori=="CA04212", fplace:="8758"]
ucr[ori=="CA04212", type.local:=1]

# District of Colombia -- United States Park Police
ucr[ori=="DCPPD00", state.name:="DISTRICT OF COLUMBIA"]
ucr[ori=="DCPPD00", fstate:=11]
ucr[ori=="DCPPD00", county.name:="DISTRICT OF COLUMBIA"]
ucr[ori=="DCPPD00", fcounty:="1"]
ucr[ori=="DCPPD00", fplace:=NA_character_]
ucr[ori=="DCPPD00", type.parks:=1]

# Unknown: US CUST SERV SECT COMM
ucr[ori=="FL01380", state.name:="FLORIDA"]
ucr[ori=="FL01380", fstate:=12]
ucr[ori=="FL01380", county.name:="MIAMI-DADE"]
ucr[ori=="FL01380", fcounty:="86"]
ucr[ori=="FL01380", fplace:=NA_character_]
ucr[ori=="FL01380", type.parks:=1]

# Unknown: EAST CENTRAL ILL TASD FO
ucr[ori=="IL01508", state.name:="ILLINOIS"]
ucr[ori=="IL01508", fstate:=17]
ucr[ori=="IL01508", county.name:="COLES; DOUGLAS; MOULTRIE; SHELBY"]
ucr[ori=="IL01508", fcounty:="29; 41; 139; 173"]
ucr[ori=="IL01508", fplace:=NA_character_]
ucr[ori=="IL01508", type.parks:=1]

# Unknown: S SP: AUTO THEFT  DIST 5
ucr[ori=="IL10119", state.name:="ILLINOIS"]
ucr[ori=="IL10119", fstate:=17]
ucr[ori=="IL10119", county.name:="WINNEBAGO; BOONE"]
ucr[ori=="IL10119", fcounty:="201; 7"]
ucr[ori=="IL10119", fplace:=NA_character_]
ucr[ori=="IL10119", type.criminal:=1]

# Lexington, KY
kentucky = geocodes[state==21 & county!=0 & county_subdivision==0 & consolidated_city==0]
ky_counties = paste(kentucky$county, collapse="; ")
county.names = paste(toupper(gsub(kentucky$area_name, pattern="( County)$", replacement="")), collapse="; ")

ucr[ori=="KYUSM02", state.name:="KENTUCKY"]
ucr[ori=="KYUSM02", fstate:=21]
ucr[ori=="KYUSM02", county.name:=county.names]
ucr[ori=="KYUSM02", fcounty:=ky_counties]
ucr[ori=="KYUSM02", fplace:=NA_character_]
ucr[ori=="KYUSM02", type.parks:=1]

# Unknown: KENTUCKY DAM
ucr[ori=="KY07002", state.name:="KENTUCKY"]
ucr[ori=="KY07002", fstate:=21]
ucr[ori=="KY07002", county.name:="LIVINGSTON"]
ucr[ori=="KY07002", fcounty:="139"]
ucr[ori=="KY07002", fplace:="32212"]
ucr[ori=="KY07002", type.facilities:=1]

# Warren County, KY
ucr[ori=="KY11405", state.name:="KENTUCKY"]
ucr[ori=="KY11405", fstate:=21]
ucr[ori=="KY11405", county.name:="WARREN"]
ucr[ori=="KY11405", fcounty:="227"]
ucr[ori=="KY11405", fplace:=NA_character_]
ucr[ori=="KY11405", type.parks:=1]

# Silver Bow County, MT
ucr[ori=="MT04700", state.name:="MONTANA"]
ucr[ori=="MT04700", fstate:=30]
ucr[ori=="MT04700", county.name:="SILVER BOW"]
ucr[ori=="MT04700", fcounty:="93"]
ucr[ori=="MT04700", fplace:=NA_character_]
ucr[ori=="MT04700", type.sheriff:=1]


# Unknown: DTF:7TH JUDICIAL DISTRIC
ucr[ori=="TN00106", state.name:="TENNESSEE"]
ucr[ori=="TN00106", fstate:=47]
ucr[ori=="TN00106", county.name:="ANDERSON"]
ucr[ori=="TN00106", fcounty:="1"]
ucr[ori=="TN00106", fplace:=NA_character_]
ucr[ori=="TN00106", type.parks:=1]

# Unknown: SOUTHEAST MO DRUG TASK F
ucr[ori=="MO10111", state.name:="MISSOURI"]
ucr[ori=="MO10111", fstate:=29]
ucr[ori=="MO10111", county.name:="Bollinger; Butler; Cape Girardeau; Mississippi; New Madrid; Perry; Ripley; Scott; Stoddard; Wayne"]
ucr[ori=="MO10111", fcounty:="17; 23; 31; 133; 143; 157; 181; 201; 207; 223"]
ucr[ori=="MO10111", fplace:=NA_character_]
ucr[ori=="MO10111", type.parks:=1]

# Unknown: FORT BERTHOLD TRIBAL
ucr[ori=="NDDI004", state.name:="NORTH DAKOTA"]
ucr[ori=="NDDI004", fstate:=38]
ucr[ori=="NDDI004", county.name:="Mountrail"]
ucr[ori=="NDDI004", fcounty:="61"]
ucr[ori=="NDDI004", fplace:="56740"]
ucr[ori=="NDDI004", type.local:=1]

# Unknown: ROBINSON RANCHERIA TRBL
ucr[ori=="CADIT07", state.name:="CALIFORNIA"]
ucr[ori=="CADIT07", fstate:=6]
ucr[ori=="CADIT07", county.name:="LAKE"]
ucr[ori=="CADIT07", fcounty:="33"]
ucr[ori=="CADIT07", fplace:=NA_character_]
ucr[ori=="CADIT07", type.local:=1]

# Unknown: CENTRAL AL DRUG TASK FOR
ucr[ori=="AL02907", state.name:="ALABAMA"]
ucr[ori=="AL02907", fstate:=1]
ucr[ori=="AL02907", county.name:="ELMORE"]
ucr[ori=="AL02907", fcounty:="51"]
ucr[ori=="AL02907", fplace:=NA_character_]
ucr[ori=="AL02907", type.parks:=1]

# Lawrence County, AL
ucr[ori=="AL04206", state.name:="ALABAMA"]
ucr[ori=="AL04206", fstate:=1]
ucr[ori=="AL04206", county.name:="LAWRENCE"]
ucr[ori=="AL04206", fcounty:="79"]
ucr[ori=="AL04206", fplace:=NA_character_]
ucr[ori=="AL04206", type.parks:=1]

# Marion County, AL
ucr[ori=="AL04908", state.name:="ALABAMA"]
ucr[ori=="AL04908", fstate:=1]
ucr[ori=="AL04908", county.name:="MARION"]
ucr[ori=="AL04908", fcounty:="93"]
ucr[ori=="AL04908", fplace:=NA_character_]
ucr[ori=="AL04908", type.parks:=1]

# Unknown: SOUTH METRO DRUG TASK FO
ucr[ori=="CO00381", state.name:="COLORADO"]
ucr[ori=="CO00381", fstate:=8]
ucr[ori=="CO00381", county.name:="Arapahoe; Douglas; Elbert"]
ucr[ori=="CO00381", fcounty:="5; 35; 39"]
ucr[ori=="CO00381", fplace:=NA_character_]
ucr[ori=="CO00381", type.parks:=1]

# Unknown: FOND DU LAC TRIBAL
ucr[ori=="MNDI070", state.name:="MISSOURI"]
ucr[ori=="MNDI070", fstate:=27]
ucr[ori=="MNDI070", county.name:="CARLTON"]
ucr[ori=="MNDI070", fcounty:="17"]
ucr[ori=="MNDI070", fplace:=NA_character_]
ucr[ori=="MNDI070", type.local:=1]

# Unknown: DPT AGRIC FRSTRY SRV LES
oklahoma = geocodes[state==40 & county!=0 & county_subdivision==0 & consolidated_city==0]
ok_counties = paste(oklahoma$county, collapse="; ")
county.names = paste(gsub(x=oklahoma[, area_name], pattern="( County)$", replacement=""), collapse="; ")

ucr[ori=="OK05533", state.name:="OKLAHOMA"]
ucr[ori=="OK05533", fstate:=40]
ucr[ori=="OK05533", county.name:=county.names]
ucr[ori=="OK05533", fcounty:=ok_counties]
ucr[ori=="OK05533", fplace:=NA_character_]
ucr[ori=="OK05533", type.parks:=1]

# Washington Gambling Commission
washington = geocodes[state==53 & county!=0 & county_subdivision==0 & consolidated_city==0]
wa_counties = paste(washington$county, collapse="; ")
county.names = paste(gsub(x=washington[, area_name], pattern="( County)$", replacement=""), collapse="; ")

# fill them in
ucr[ori=="WA03410", state.name:="WASHINGNTON"]
ucr[ori=="WA03410", fstate:=53]
ucr[ori=="WA03410", county.name:=county.names]
ucr[ori=="WA03410", fcounty:=wa_counties]
ucr[ori=="WA03410", fplace:=NA_character_]
ucr[ori=="WA03410", type.parks:=1]

# Now load auxiliary data with agency info for newly established 2013 agencies
extras = fread(paste0(origin, "/UCR-data-request/data dependencies/Auxiliary data/New agencies.csv"))

# loop through and apply information from these new agencies to the Offenses Known data
for(i in 1:nrow(extras)){
	
	# record ori
	agcy = extras$ORI7[i]
	
	# fill in variables except for agency type variable
	ucr[ori==agcy, state.name:=extras$STATENAME[i]]
	ucr[ori==agcy, fstate:=extras$FIPS_ST[i]]
	ucr[ori==agcy, county.name:=extras$COUNTYNAME[i]]
	ucr[ori==agcy, fcounty:=extras$FCOUNTY[i]]
	ucr[ori==agcy, fplace:=extras$FPLACE[i]]

	# fill in agency type variable	
	agcytype = extras[i, AGCYTYPE]
	subtype1 = extras[i, SUBTYPE1]
	
	if(!is.na(agcytype)){
		
		if(agcytype!=6){
			
			# local
			if(agcytype==0){
				ucr[ori==agcy, type.local:=1]
			}
			
			# sheriff
			if(agcytype==1){
				ucr[ori==agcy, type.sheriff:=1]
			}
			
			# state
			if(agcytype==5){
				ucr[ori==agcy, type.state:=1]
			}
			
			
		} else {
			
			if(!is.na(subtype1)){
				
				# facilities
				if(subtype1 == 1){
					ucr[ori==agcy, type.facilities:=1]
				}
				
				# parks
				if(subtype1 == 2){
					ucr[ori==agcy, type.parks:=1]
				}
				
				# transportationn
				if(subtype1 == 3){
					ucr[ori==agcy, type.transportation:=1]
				}
				
				# criminal
				if(subtype1 == 4){
					ucr[ori==agcy, type.criminal:=1]
				}
				
				# special
				if(subtype1 == 5){
					ucr[ori==agcy, type.parks:=1]
				}
				
				
			}
			
		}
		
	}

}


###########################################################
# 3. Remove agencies from US territories and tribal lands #
###########################################################

# All agencies still missing county FIPS (fcounty) are either tribal police, agencies in US territories, 
# or a duplicate record of the SD highway patrol.

ucr = ucr[!is.na(ucr$fcounty)]

# remove other tribal police agencies
rows = which( (grepl(ucr$ori, pattern="IDI|DDI") & ucr$state.name!="IDAHO") |
								grepl(ucr$agency, pattern="TRIBAL|TRIBL|TRBL|INDIAN TWP|INDIAN TWN|INDIAN PD|SAN ILDEFONSO PUEBLO|AKWESASNE", ignore.case=TRUE) |
								ucr$ori %in% c("ME01512", "MT02102", "MT02405", "NM01904", "FL00634", "FL02603"))

ucr=ucr[-rows]


###############################################
# 4. Obtain valid county FIPS for each agency #
###############################################

#################################################################################################
# NOTE: The Offenses Known data has county codes built in, but rather than FIPS codes, they're	#
# FBI county codes.  We use the file "Fbi2fips.csv" (in Auxiliary data) to convert FBI codes to	#
# FIPS codes.  Then, for any agencies still missing FIPS codes, we supplement with FIPS codes		#
# from the Agency identifiers crosswalk (fcounty).																							#
#################################################################################################

# load Fbi2fips.csv
fbi2fips = fread(paste0(origin, "/UCR-data-request/data dependencies/Auxiliary data/Fbi2fips.csv"))

# turn codes into character vectors
fbi2fips$fbi_county=as.character(fbi2fips$fbi_county)
fbi2fips$fips_county=as.character(fbi2fips$fips_county)
fbi2fips$fstate=as.character(fbi2fips$fstate)

# create a geoid_fbi
rows = which(nchar(fbi2fips$fbi_county)==1)
fbi2fips[rows, geoid_fbi:=paste0(fstate, "00", fbi_county)]

rows = which(nchar(fbi2fips$fbi_county)==2)
fbi2fips[rows, geoid_fbi:=paste0(fstate, "0", fbi_county)]

rows = which(nchar(fbi2fips$fbi_county)==3)
fbi2fips[rows, geoid_fbi:=paste0(fstate, fbi_county)]

# create a geoid_fips
rows = which(nchar(fbi2fips$fips_county)==1)
fbi2fips[rows, geoid_fips:=paste0(fstate, "00", fips_county)]

rows = which(nchar(fbi2fips$fips_county)==2)
fbi2fips[rows, geoid_fips:=paste0(fstate, "0", fips_county)]

rows = which(nchar(fbi2fips$fips_county)==3)
fbi2fips[rows, geoid_fips:=paste0(fstate, fips_county)]

# similarly for ucr
ucr$county1=as.character(ucr$county1)
ucr$county2=as.character(ucr$county2)
ucr$county3=as.character(ucr$county3)

# first for county1
rows = which(nchar(ucr$county1)==1 & !is.na(ucr$county1) & !is.na(ucr$fstate))
ucr[rows, county1:=paste0(fstate, "00", county1)]

rows = which(nchar(ucr$county1)==2 & !is.na(ucr$county1) & !is.na(ucr$fstate))
ucr[rows, county1:=paste0(fstate, "0", county1)]

rows = which(nchar(ucr$county1)==3 & !is.na(ucr$county1) & !is.na(ucr$fstate))
ucr[rows, county1:=paste0(fstate, county1)]

# first for county2
rows = which(nchar(ucr$county2)==1 & !is.na(ucr$county2) & !is.na(ucr$fstate))
ucr[rows, county2:=paste0(fstate, "00", county2)]

rows = which(nchar(ucr$county2)==2 & !is.na(ucr$county2) & !is.na(ucr$fstate))
ucr[rows, county2:=paste0(fstate, "0", county2)]

rows = which(nchar(ucr$county2)==3 & !is.na(ucr$county2) & !is.na(ucr$fstate))
ucr[rows, county2:=paste0(fstate, county2)]

# first for county3
rows = which(nchar(ucr$county3)==1 & !is.na(ucr$county3) & !is.na(ucr$fstate))
ucr[rows, county3:=paste0(fstate, "00", county3)]

rows = which(nchar(ucr$county3)==2 & !is.na(ucr$county3) & !is.na(ucr$fstate))
ucr[rows, county3:=paste0(fstate, "0", county3)]

rows = which(nchar(ucr$county3)==3 & !is.na(ucr$county3) & !is.na(ucr$fstate))
ucr[rows, county3:=paste0(fstate, county3)]

# get all unique fbi county codes
fbi_codes = unique(c(ucr[!is.na(county1), county1], ucr[!is.na(county2), county2], ucr[!is.na(county3), county3]))

# initialize new county1, county2, county3
ucr$county1_fips=NA_character_
ucr$county2_fips=NA_character_
ucr$county3_fips=NA_character_

# First, convert FBI codes to FIPS codes for agencies with jurisdiction in one county
for(i in 1:length(fbi_codes)){
	
	# get code
	code = fbi_codes[i]
	
	# get fips version
	fips_code = fbi2fips[geoid_fbi==code, geoid_fips]
	
	# if fips version exists, try to fill in
	if(length(fips_code)>0){
		
		# find rows where this code appears in county1, county2, and county3, and also where we havent' found cross-county jurisdiction
		# in our manual searches.
		rows1 = which(ucr$county1==code & !grepl(ucr$fcounty, pattern=";"))
		rows2 = which(ucr$county2==code & !grepl(ucr$fcounty, pattern=";"))
		rows3 = which(ucr$county3==code & !grepl(ucr$fcounty, pattern=";"))
		
		# get associated fips values and fill in
		if(length(rows1)>0){
			
			# store in ucr
			ucr[rows1, county1_fips:=fips_code]
			
		}
		if(length(rows2)>0){
			
			# store in ucr
			ucr[rows2, county2_fips:=fips_code]
			
		}
		if(length(rows3)>0){
			
			# store in ucr
			ucr[rows3, county3_fips:=fips_code]
			
		}
		
		
	}
	
	
	if(i%%1000==0)
		print(paste0(round(i / length(fbi_codes), digits=3) * 100, "% Complete"))
	
}

# NEXT, convert FBI codes to FIPS codes for agencies with jurisdiction in multiple counties.

# first, turn fcounty into a geoid
rows1 = which(nchar(ucr$fcounty)==1)
ucr[rows1, fcounty:=paste0(fstate, "00", fcounty)]

rows2 = which(nchar(ucr$fcounty)==2)
ucr[rows2, fcounty:=paste0(fstate, "0", fcounty)]

rows3 = which(nchar(ucr$fcounty)==3)
ucr[rows3, fcounty:=paste0(fstate, fcounty)]

# loop through rows with multiple fcounties and turn them into geoids.
rows = which(grepl(ucr$fcounty, pattern=";"))

for(i in rows){
	
	# get fstate
	fst = ucr[i, fstate]
	
	# get fcounties
	fcs = ucr[i, fcounty]
	
	# string split and unlist
	fcs = unlist(str_split(fcs, pattern="; "))
	
	# replace each with geoid
	ones = which(nchar(fcs)==1)
	twos = which(nchar(fcs)==2)
	threes = which(nchar(fcs)==3)
	
	if(length(ones)>0){
		fcs[ones] = paste0(fst, "00", fcs[ones])
	}

	if(length(twos)>0){
		fcs[twos] = paste0(fst, "0", fcs[twos])
	}
	
	if(length(threes)>0){
		fcs[threes] = paste0(fst, fcs[threes])
	}
	
	# collapse with semicolons
	fcs = paste(fcs, collapse = "; ")
	
	# place back into fcounty
	ucr[i, fcounty:=fcs]
	
}

# MIAMI-DADE correction -- their fips changed after 1996, and the new fips is in cda.
ucr[county1_fips=="12025", county1_fips:="12086"]
ucr[county2_fips=="12025", county2_fips:="12086"]
ucr[county3_fips=="12025", county3_fips:="12086"]

# Finally, substitute fcounty where county1_fips is missing
ucr[is.na(county1_fips), county1_fips:=fcounty]


#################################################################################
# 5. Obtain valid place FIPS for local law enforcement and other local agencies #
#################################################################################

# First handle agencies with jurisdiction in multiple census places... we can identify such agencies
# because they're indicated in the COMMENT variable in the Agency identifiers crosswalk.

# load agency identifiers crosswalk
crosswalk = fread(paste0(origin, "/UCR-data-request/data dependencies/UCR data/Agency identifiers crosswalk/ICPSR_35158/DS0001/35158-0001-Data.tsv"))

# multi-place jurisdiction occurs for agencies with vertical bars in the comment field
comments = crosswalk$COMMENT[grepl(crosswalk$COMMENT, pattern="\\|")]

# note that the number of fplaces drawn from each row should be one more than the number of vertical bars.
bar_count = str_count(comments, pattern="\\|")

# extract all digit strings
q=str_extract_all(comments, pattern="[0-9]+")

# loop through q and keep only those with five digits
for(i in 1:length(q)){
	
	keep=which(stringr::str_count(q[[i]])==5)
	q[[i]] = q[[i]][keep]
	
}

# CORRECTION: The place code for Caspian, Michigan is 13860.
q[[18]][2] = "13860"

# now let's tack these onto fplace. First get ORIs for these multiples.
ori_mults = crosswalk$ORI7[grepl(crosswalk$COMMENT, pattern="\\|")]

# now loop through these mults and append
for(i in 1:length(ori_mults)){
	
	if(ori_mults[i] != "-1"){
		
		ucr[ ori == ori_mults[i], fplace:=paste(q[[i]], collapse="; ") ]
		
	}
	
}


# Now we handle agencies with jurisdiction in a single census place

# add zeroes to ucr place fips
rows = which(!grepl(ucr$fplace, pattern=";") & !is.na(ucr$fplace) & nchar(ucr$fplace)==2)
ucr[rows, fplace:=paste0("000", fplace)]

rows = which(!grepl(ucr$fplace, pattern=";") & !is.na(ucr$fplace) & nchar(ucr$fplace)==3)
ucr[rows, fplace:=paste0("00", fplace)]

rows = which(!grepl(ucr$fplace, pattern=";") & !is.na(ucr$fplace) & nchar(ucr$fplace)==4)
ucr[rows, fplace:=paste0("0", fplace)]

# now create two columns in ucr that you'll eventually combine into one.

ucr[, geoid.cd:=NA_character_]    # geoid.cd combines state county and place fips
ucr[, geoid.p:=NA_character_]			# geoid.p combines state and place fips

# get just rows corresponding to agencies where fplace is defined -- will fill in geoid variables just for these.
rows = which(!is.na(ucr$fplace) & !grepl(ucr$fplace, pattern=";"))

ucr[rows, geoid.p:=paste0(ucr$fstate[rows], ucr$fplace[rows])]
ucr[rows, geoid.cd:=paste0(ucr$county1_fips[rows], ucr$fplace[rows])]

# We will rely on county FIPS for any agencies with place FIPS do not map into the census 

# load the census data to find out which place codes these are
census = fread(paste0(origin, "/UCR-data-request/data dependencies/Auxiliary data/Census.csv"))
census[, geoid := as.character(geoid)]

# rows where the place codes do not map into the census
missing_rows = which(!is.na(ucr$fplace) &
										 	!grepl(ucr$fplace, pattern=";") &
										 	! ucr$geoid.cd %in% census$geoid &
										 	! ucr$geoid.p %in% census$geoid)

# set these to missing
ucr[missing_rows, geoid.cd:=NA_character_]
ucr[missing_rows, geoid.p:=NA_character_]
ucr[missing_rows, fplace:=NA_character_]

# create a single column called geoid_place that equals geoid.cd when county 
# subdivision matches and geoid.p when it does not.
ucr[geoid.cd %in% census$geoid, geoid_place := geoid.cd]
ucr[(! geoid.cd %in% census$geoid) & (geoid.p %in% census$geoid), geoid_place := geoid.p]


####################################################
# 6. Final check that all FIPS codes are in census #
####################################################

# loop through county1_fips, and check county2_fips and county3_fips to make sure all are valid -- they are
for(i in 1:nrow(ucr)){
	
	fips1 = ucr[i, county1_fips]

	if(!grepl(fips1, pattern=";")){
		
		if(fips1 %in% census$geoid){
			
		} else {
			print(paste0("FIPS code not found in census! row: ", i))
		}
		
	} else {
		
		fips1 = str_split(fips1, pattern="; ")[[1]]
		
		for(j in 1:length(fips1)){
			
			if(fips1[j] %in% census$geoid){
				
			} else {
				print(paste0("FIPS code not found in census! row: ", i))
			}
			
		}
		
	}
	
	if(i %% 10000 == 0){
		print(paste0(round(i / nrow(ucr), digits=3) * 100, "% Complete"))
	}
	
}

rows = which(!is.na(ucr$county2_fips))
sum(ucr[rows, county2_fips] %in% census$geoid) == length(rows)

rows = which(!is.na(ucr$county3_fips))
sum(ucr[rows, county3_fips] %in% census$geoid) == length(rows)

# now check that all components for geoid_place are valid -- they are
rows = which(!is.na(ucr$geoid_place))
sum(ucr[rows, geoid_place] %in% census$geoid) == length(rows)

# get rid of unwanted columns
ucr$geoid.cd=NULL
ucr$geoid.p=NULL


#################################################
# 7. Save output: /data output/3. Geocoding.csv #
#################################################

write.csv(x=ucr, file=paste0(origin, "/UCR-data-request/data output/3. Geocoding.csv"), row.names=FALSE)