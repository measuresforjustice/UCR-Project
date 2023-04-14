# Data sets in the repository

This file contains information on each of the data sets used in our methods.  These files can be found in the 
directory titled “data dependencies.”  Each section below corresponds to one of the data sets in that directory.  
&nbsp;   

### <ins>UCR data / Offenses Known (2010-2013)</ins>

**What is it:** These files, formally known as the “Offenses Known and Clearances by Arrest” data, contain monthly, 
agency-level offense and arrest counts collected by the FBI as part of the Uniform Crime Reporting project.

**How it’s used:** These data are the starting point for our methods and are dependencies in the first script 
(1. Add variable names.R).  Because many agencies do not report their data to the FBI, there is a considerable 
amount of missing data.  Our goal is to take these files and multiply impute the missing data.

**Source**: Each folder inside the Offenses Known (2010-2013) directory contains the entire contents of a ZIP file 
that can be downloaded from ICPSR.  See below for links to each of these ZIP files.

[Uniform Crime Reporting Program Data: Offenses Known and Clearances by Arrest, 2010](https://www.icpsr.umich.edu/web/NACJD/studies/33526)  
[Uniform Crime Reporting Program Data: Offenses Known and Clearances by Arrest, 2011](https://www.icpsr.umich.edu/web/NACJD/studies/34586)  
[Uniform Crime Reporting Program Data: Offenses Known and Clearances by Arrest, 2012](https://www.icpsr.umich.edu/web/NACJD/studies/35021)  
[Uniform Crime Reporting Program Data: Offenses Known and Clearances by Arrest, 2013](https://www.icpsr.umich.edu/web/NACJD/studies/36122)  
&nbsp;   

### <ins>UCR data / Arson (2010-2013)</ins>

**What is it:** These files contain monthly, agency-level offense and arrest counts for arson.

**How it’s used:** Arson is the only Part I crime that’s NOT provided in the Offenses Known data.  To get the total 
number of Part I property crimes reported by agencies, we need to merge arson data into the offenses known files.  
This step is accomplished in the code file, 2. Merging.R.

**Source:** Each folder inside the Arson (2010-2013) directory contains the entire contents of a ZIP file that can be 
downloaded from ICPSR.  See below for links to each of these ZIP files.

[Uniform Crime Reporting Program Data: Arson, United States, 2010](https://www.icpsr.umich.edu/web/NACJD/studies/33528)  
[Uniform Crime Reporting Program Data: Arson, United States, 2011](https://www.icpsr.umich.edu/web/NACJD/studies/34579)  
[Uniform Crime Reporting Program Data: Arson, United States, 2012](https://www.icpsr.umich.edu/web/NACJD/studies/35016)  
[Uniform Crime Reporting Program Data: Arson, United States, 2013](https://www.icpsr.umich.edu/web/NACJD/studies/36114)  
&nbsp;   

### <ins>UCR data / Police employee data (2010-2013)</ins>

**What is it:** These are annual, agency-level files that contain information on the number of employees and officers 
per 1,000 citizens in its jurisdiction.

**How it’s used:** We include the number of employees and officers per 1,000 citizens in our imputation models.

**Source:** Each folder inside the Police employee data (2010-2013) directory contains the entire contents of a ZIP 
file that can be downloaded from ICPSR.  See below for links to each of these ZIP files.

[Uniform Crime Reporting Program Data: Police Employee (LEOKA) Data, 2010](https://www.icpsr.umich.edu/web/NACJD/studies/33525)  
[Uniform Crime Reporting Program Data: Police Employee (LEOKA) Data, 2011](https://www.icpsr.umich.edu/web/NACJD/studies/34584)  
[Uniform Crime Reporting Program Data: Police Employee (LEOKA) Data, 2012](https://www.icpsr.umich.edu/web/NACJD/studies/35020)  
[Uniform Crime Reporting Program Data: Police Employee (LEOKA) Data, 2013](https://www.icpsr.umich.edu/web/NACJD/studies/36119)  
&nbsp;   

### <ins>UCR data / Agency identifiers crosswalk</ins>

**What is it:** This data set contains additional information on the law enforcement agencies represented in the data.  
Information includes the name and location of an agency, agency type (e.g. local law enforcement, sheriff, park police, 
etc.), and the size of its jurisdiction.

**How it’s used:** Information on agency type and jurisdiction are important predictors of how many offenses and arrests 
an agency records.  We also merge in FIPS county and place codes that are eventually used to link census data to each of 
the agencies.  This information is merged into the Offenses Known data in the file 2. Merging.R.

**Source:** This data was downloaded from ICPSR and can be found here: [Law Enforcement Agency Identifiers Crosswalk, United States, 2012](https://www.icpsr.umich.edu/web/NACJD/studies/35158)  
&nbsp;   

### <ins>Auxiliary data / UCR dictionary.csv</ins>

**What is it:** The Offenses Known data come with a PDF codebook detailing each of the 1,448 variables in the files.  
We scraped information from this codebook and stored it in a CSV file.  The data in this file contain the variable 
names as they appear in the data and brief descriptions for those variables.

**How it’s used:** There are 1,448 variables in the Offenses Known data, and the variable names in these files are 
simply V1, V2 ,..., V1448.  For ease of interpretation, we wanted to overwrite these variable names by the “Variable 
Label” which also appears in the codebook.  This step occurs in the first script (1. Add variable names.R).

**Source:** This file was created by MFJ, but the original codebooks can be found in the Offenses Known folders (see, 
for example: `/Offenses Known (2010-2013)/2010 (ICPSR_33526)/DS0001/33526-0001-Codebook.pdf`).  
&nbsp;   

### <ins>Auxiliary data / Variable names.csv</ins>

**What is it:** This file is a CSV with two columns that act as a dictionary, converting old variable names in the 
column labeled “orig” to new variable names in the column labeled “new”.

**How it’s used:** This dictionary is applied to the Offenses Known data (see 2. Merging.R) after having merged in 
the Arson data and information from the Agency identifiers crosswalk.  Variable names are changed to ease 
interpretation while writing code.

**Source:** This file was created by MFJ.  
&nbsp;   

### <ins>Auxiliary data / Fbi2fips.csv</ins>

**What it is:** This file is a dictionary that translates UCR county codes to FIPS codes.

**How it’s used:** The county codes in the Offenses Known data are UCR geographic codes rather than FIPS codes.  In 
order to merge in census data, we convert these to FIPS codes using this file.

**Source:** This file can be downloaded from ICPSR, here: [UCR and FIPS State and County Geographic Codes, 1990: United States](https://www.icpsr.umich.edu/web/NACJD/studies/2565)  
&nbsp;   

### <ins>Auxiliary data / Geocodes.csv</ins>

**What is it:** This file contains accurate census FIPS codes at the state, county, county subdivision, and place levels.

**How it’s used:** After converting UCR county codes to FIPS codes, and after merging in place FIPS codes from the 
Agencies identifiers crosswalk, we are in a position to verify that all FIPS codes in the data are accurate.  To do 
so, we cross-reference every FIPS code in the Offenses Known data against those in this file.  County codes that are 
not found are incorrect and are fixed manually.  Place codes that are not found are deleted and county FIPS codes are 
used instead.

**Source:** This data set comes from the Census Bureau and can be downloaded here: [2016 Population Estimates FIPS Codes](https://www.census.gov/geographies/reference-files/2016/demo/popest/2016-fips.html)  
&nbsp;   

### <ins>Auxiliary data / ORI extras.csv</ins>

**What is it:** This file is a supplement to the Agency identifiers crosswalk.  It contains information on new 
agencies from 2013 that do not appear in the crosswalk.

**How it’s used:** The Agency identifiers crosswalk is up to date as of 2012.  Therefore, any new agencies in 2013 
won’t be listed in the crosswalk.  MFJ researched each of these new agencies and created this supplemental file to 
be merged into the Offenses Known data.

**Source:** This file was created by MFJ.  
&nbsp;   

### <ins>Auxiliary data / Census.csv</ins>

**What is it:** Demographic and socioeconomic census data for counties, county subdivisions and census designated 
places.

**How it’s used:** Demographic and socioeconomic data is merged into the Offenses Known files to help predict crime 
and arrest counts for specific locales.

**Source:** The Census API was used to download files directly.  See here for more information: [Census APIs](https://www.census.gov/data/developers/data-sets.html)
