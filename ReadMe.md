## Project overview

Historically, the FBI has collected crime and arrest data from law enforcement agencies across the United States.  These data are compiled in a series of annual data sets called the “Offenses Known and Clearances by Arrest” data, or simply the “Offenses Known” data.  These files are publicly available through the Inter-university Consortium for Political and Social Research ([ICPSR](https://www.icpsr.umich.edu/)).  

It is well documented that the Offenses Known data suffer from missing values.  Submitting data to the FBI is voluntary, and only about 65% of agencies submit complete reports each year.  To account for this, we multiply impute missing values using the methods described in [*Tackling UCR's missing data problem: A multiple imputation approach*](https://www.sciencedirect.com/science/article/abs/pii/S0047235222000022).  The data and code in this package implement these methods on the Offenses Known data from 2010-2013.  

## What’s in this package?

Along with this ReadMe file, you will find:

- A folder called “code” with nine R scripts. The first eight scripts (numbered) preprocess and multiply impute the Offenses Known data. The ninth script (Use.R) demonstrates how to use the multiply imputed data in an analysis. 
- A folder called “data dependencies” which contains the data sets required for preprocessing and imputing the data.
- A folder called “data output” (currently empty) that will store the output saved upon running the scripts in the code folder.

These files will help you take the Offenses Known data from its original form — what you get when you download it from ICPSR — to a multiply imputed data set.  All code should be compatible with R 4.2.3 and RStudio 2023.03.0+386.

## Limitations

***Some agencies do not record simple assaults.***  Our methods impute counts for Part I crimes defined by the FBI, including aggravated assault.  However, aggravated assaults do not exist in the Offenses Known data.  To calculate this quantity for an agency, simple assaults must be subtracted from total assaults.

This by itself is not a limitation.  However, we have noticed that some agencies do not seem to report simple assaults.  Rather than appear as missing data, the number of simple assaults is listed as zero.  For agencies that report a large number of total assaults, a zero count for simple assaults is suspect, because about 81% of all assaults are simple.[^1]  If we aggregate data across years (2010-2013), we find that there are 243 agencies that report at least 50 total assaults, none of which are simple.  Below, we provide a list of the 13 agencies with at least 1,000 recorded assaults during these years, none of which are simple.[^2]  
&nbsp;  


<div align="center">

Table 1. Agencies with over 1,000 recorded assaults but no simple assaults (2010-2013)
| ORI      | Agency            | Total   | 
|----------|-------------------|---------|
| NY03030  | New York City PD  | 120,116 |
| ILCPD00  | Chicago PD        | 50,545  |
| OH04807  | Toledo PD         | 5,171   |
| IL08207  | East St. Louis PD | 4,693   |
| AL00102  | Birmingham PD     | 3,951   |
| IL08402  | Springfield PD    | 3,593   |
| IL01001  | Champaign PD      | 2,188   |
| IL07207  | Peoria PD         | 2,025   |
| AL00201  | Mobile PD         | 1,681   |
| IL04501  | Aurora PD         | 1,669   |
| IL09907  | Joliet PD         | 1,468   |
| IL05802  | Decatur PD        | 1,108   |
| IL05701  | Bloomington PD    | 1,064   |

</div>
&nbsp;  

Users of the data may want to calculate violent crime rates using Part I crimes, similar to the way the FBI calculates rates.  However, this requires separating out aggravated and simple assaults, which cannot reliably be done for all agencies.  Unless this limitation is accounted for, violent crime rates in counties where these agencies operate will be inflated.  

***Some agencies do not record clearances.*** We found several agencies that report dozens, and sometimes hundreds, of Part I crimes, but do not record a single clearance for those crimes.  While possible, we suspect that clearances are not recorded and should be considered missing rather than zero counts.  There are 173 agencies with at least 100 reported offenses between 2010 and 2013 and no clearances.  Below, we provide a list of the 9 agencies with more than 1,000 reported offenses and no clearances.  
&nbsp;  


<div align="center">

Table 2. Agencies with over 1,000 reported offenses but no clearances (2010-2013)
| ORI      | Agency                           | Total   | 
|----------|----------------------------------|---------|
| IN04505  | Gary, IN PD                      | 5,677   |
| MS07601  | Greenville, MS PD                | 2,686   |
| CA00799  | Highway Patrol: Contra Costa, CA | 2,601   | 
| CA05099  | Highway Patrol: Modesto, CA      | 1,566   |
| AZ01201  | Nogales, AZ PD                   | 1,359   |
| CA04499  | Highway Patrol: Santa Cruz, CA   | 1,264   |
| CA05499  | Highway Patrol: Visalia, CA      | 1,258   |
| CA03657  | Patton State Hospital, PD        | 1,107   |
| CA03999  | Highway Patrol: Stockton, CA     | 1,008   |

</div>
&nbsp;  

***State police and other agencies with cross-county jurisdiction.***  Sometimes an agency in the Offenses Known data has jurisdiction in multiple counties, but the FIPS code for that agency points to a single county, usually where the agency’s headquarters is located.  This is often the case for state police agencies.  For example, the Connecticut State Police has jurisdiction in all eight counties in the state,[^3] but has just a single entry in the Offenses Known data (CTCSP00) indicating that the agency is located in New Haven County.  A county-level analysis that ignores this fact would attribute too much crime to New Haven County and too little to the other seven counties.  In contrast, the Indiana State Police has entries in the Offenses Known data for each county in the state, so that the offenses and clearances recorded by the state police are already disaggregated across counties.  By our count, there are 21 states that have a single state police agency that represents all counties, and 19 states where the state police agency has entries in the data across all counties.  

To make matters more complicated, there are nine states that follow neither pattern.[^4]  For example, the state police in Idaho have six entries in the Offenses Known data, each of which span multiple counties.[^5]  In Vermont, the state police are split into troops that are organized by city, so that more than one troop may provide service for a single county.[^6]  In addition to state police, there are several other agencies that have cross-county jurisdiction despite having a single entry into the UCR.  Examples include the Southeast Missouri Drug Task Force (MO10111), an agency with jurisdiction in ten counties in Missouri, and the Washington Gambling Commission (WA03410), an agency with statewide jurisdiction.  Any county-level analysis using the UCR data would benefit from identifying all agencies that operate in multiple counties and distributing offense and clearance counts across all counties where those agencies have jurisdiction.  

***Covering agencies.*** Some agencies in the Offenses Known data do not report their own crime and clearance statistics. Instead, another agency “covers” for them, submitting a report that includes aggregate counts for both agencies. The agency that submits the data is called a “covering agency,” and the agency that delegates this responsibility is called a “covered agency.” These agencies are identified in the Offenses Known data by the variable V9 (label: COVERED BY CODE). About 9% and 17% of all agencies are covering and covered agencies, respectively. More information on these agencies can be found in the Offenses Known codebooks (see for example, `data dependencies/UCR data/Offenses Known (2010-2013)/2013 (ICPSR_36122)/DS0001/36122-0001-Codebook.pdf`).

In an effort to keep our code as similar as possible to the methods used in DeLang et al. (2022), we do not make any distinction between covering, covered, or uncovered agencies.[^7]  However, this presents a problem when a covering agency submits data to the UCR.  In this case, the covered agency’s counts are still represented as missing values, and imputing those missing values results in double counting.

There are several options to try and remedy this problem. One is to delete the aggregate statistics reported by covering agencies and then impute the resulting data. The logic behind this is that the true crime and clearance counts for covering agencies are unknown, because all we know are the aggregate counts for that agency and others that it covers. This approach would address concerns over double counting, but would result in deleting potentially useful information.[^8] Alternatively, one may choose not to impute missing values for covered agencies if the covering agency fully reports. This might be useful if the end goal is a county-level analysis, because the vast majority of covering agencies are in the same county as the agencies they cover, so aggregating to the county-level preserves an accurate count. We encourage other suggestions and modifications to our code, as this is an open concern with our methods.  

***Newly established agencies in 2013.*** We use the Agency Identifiers Crosswalk (ICPSR 35158) to obtain each agency’s “type” (e.g., local police department, parks and recreation) as well as place FIPS codes for each local law enforcement agency. Unfortunately, this data set is only current up to 2012. To obtain agency type and place FIPS codes for agencies established in 2013, we manually searched for each agency on the internet using the agency’s name as listed in the Offenses Known data. Information for these agencies is stored in the file 
`data dependencies/Auxiliary data/New agencies.csv`.  Users who seek to expand on this work and include data for 2014 and beyond will also have to collect this information manually.

***Tribal agencies.*** The laws enforced on Indian reservations are not the same as those of the encompassing state. Under Public Law 93-638, tribes are given the opportunity to establish their own government functions by contracting with the Bureau of Indian Affairs.[^9] Because the laws that govern reservations are distinct from the laws in the county and state in which it exists, we have chosen to remove tribal law enforcement agencies from the data.

We use ORIs and agency names to identify tribal law enforcement agencies (see Part 3 of the R script titled “3. Geocoding.R”). This procedure removes 162 law enforcement agencies, all but three of which are local police departments. However, because the UCR data does not contain a clear indicator as to which agencies are tribal agencies, it is likely that some tribal agencies remain in the data.

***Loss of data when aggregating to years.*** The Offenses Known data provides monthly crime and clearance counts for law enforcement agencies. As part of the preprocessing steps, we aggregate the data to the agency-year level prior to imputing missing values. The benefit of this approach is in processing time. However, the cost is that data from partially reporting agencies, such as an agency that only submits data from January through June, is lost because the annual totals are unknown.  Fortunately, around 90% of agencies submit either a complete annual report or no data at all. For these agencies, there is no loss of information when aggregating to annual counts.

## Additional resources

<ins> Academic papers </ins>

- [Bridging Gaps in Police Crime Data (1999)](https://bjs.ojp.gov/content/pub/pdf/bgpcdes.pdf). Discusses the existing techniques used to impute
missing data in the UCR and areas for improvement.
- [A Note on the Use of County-Level UCR Data (2002)](https://citeseerx.ist.psu.edu/document?repid=rep1&type=pdf&doi=25fbd7d97b549fb99238508feb926166e4bcf423). Research paper appearing in the Journal
of Quantitative Criminology that cautions against use of the county-level UCR data.
- [Making UCR Data Useful and Accessible (2004)](https://www.ojp.gov/pdffiles1/nij/grants/205171.pdf). Report that offers guidelines on cleaning the
UCR data.
- [Analysis of Missingness in UCR Crime Data (2006)](https://www.ojp.gov/pdffiles1/nij/grants/215343.pdf). Report that examines missingness patterns
in the UCR data.
- [A Comparison of Imputation Methodologies in the Offenses-Known Uniform Crime Report
(2011)](https://biblioteca.cejamericas.org/bitstream/handle/2015/1561/235152.pdf?sequence=1&isAllowed=y). Provides a comprehensive background on the UCR program and compares different
imputation methods.

<ins> Web resources </ins>

- [NACJD: Uniform Crime Reporting Program](https://www.icpsr.umich.edu/web/pages/NACJD/guides/ucr.html). Overview of UCR data, including agency-, county- and incident-level data.
- [FBI UCR Landing Page](https://www.fbi.gov/how-we-can-help-you/more-fbi-services-and-information/ucr). FBI related information on the UCR program.
- [Uniform Crime Reporting Handbook](https://ucr.fbi.gov/additional-ucr-publications/ucr_handbook.pdf). Comprehensive handbook issued by the DOJ that
provides historical background of the program, offense classification, and rules that agencies are expected to follow when inputting data.
- [Return A](https://omb.report/icr/201905-1110-001/doc/94472301). The form that agencies use to submit monthly data to the FBI.
- [UCRbook.com](https://ucrbook.com/). A useful guide to using and understanding the UCR data.

## Project status

As detailed in the Limitations section above, there are numerous challenges associated with imputing and using the UCR data. Although the Research Team at Measures for Justice has officially retired this project, we welcome all efforts to improve the code and methods found in this repository. Any questions should be referred to Mason DeLang at the email address, below.  

Mason DeLang  
Senior Data Scientist  
Measures for Justice Institute  
ucr@mfj.io  


[^1]: To calculate this, we looked at all agencies with no missing data on total assaults for every month in 2013.  We then subset the data to only include agencies where at least one simple assault was reported and calculated the percentage of simple assaults.
[^2]: Notice that nine of the 13 agencies listed are located in Illinois.  Over 90% of the 243 agencies that record at least 50 total assaults but no simple assaults are also located in Illinois, pointing to regional differences associated with this limitation.
[^3]: [Connecticut State Police troops and districts](https://portal.ct.gov/DESPP/Division-of-State-Police/_old/Connecticut-State-Police-Troops-and-Districts)
[^4]: Hawaii does not have a state police agency.
[^5]: [Idaho State Police patrols](https://isp.idaho.gov/patrol/)
[^6]: [Vermont State Police barracks map](https://vsp.vermont.gov/sites/vsp/files/2022-06/VSPbarracksmap2022.pdf)
[^7]: The analysis in DeLang et al. (2022) excludes covering and covered agencies.
[^8]: Ideally, this information would be incorporated into the imputation algorithm.
[^9]: [Information on tribal law enforcement](https://www.tribal-institute.org/lists/enforcement.htm)
