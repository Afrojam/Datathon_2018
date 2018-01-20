# Read Obs
setwd("~/Desktop/Datathon_2018")
setwd("~/Desktop/datathon")
library(data.table)
data=data.table(id_station=character(), no2=numeric(), date=character())
for(year in 2013:2015){
  listfiles<-list.files(path = paste0("obs/",year), pattern = ".csv")
  dt<-data.table()
  for(i in listfiles){
    dt_aux=fread(paste0("obs/",year,"/",i))
    dt_aux=dt_aux[,c(4,12,14),with=FALSE]
    colnames(dt_aux)<-c("id_station","no2","date")
    data<-rbind.data.frame(data,dt_aux)
  }
}
data=unique(data)
data[,id_station:=gsub("STA_","",id_station)]
data[,date:=as.POSIXct(date)]

# Creating complete data
times=as.POSIXct("2013-01-01 00:00:00" )+(1:(365*3*24-1))*3600
stat=stations$code
dat=expand.grid(stat,times)
dt=merge(data,dat,by.x = c("id_station","date"),by.y = c("Var1","Var2"),all = TRUE)

dt[,month:=month(date)]
dt[,year:=year(date)]
dt[,hour:=hour(date)]


stations=fread("stations.csv")[,c(1,3,4,5)]
dt=merge(dt,stations,by.x="id_station",by.y = "code")
dt[,date:=as.POSIXct(date)]
fwrite(dt,"00_Dataset/obs_complete.csv")

data[is.na(no2)]
