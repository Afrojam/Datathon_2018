############################
#
#     HOLIDAYS
#
#############################


library(lubridate)

setwd("C:/Users/Ana/Dropbox (Personal)/Datathon_2018")

dataset <- as.data.table(read.csv("00_Dataset/dataset.csv", sep = ";"))

dataset[,month:=month(date)]
dataset[,year:=year(date)]
dataset[,hour:=hour(date)]
dataset[,day:=day(date)]
dataset[,fecha:=as.Date(date)]
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


dataset$school <- ifelse(dataset$fecha >= "2013-01-08" & dataset$fecha <= "2013-03-22" & (dataset$weekday != "sábado" | dataset$weekday != "domingo"), 1, 0)
dataset$school <- ifelse(dataset$fecha >= "2013-04-02" & dataset$fecha <= "2013-06-21" & (dataset$weekday != "sábado" | dataset$weekday != "domingo"), 1, dataset$school)

dataset$school <- ifelse(dataset$fecha >= "2013-09-12" & dataset$fecha <= "2013-12-20" & (dataset$weekday != "sábado" | dataset$weekday != "domingo"), 1, dataset$school)
dataset$school <- ifelse(dataset$fecha >= "2014-01-08" & dataset$fecha <= "2014-04-11" & (dataset$weekday != "sábado" | dataset$weekday != "domingo"), 1, dataset$school)
dataset$school <- ifelse(dataset$fecha >= "2014-04-22" & dataset$fecha <= "2014-06-20" & (dataset$weekday != "sábado" | dataset$weekday != "domingo"), 1, dataset$school)


dataset$school <- ifelse(dataset$fecha >= "2014-09-15" & dataset$fecha <= "2014-12-23" & (dataset$weekday != "sábado" | dataset$weekday != "domingo"), 1, dataset$school)
dataset$school <- ifelse(dataset$fecha >= "2015-01-08" & dataset$fecha <= "2015-03-27" & (dataset$weekday != "sábado" | dataset$weekday != "domingo"), 1, dataset$school)
dataset$school <- ifelse(dataset$fecha >= "2015-04-07" & dataset$fecha <= "2015-06-19" & (dataset$weekday != "sábado" | dataset$weekday != "domingo"), 1, dataset$school)

dataset$school <- ifelse(dataset$fecha >= "2015-09-14" & dataset$fecha <= "2015-12-22" & (dataset$weekday != "sábado" | dataset$weekday != "domingo"), 1, dataset$school)

write.csv(dataset, "00_Dataset/dataset_dates_holidays.csv", row.names=FALSE)