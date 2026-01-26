# This script is based on code created to produce publication tables for Birth Characteristics.
# It has been been heavily edited and sections have been removed for example purposes.
# This repository should only be used as an example alongside the Analysis for Action Birth Characteristics RAP learning resource.

##########################################
# Code for Birth Characteristics table 12
##########################################


# Load libraries
library("readr")
library("RODBC")
library("data.table")
library("sqldf")
library("plyr")
library("dplyr")
library("stringr")
library("reshape")
library("tidyverse")
library("janitor")


# Update data year
datyr <- 21
datyrfull <- 2021


##################################################################################
##                   ...Import and processing not shown...                      ##
##################################################################################

# Drop the NA
e <- e[!is.na(e$IMD_E),]

# Add a total row
e <- e %>% adorn_totals("row", name = "Total")

# Create table for Wales
w <- plyr::count(ew, c('bth','IMD_W'))
w <- cast(w, IMD_W ~ bth, value = 'freq')

# Drop the NA
w <- w[!is.na(w$IMD_W),]

# Add a total row
w <- w %>% adorn_totals("row", name = "Total")

# Join England and Wales together
t12 <- merge(e,w, by.x=c("IMD_E"),by.y=c("IMD_W"))

# Reorder rows to match publishable format
t12 <- t12[c("IMD","Live.births.E","Stillbirths.E","Stillbirth.rate.E","Live.births.W","Stillbirths.W","Stillbirth.rate.W")]

# Reorder the rows
x <- c("1","2","3","4","5","6","7","8","9","10","Total")
t12 <- t12 %>% slice(match(x, IMD))

# Export - UPDATE EXPORT LOCATION AS REQUIRED
write.csv(t12, "output_location/Births_ch_table12_KG.csv")
