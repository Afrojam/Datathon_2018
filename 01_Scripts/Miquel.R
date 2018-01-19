# Miquel
library(data.table)
library(ggplot2)
library(lubridate)
dt=fread("00_Dataset/madrid_data.csv")

dt[,day:=as.Date(fecha,format="%d/%m/%Y")]
dt[,fecha:=strptime(fecha,format='%d/%m/%Y %H:%M')]
dt[,month:=month(fecha)]
dt[,hour:=hour(fecha)]
dt=unique(dt)
hour1=3600
day1=3600*24
hours=as.numeric(dt$fecha)-min(as.numeric(dt$fecha))
hours/3600
dtday=dt[,.(mean(no2)),by=day]
ggplot(dt[,.(mean(no2)),by=hour],aes(x=hour,y=V1))+geom_point()+geom_line()
dt[,.(fecha-hour1)]
dt[,.(fecha-day1)]
       
dt[id_estacion==28079004 & day=="2016-04-18"]
ggplot(dt[id_estacion==28079060],aes(x=fecha,y=no2,group=id_estacion,col=as.factor(id_estacion)))+
  geom_point()+geom_line()
dt[id_estacion==28079060]$no2

fitNile <- StructTS(dt[id_estacion==28079060]$no2, "level")
plot(dt[id_estacion==28079060]$no2, type = "o")
lines(fitted(fitNile), lty = "dashed", lwd = 2)
lines(tsSmooth(fitNile), lty = "dotted", lwd = 2)
Nile[c(5,6,7,8,9,19)]<-NA
library(forecast)
plot(forecast(fitNile, level = c(50, 90), h = 10), xlim = c(1950, 1980))
library(dlm)
library(stats)
library(numDeriv)
buildNile <- function(theta) {
  dlmModPoly(order = 1, dV = theta[1], dW = theta[2])
}
fit <- dlmMLE(Nile, parm = c(100, 2), buildNile, lower = rep(1e-4, 2))
hs <- hessian(function(x) dlmLL(Nile, buildNile(x)), fit$par)
all(eigen(hs, only.values = TRUE)$values > 0)
aVar <- solve(hs)
