
library(data.table)
library(ggplot2)
library(lubridate)
library(imputeTS)

source("01_Scripts/KFunctions.R")

dt_obs=fread("00_Dataset/obs_complete.csv",sep=";")
dt_cal=fread("00_Dataset/caliope_data.csv",sep=";")
dt_obs[,date:=as.POSIXct(date)]
dt_cal[,date:=as.POSIXct(date)]

dt_cal <- dt_cal[, c("station", "date", "FC_today", "FC_yesterday")]

dt <- merge(dt_obs, dt_cal, by.x = c("id_station", "date"), by.y= c("station", "date"), all=T)
dt=dt[order(id_station, date)]

stations <- unique(dt$id_station)
require(xts)
require(forecast)
for (i in stations){
  dt_st <- dt[id_station == i]
  ts <- xts(dt_st$no2, order.by = dt_st$date)
  plot(ts)
  
  y=ts
  y[is.na(y)]=0
  num=length(y)
  A=rep(list(1),num+1)
  for(i in 1:num){
    if (y[i]==0) A[[i+1]]=matrix(0)
  }
  
  mu0=matrix(y[3])
  Sigma0=matrix(100)
  cR=matrix(1e-6)
  
  ## Función de verosimilitud para estimar los parámetros
  Linn=function(param){
    Phi=matrix(param[1])
    cQ=matrix(param[2])
    kf=Kfilter(num,y,A,mu0,Sigma0,Phi,cQ,cR)
    return(kf$like)
  }
  
  
  ## Estimación de los parámetros
  initpar=c(1,1)
  est=optim(initpar,Linn,NULL,method="BFGS",hessian=TRUE)
  stderr=sqrt(diag(solve(est$hessian)))
  Phi=est$par[1]
  # quasi 1... bon ull!
  cQ=est$par[2]
  Q = round(cQ %*% t(cQ), 4)
  Phi_w = round(Phi, 4)
  
  
  ks1=Ksmooth(num,y,A,mu0, Sigma0,Phi,cQ,cR)
  
  ## Extracción del alisado y su varianza
  smo1=ts(data.frame(GDP=unlist(ks1$xs)[-1]),start=c(1996,1),freq=12)
  Psmo1=ts(data.frame(GDP=unlist(ks1$Ps)[-1]),start=c(1996,1),freq=12)
  
  ## Intervalos de confianza 95% para el estado, basados en el alisado
  llim1=smo1+qnorm(0.025)*sqrt(Psmo1)
  ulim1=smo1+qnorm(0.975)*sqrt(Psmo1)
  nrow(smo1)
  nrow(y)
  
  View(cbind(y,smo1))

}






dt <- dt[!is.na(height)]






write.table(dt, "00_Dataset/dataset.csv", row.names = FALSE, sep=";")

