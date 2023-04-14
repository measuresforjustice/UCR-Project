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


############
# Use file #
############

# Data dependencies: 
# 
# 1. data output/8. Multiple Imputation.RData
#
# This file does the following:
#
# 1. Loads the MIDS object that results from multiple imputation using mice()
# 2. Obtains each of the imputed data sets from the MIDS object
# 3. Uses the imputed data to run an agency-level regression
# 4. Uses the imputed data to run a county-level regression
#
# Libraries 
# install.packages("data.table")
# install.packages("rlist")
# install.packages("mice")

library(data.table)
library(dplyr)
library(mice)

# **** Provide file path to the location of the github repository ****
origin = ""


########################################
# 1. Load MIDS object after running MI #
########################################

load(paste0(origin, "/UCR-data-request/data output/8. Multiple imputation.RData"))


###################################
# 2. Obtain the imputed data sets #
###################################

# Use the complete() function in the mice package to obtain the imputed data as a list object
imps=complete(ucr.imputed, action="all")

# Use the argument *include = TRUE* to include the original data (missing values preserved)
imps=complete(ucr.imputed, action="all", include=TRUE)

# The first element of this list is the original data
View(imps[[1]])

# The other elements are the five imputed data sets
View(imps[[2]])
View(imps[[3]])
View(imps[[4]])
View(imps[[5]])
View(imps[[6]])

# You can stack the imputed data sets into a single data.frame using *action = "long"*
imps=complete(ucr.imputed, action="long", include = TRUE)


########################################################################################
# Note that there are two additional variables using the "long" format:								 #
#																																											 #
# 1) .imp indicates which data set the row comes from (0 indicates original data, 1-5  #
#		 indicates imputed data).																													 #
#																																											 #	
# 2) .id indicates the observation  																									 #
########################################################################################


##########################################################################################
# 3. Estimate the effect of agency size and type on the total number of violent offenses #
##########################################################################################

# First, obtain the imputed data in the long format in order to make transformations
imps = complete(ucr.imputed, action="long", include=TRUE)

# Next, create a variable for violent offenses
imps$violent.tot = imps$murd.tot + imps$mans.tot + imps$rape.tot + imps$robb.tot + imps$agga.tot

# Now use as.mids() to return the imputed data to a MIDS object
back.to.mids = as.mids(imps)

# use with() and glm() to run a regression on the MIDS object
fit=with(back.to.mids, 
				 glm(violent.tot ~ juris1 + employees + type.local + type.sheriff, 
				 		family="poisson"))

# Pool estimates using Rubin's rules
estimates = pool(fit)

# Look at results
summary(estimates)


###########################################################################
# 3. At the county level, estimate the effect of socioeconomic indicators #
#    on the total number of violent crimes																#
###########################################################################

# First, obtain the imputed data in the long format in order to make transformations
imps = complete(ucr.imputed, action="long", include=TRUE)

# Next (for the purposes of this example) focus just on agencies WITHOUT cross-county jurisdiction.
imps = imps %>% filter(!grepl(county1_fips, pattern=";"))

# Now use group_by() and summarise() to aggregate the data on .imp and county1_fips.
imps = imps %>%
	group_by(.imp, county1_fips) %>%
	reframe(violent.tot = murd.tot + mans.tot + rape.tot + robb.tot + agga.tot,
					pop = sum(juris1),
					urban.perc = mean(urban.perc),
					HS_or_more = mean(HS_or_more),
					high.income = mean(high.income),
					unemp.perc = mean(unemp.perc)) %>%
	as.data.table()

# Now use as.mids() to return the imputed data to a MIDS object
back.to.mids = as.mids(imps)

# use with() and lm() to run regression
fit=with(back.to.mids, lm(violent.tot ~ pop + urban.perc + HS_or_more + high.income + unemp.perc))

# Pool estimates using Rubin's rules
estimates = pool(fit)

# Look at results
summary(estimates)