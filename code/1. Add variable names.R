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


###########################
# 1. Add variable names.R #
###########################

# Data dependencies: 
# 
# 1. UCR data / Offenses Known (2010-2013)
# 2. Auxiliary data / UCR dictionary.csv
#
#
# This file does the following:
#
# 1. Loads the Offenses Known data (2010-2013)
# 2. Applies the UCR dictionary to get readable column names.
# 3. Saves output: 
#				- data output/1a. Add variable names (2010).csv
#				- data output/1b. Add variable names (2011).csv
#				- data output/1c. Add variable names (2012).csv
#				- data output/1d. Add variable names (2013).csv
#
#
# Libraries 
# install.packages("data.table")

library(data.table)

# **** Provide file path to the location of the github repository ****
origin = ""


##########################
# 1. Load Offenses Known #
##########################

ucr2010=fread(paste0(origin, "/UCR-data-request/data dependencies/UCR data/Offenses Known (2010-2013)/2010 (ICPSR_33526)/DS0001/33526-0001-Data.tsv"))
ucr2011=fread(paste0(origin, "/UCR-data-request/data dependencies/UCR data/Offenses Known (2010-2013)/2011 (ICPSR_34586)/DS0001/34586-0001-Data.tsv"))
ucr2012=fread(paste0(origin, "/UCR-data-request/data dependencies/UCR data/Offenses Known (2010-2013)/2012 (ICPSR_35021)/DS0001/35021-0001-Data.tsv"))
ucr2013=fread(paste0(origin, "/UCR-data-request/data dependencies/UCR data/Offenses Known (2010-2013)/2013 (ICPSR_36122)/DS0001/36122-0001-Data.tsv"))


########################################
# 2. Load and apply the UCR dictionary #
########################################

dictionary=fread(paste0(origin, "/UCR-data-request/data dependencies/Auxiliary data/UCR dictionary.csv"))

names(ucr2010) = dictionary$variableLabel
names(ucr2011) = dictionary$variableLabel
names(ucr2012) = dictionary$variableLabel
names(ucr2013) = dictionary$variableLabel


##################
# 3. Save output #
##################

write.csv(x=ucr2010, file=paste0(origin, "/UCR-data-request/data output/1a. Add variable names (2010).csv"), row.names=FALSE)
write.csv(x=ucr2011, file=paste0(origin, "/UCR-data-request/data output/1b. Add variable names (2011).csv"), row.names=FALSE)
write.csv(x=ucr2012, file=paste0(origin, "/UCR-data-request/data output/1c. Add variable names (2012).csv"), row.names=FALSE)
write.csv(x=ucr2013, file=paste0(origin, "/UCR-data-request/data output/1d. Add variable names (2013).csv"), row.names=FALSE)