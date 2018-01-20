library(data.table)
library(ggplot2)
library(lubridate)
library(lubridate)


dataset <- as.data.table(read.csv("00_Dataset/dataset.csv", sep = ";"))

dataset[,month:=month(date)]
dataset[,year:=year(date)]
dataset[,hour:=hour(date)]
dataset[,day:=day(date)]
dataset[,fecha:=as.Date(date)]
dataset[hour==0 & day == 1 & month==1, fecha:=as.Date(date)+3600]
dataset$weekday <- weekdays(dataset$fecha)

# Holidays
dataset$holidays <- ifelse(dataset$day == 1 & dataset$month == 1, "Any_Nou", "Normal")
dataset$holidays <- ifelse(dataset$day == 6 & dataset$month == 1, "Reis", dataset$holidays)
dataset$holidays <- ifelse(dataset$day == 1 & dataset$month == 5, "Dia_Treball", dataset$holidays)
dataset$holidays <- ifelse(dataset$day == 24 & dataset$month == 6, "Sant_Joan", dataset$holidays)
dataset$holidays <- ifelse(dataset$day == 15 & dataset$month == 8, "Verge", dataset$holidays)
dataset$holidays <- ifelse(dataset$day == 11 & dataset$month == 9, "Diada", dataset$holidays)
dataset$holidays <- ifelse(dataset$day == 24 & dataset$month == 9, "Merce", dataset$holidays)
dataset$holidays <- ifelse(dataset$day == 12 & dataset$month == 10, "Hispanidad", dataset$holidays)
dataset$holidays <- ifelse(dataset$day == 1 & dataset$month == 11, "Tot_Sants", dataset$holidays)
dataset$holidays <- ifelse(dataset$day == 6 & dataset$month == 12, "Constitucion", dataset$holidays)
dataset$holidays <- ifelse(dataset$day == 8 & dataset$month == 12, "Immaculada", dataset$holidays)
dataset$holidays <- ifelse(dataset$day == 25 & dataset$month == 12, "Nadal", dataset$holidays)
dataset$holidays <- ifelse(dataset$day == 26 & dataset$month == 12, "St_Esteve", dataset$holidays)
dataset$holidays <- ifelse(dataset$day == 31 & dataset$month == 12, "Cap_Any", dataset$holidays)


dataset$holidays <- ifelse(dataset$day == 24 & dataset$month == 3 & dataset$year == 2013, "Diumenge_Rams", dataset$holidays)
dataset$holidays <- ifelse(dataset$day == 29 & dataset$month == 3 & dataset$year == 2013, "Divendres_Sant", dataset$holidays)
dataset$holidays <- ifelse(dataset$day == 1 & dataset$month == 4 & dataset$year == 2013, "Pasqua", dataset$holidays)
dataset$holidays <- ifelse(dataset$day == 20 & dataset$month == 5 & dataset$year == 2013, "Pentecostes", dataset$holidays)

dataset$holidays <- ifelse(dataset$day == 13 & dataset$month == 4 & dataset$year == 2014, "Diumenge_Rams", dataset$holidays)
dataset$holidays <- ifelse(dataset$day == 18 & dataset$month == 4 & dataset$year == 2014, "Divendres_Sant", dataset$holidays)
dataset$holidays <- ifelse(dataset$day == 21 & dataset$month == 4 & dataset$year == 2014, "Pasqua", dataset$holidays)
dataset$holidays <- ifelse(dataset$day == 9 & dataset$month == 6 & dataset$year == 2014, "Pentecostes", dataset$holidays)

dataset$holidays <- ifelse(dataset$day == 29 & dataset$month == 3 & dataset$year == 2015, "Diumenge_Rams", dataset$holidays)
dataset$holidays <- ifelse(dataset$day == 3 & dataset$month == 4 & dataset$year == 2015, "Divendres_Sant", dataset$holidays)
dataset$holidays <- ifelse(dataset$day == 6 & dataset$month == 4 & dataset$year == 2015, "Pasqua", dataset$holidays)
dataset$holidays <- ifelse(dataset$day == 1 & dataset$month == 6 & dataset$year == 2015, "Pentecostes", dataset$holidays)


dataset$school <- ifelse(dataset$fecha >= "2013-01-08" & dataset$fecha <= "2013-03-22" & !(dataset$weekday  %in% c("sábado", "domingo")), 1, 0)
dataset$school <- ifelse(dataset$fecha >= "2013-04-02" & dataset$fecha <= "2013-06-21" & !(dataset$weekday  %in% c("sábado", "domingo")), 1, dataset$school)

dataset$school <- ifelse(dataset$fecha >= "2013-09-12" & dataset$fecha <= "2013-12-20" & !(dataset$weekday  %in% c("sábado", "domingo")), 1, dataset$school)
dataset$school <- ifelse(dataset$fecha >= "2014-01-08" & dataset$fecha <= "2014-04-11" & !(dataset$weekday  %in% c("sábado", "domingo")), 1, dataset$school)
dataset$school <- ifelse(dataset$fecha >= "2014-04-22" & dataset$fecha <= "2014-06-20" & !(dataset$weekday  %in% c("sábado", "domingo")), 1, dataset$school)


dataset$school <- ifelse(dataset$fecha >= "2014-09-15" & dataset$fecha <= "2014-12-23" & !(dataset$weekday  %in% c("sábado", "domingo")), 1, dataset$school)
dataset$school <- ifelse(dataset$fecha >= "2015-01-08" & dataset$fecha <= "2015-03-27" & !(dataset$weekday  %in% c("sábado", "domingo")), 1, dataset$school)
dataset$school <- ifelse(dataset$fecha >= "2015-04-07" & dataset$fecha <= "2015-06-19" & !(dataset$weekday  %in% c("sábado", "domingo")), 1, dataset$school)

dataset$school <- ifelse(dataset$fecha >= "2015-09-14" & dataset$fecha <= "2015-12-22" & !(dataset$weekday  %in% c("sábado", "domingo")), 1, dataset$school)

setDT(dataset)
dataset[, ':='(
  wday = as.POSIXlt(date)$wday,
  day = as.numeric(substr(date, 9,10)),
  year_day = as.POSIXlt(date)$yday+1,
  week_num = as.numeric(strftime(date,format="%W")),
  holidays_dummy = ifelse(holidays == "Normal", 0, 1)
)]


dt=dataset
dt[,date:=as.POSIXct(date)]
dt=unique(dt)
dt=dt[order(id_station,date)]

dt[,month:=month(date)]
dt[,year:=year(date)]
dt[,hour:=hour(date)]
dt[,day:=day(date)]
dt[,fecha:=as.Date(date)]
dt[hour==0 & day == 1 & month==1, fecha:=as.Date(date)+3600]

dt[,obs_hour:=shift(no2_2,1),by=id_station]
dt[,obs_hour2:=shift(no2_2,2),by=id_station]
dt[,obs_day:=shift(no2_2,1),by=c("id_station","hour")]
dt[,obs_year:=shift(no2_2,1),by=c("id_station","year_day")]
dt[,pred_hour:=shift(FC_T_2,1),by=id_station]
dt[,pred_hour2:=shift(FC_T_2,2),by=id_station]
dt[,pred_day:=shift(FC_T_2,1),by=c("id_station","hour")]
dt[,pred_year:=shift(FC_T_2,1),by=c("id_station","year_day")]
dt[,pred_Yhour:=shift(FC_Y_2,1),by=id_station]
dt[,pred_Yhour2:=shift(FC_Y_2,2),by=id_station]
dt[,pred_Yday:=shift(FC_Y_2,1),by=c("id_station","hour")]
dt[,pred_Yyear:=shift(FC_Y_2,1),by=c("id_station","year_day")]


dt2 <- dt[, list(
  max_no2_day = max(no2_2, na.rm=T),
  min_no2_day = min(no2_2, na.rm=T),
  mean_no2_day = mean(no2_2, na.rm=T),
  median_no2_day = median(no2_2, na.rm=T),
  
  max_FC_T_day = max(FC_T_2, na.rm=T),
  min_FC_T_day = min(FC_T_2, na.rm=T),
  mean_FC_T_day = mean(FC_T_2, na.rm=T),
  median_FC_T_day = median(FC_T_2, na.rm=T),
  
  max_FC_Y_day = max(FC_Y_2, na.rm=T),
  min_FC_Y_day = min(FC_Y_2, na.rm=T),
  mean_FC_Y_day = mean(FC_Y_2, na.rm=T),
  median_FC_Y_day = median(FC_Y_2, na.rm=T)
  
),
by = c("id_station", "fecha")]

dt <- merge(dt, dt2, by.x = c("id_station", "fecha"), by.y = c("id_station", "fecha"), all.x=T)

# target day by day

dt_aux=dt[,.(mean(no2_2, na.rm=T)),by=c("hour","id_station")]
ggplot(dt_aux,aes(hour,V1,col=id_station))+geom_point()+geom_line()

targetobs=dt[,.(y=any(no2_2>100)*1),by=c("fecha","id_station")]

dt <- merge(dt, targetobs, by.x=c("fecha","id_station"), by.y=c("fecha","id_station"), all.x=T)
write.table(dt, "00_Dataset/dataset_main.csv", row.names = FALSE, sep =";")

