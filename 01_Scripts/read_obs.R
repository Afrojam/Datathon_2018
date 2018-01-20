# Miquel
setwd("~/Desktop/Datathon_2018")
setwd("~/Desktop/datathon")
library(data.table)
data=data.table(id_station=character(), no2=numeric(), fecha=character())
for(year in 2013:2015){
  listfiles<-list.files(path = paste0("obs/",year), pattern = ".csv")
  dt<-data.table()
  for(i in listfiles){
    stat=strsplit(i,"\\_|\\.")[1]
    dt_aux=fread(paste0("obs/",year,"/",i))
    dt_aux=dt_aux[,c(4,12,14),with=FALSE]
    colnames(dt_aux)<-c("id_station","no2","fecha")
    data<-rbind.data.frame(data,dt_aux)
  }
}
stations=fread("stations.csv")[,c(1,3,4,5)]
data[,id_station:=gsub("STA_","",id_station)]
data=merge(data,stations,by.x="id_station",by.y = "code")
data[,fecha:=as.POSIXct(fecha)]
