library(data.table)
library(ggplot2)
library(lubridate)
dt=fread("00_Dataset/dataset.csv",sep=";")
dt[,date:=as.POSIXct(date)]
dt=unique(dt)
dt=dt[order(id_station,date)]

dt[,month:=month(date)]
dt[,year:=year(date)]
dt[,hour:=hour(date)]
dt[,day:=day(date)]
dt[,fecha:=as.Date(date)]

dt[,obs_hour:=shift(no2_2,1),by=id_station]
dt[,obs_day:=shift(no2_2,1),by=c("id_station","hour")]
dt[,obs_day:=shift(no2_2,1),by=c("id_station","year")]
dt[,pred_hour:=shift(FC_T_2,1),by=id_station]
dt[,pred_day:=shift(FC_T_2,1),by=c("id_station","hour")]
dt[,pred_year:=shift(FC_T_2,1),by=c("id_station","year")]
dt[,pred_Yhour:=shift(FC_Y_2,1),by=id_station]
dt[,pred_Yday:=shift(FC_Y_2,1),by=c("id_station","hour")]
dt[,pred_Yyear:=shift(FC_Y_2,1),by=c("id_station","year")]