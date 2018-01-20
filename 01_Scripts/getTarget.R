setwd("~/Desktop/Datathon_2018")
library(data.table)
library(ggplot2)
library(lubridate)
library(imputeTS)

dt=fread("00_Dataset/dataset.csv",sep=";")
dt[,month:=month(date)]
dt[,year:=year(date)]
dt[,hour:=hour(date)]
dt[,day:=day(date)]

dt_aux=dt[date<"2015-01-01 00:00:00" & date>"2013-01-01 00:00:00",.(mean(no2_2)),by=c("hour","station")]
ggplot(dt_aux,aes(hour,V1,col=station))+geom_point()+geom_line()

cor(dt[date<"2015-01-01 00:00:00" & date>"2013-01-01 00:00:00",.(no2_2,height)])

dt_obs[is.na(no2),.N,by=id_station]

dt[,fecha:=as.Date(date)]
targetobs=dt[,.(y=any(no2_2>100)*1),by=c("fecha","station")]
write.table(targetobs, "00_Dataset/targetobs.csv", row.names = FALSE, sep=";")

