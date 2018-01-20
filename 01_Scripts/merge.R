
library(data.table)
library(ggplot2)
library(lubridate)
library(imputeTS)
dt_obs=fread("00_Dataset/obs_complete.csv",sep=";")
dt_cal=fread("00_Dataset/caliope_data.csv",sep=";")
dt_obs[,date:=as.POSIXct(date)]
dt_cal[,date:=as.POSIXct(date)]

dt_cal <- dt_cal[, c("station", "date", "FC_today", "FC_yesterday")]

dt <- merge(dt_obs, dt_cal, by.x = c("id_station", "date"), by.y= c("station", "date"), all=T)
dt=dt[order(id_station, date)]
dt[, no2_2:=na.interpolation(no2)]
dt[, FC_T_2:=na.interpolation(FC_today)]
dt[, FC_Y_2:=na.interpolation(FC_yesterday)]
dt <- dt[!is.na(height)]

write.table(dt, "00_Dataset/dataset.csv", row.names = FALSE, sep=";")

