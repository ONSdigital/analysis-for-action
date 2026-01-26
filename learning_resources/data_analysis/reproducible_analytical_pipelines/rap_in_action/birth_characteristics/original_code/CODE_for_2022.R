# This script is based on code created to produce publication tables for Birth Characteristics.
# It has been been heavily edited and sections have been removed for example purposes.
# This repository should only be used as an example alongside the Analysis for Action Birth Characteristics RAP learning resource.

#7.11.23 added some formatting on tables
#08.11.23 added some code to solve issue of NA in  missing data

###########################################################################################
####  DAU 'Childbearing for women born in different years, England and Wales' Release  ####
####  V2.0 - August 2021 (updated 9.11.21) 
##### V2.1 March 2023 (2021 data updates and tweaks, last updated 16.03.23)
#################################################################
###########################################################################################

##############################################################
## [1] Install Packages and define input and output folders ##
##############################################################

install.packages("RODBC", dependencies = TRUE, type = "win.binary")
install.packages("data.table", dependencies = TRUE, type = "win.binary")
install.packages("sqldf", dependencies = TRUE, type = "win.binary")
install.packages("reshape", dependencies = TRUE, type = "win.binary")
install.packages("tidyverse", dependencies = TRUE, type = "win.binary")
install.packages("plyr", dependencies = TRUE, type = "win.binary")
install.packages("tidyr", dependencies = TRUE, type = "win.binary")
install.packages("plotly", dependencies = TRUE, type = "win.binary")
install.packages("xlsx", dependencies = TRUE, type = "win.binary")
install.packages("readxl", dependencies = TRUE, type = "win.binary")
install.packages("reshape2", dependencies = TRUE, type = "win.binary")
install.packages("openxlsx", dependencies = TRUE, type = "win.binary")
install.packages("writexl", dependencies = TRUE, type = "win.binary")

library(RODBC)
library(data.table)
library(sqldf)
library(reshape)
library(plyr)
library(dplyr)
library(stringr)
library(tidyr)
library(ggplot2)
library(plotly)
library(xlsx)
library(readxl)
library(reshape2)
library(openxlsx)
library(writexl)

# Set the input and output directories
# User will need to create new year folder containing input and output folders in network drive (see desk instructions for files to be added to input folder)
# Ensure the correct year is set for the directory

directory <- "path_to_directory"
setwd (directory)

################################################################################
## [2] Accessing and prepping LEO Births Data for most recent year [REQUIRED] ##
################################################################################

sqlbths <- odbcDriverConnect('driver=driver;server=server;schema=schema;
                             database=leo_births; trusted_connection=true') 

LEO_births <- sqlQuery(sqlbths,"SELECT sourcetable, AGEBM, PREVCHL, BTHIMAR, SBIND, REGDETS, MULTBTH, MULTTYPE, PCDRM FROM dbo.Births_2018on" , stringsAsFactors=FALSE)

births <- LEO_births %>% 
  filter(sourcetable == 2022) %>%  # Year 2022 specified inline
  filter(is.na(SBIND)) %>% 
  mutate(SBIND = NULL)

# Set values of PREVCHL = 99, to be missing values N/A
births$PREVCHL[births$PREVCHL == 99] <- NA

# Create new variable: mother's age at birth (AGEBM) to COMPLETED YEARS (M_AGE_COMPLETEYRS) 
#(i.e. completed years when child is born: rounded down)

births <- births %>%
  mutate(M_AGE_COMPLETEYRS = AGEBM) %>% 
  mutate(M_AGE_COMPLETEYRS = M_AGE_COMPLETEYRS/100)
births$M_AGE_COMPLETEYRS <- round(births$M_AGE_COMPLETEYRS, digit = 0)  

# Create new variable: M_AGE_EXACT

births <- mutate(births, M_AGE_EXACT = M_AGE_COMPLETEYRS + 1)


##################################################################################
##                    ...Further processing not shown...                        ##
##################################################################################


#########################################################################################################################################
## [5] [OPTIONAL] OUTLIERS: Plot Age/PrevChildren to map outliers **OUTPUT 2** & code to identify particular outlier records if needed ## 
#########################################################################################################################################

# Plot Age of mother (completed years) against number of previous children
# plot_ly(...)


##################################################################################
##                    ...Further processing not shown...                        ##
##################################################################################


########################################################################
## [12] [REQUIRED] Convert COMPLETED YEARS 'Histspec' into 'Truespec' ##
########################################################################

# Download MYE file from corresponding year as a csv
MYE <- read.csv("input/female_population.csv", skip = 0, header = TRUE)

# Set location of Truespec file from previous year and read in
# ENSURE TRUESPEC DATA FROM PREVIOUS YEAR IS COPIED INTO INPUT DIRECTORY FOLDER AS A CSV FILE AND CORRECT FILE NAME IS USED IN READ.CSV FUNCTION
# File name will need to be amended to data from previous year
Truespec_prev_year <- read.csv("input/Truespec_2021.csv")

##################################################################################
##                    ...Further processing not shown...                        ##
##################################################################################

# save wb containing tables - change year each year
saveWorkbook(wb, "output/Cohort_tables_2022_final.xlsx", overwrite = TRUE)
