# This script is based on code created to produce publication tables for Birth Characteristics.
# It has been been heavily edited and sections have been removed for example purposes.
# This repository should only be used as an example alongside the Analysis for Action Birth Characteristics RAP learning resource.

#libraries
library(RODBC)
library(data.table)
library(sqldf)
library(reshape)
library(plyr)
library(dplyr)
library(stringr)

#specify the current datayear (this needs updating before running the program)
datyrfull <- 2021
datyr<- 21

##################################################################################
##    ...Creation and processing of Parent Characteristic table not shown...    ##
##################################################################################

#write file
write.csv(fulltable21, file = "output_location/Par_ch_table1.csv")
