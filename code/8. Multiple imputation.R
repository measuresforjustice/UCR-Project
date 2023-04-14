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


##########################
# 8. Multiple imputation #
##########################

# Data dependencies: 
# 
# 1. data output/6. Aggregation and census merge.csv
# 2. data output/7. Initial Values.csv
#
# This file does the following:
#
# 1. Loads intermediate data: 
#				- data output/6. Aggregation and census merge.csv
#				- data output/7. Initial Values.csv
# 2. Pares down UCR columns to those needed for imputation
# 3. Creates inputs for multiple imputation
# 4. Imputes the data using MICE (multiple imputation by chained equations)
# 5. Creates and save the output file, a list containing:
#				- The five imputed data sets
#				- The mids object that is returned after running the MICE algorithm. 
#					See the MICE package for more information on this.
#				- File is located here: data output/8. Multiple imputation.RData
#
# Libraries 
# install.packages("data.table")
# install.packages("rlist")
# install.packages("mice")
# install.packages("ranger")

library(data.table)
library(rlist)
library(mice)
library(ranger)

# **** Provide file path to the location of the github repository ****
origin = ""


#############################
# 1. Load intermediate data #
#############################

ucr = fread(paste0(origin, "/UCR-data-request/data output/6. Aggregation and census merge.csv"))
inits = fread(paste0(origin, "/UCR-data-request/data output/7. Initial Values.csv"))


###########################################################
# 2. Pare down UCR columns to those needed for imputation # 
###########################################################

# collect variables
roots = c("murd", "mans", "rape", "robb", "agga", "burg", "larc", "vhct", "arso")

tot.vars=paste0(roots, ".tot")
clr.vars=paste0(roots, ".clr")

keeps = c("juris1", "type.local", "county1_fips", "type.sheriff", "type.state", "year", "employees", "ori", "geoid_place",
					"pop.tot", "pop.m1834.perc",
					"HS_or_more", "BS_or_more",
					"low.income", "high.income", "bpov.perc", "snap.perc",
					"unemp.perc",
					"white.perc", "black.perc",
					"urban.perc", "sphh.perc", "own.perc", "hhld.avg",
					tot.vars, clr.vars)

ucr = ucr[, ..keeps]

# A handful of agencies report negative counts. Set these to zero prior to imputation.
for(var in c(tot.vars, clr.vars)){
	
	col = which(names(ucr)==var)
	rows = which(ucr[[var]]< 0)
	if(length(rows)>0)
		ucr[rows, (col):=0]
	
}


############################################
# 3. Create inputs for multiple imputation #
############################################

# Create prediction matrix -- input into mice argument predictorMatrix
pred = matrix(nrow=ncol(ucr), ncol=ncol(ucr), 1)
diag(pred) = 0
colnames(pred) = names(ucr)
row.names(pred) = names(ucr)

# Fill in zeroes for variables not used in prediction
pred[,names(ucr) %in% c("ori", "county1_fips", "year", "county.pop", "geoid_place")] = 0
pred[! names(ucr) %in% c(tot.vars, clr.vars),] = 0

# Make it so violent totals only predict violent totals and property totals only predict 
# property totals.  Same for violent and property clearances.
viol.tot = c("murd.tot", "rape.tot", "robb.tot", "agga.tot")
viol.clr = c("murd.clr", "rape.clr", "robb.clr", "agga.clr")
prop.tot = c("larc.tot", "burg.tot", "vhct.tot", "arso.tot")
prop.clr = c("larc.clr", "burg.clr", "vhct.clr", "arso.clr")

pred[names(ucr) %in% viol.tot, names(ucr) %in% c(viol.clr, prop.clr, prop.tot, viol.tot)] = 0
pred[names(ucr) %in% prop.tot, names(ucr) %in% c(viol.clr, prop.clr, viol.tot, prop.tot)] = 0
pred[names(ucr) %in% viol.clr, names(ucr) %in% c(viol.tot, prop.tot, prop.clr, viol.clr)] = 0
pred[names(ucr) %in% prop.clr, names(ucr) %in% c(viol.tot, prop.tot, viol.clr, prop.clr)] = 0

# constrain imputations to be > 0
post = c(rep("", times=24),
				 rep("imp[[j]][, i] <- squeeze(imp[[j]][, i], c(0, Inf))", times=18))

# Store all inputs into a list...
inputs = list()

# predictor matrix
inputs$predictorMatrix=pred  

# number of imputations and maxit
inputs$m=5
inputs$maxit=6

# method for imputations
inputs$method = c(rep("", times=which(names(ucr)=="murd.tot")-1), rep("rf", times=18))

# initial values
inputs$data.init = inits

# constraints
inputs$post = post


#################################
# 4. Impute the data using MICE #
#################################

# Run the imputation algorithm
inputs$data = ucr
ucr.imputed = do.call("mice", inputs)

# Save
save("ucr.imputed", file=paste0(origin, "/UCR-data-request/data output/8. Multiple imputation.RData"))
