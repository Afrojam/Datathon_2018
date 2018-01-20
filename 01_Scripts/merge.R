setwd("~/Desktop/Datathon_2018")
library(data.table)
library(ggplot2)
library(lubridate)
library(imputeTS)
dt_obs=fread("00_Dataset/obs_complete.csv",sep=";")
dt_cal=fread("00_Dataset/caliope_data.csv",sep=";")
dt_obs[,date:=as.POSIXct(date)]
dt_cal[,date:=as.POSIXct(date)]
dt=merge(dt_cal,dt_obs[,.(station=id_station,date,no2,height)],by=c("station","date"),all = TRUE)
dt=dt[order(date)]
dt[date<"2015-01-01 00:00:00", no2_2:=na.interpolation(no2)]

write.table(dt, "00_Dataset/dataset.csv", row.names = FALSE, sep=";")

