# Miquel
library(data.table)
library(ggplot2)
library(lubridate)
library(randomForest)
library(caret)
library(Metrics)
library(Cubist)
dt=fread("00_Dataset/dataset_main.csv",sep=";")
dt[,date:=as.POSIXct(date)]
dt=unique(dt)
dt=dt[order(id_station,date)]



dat<-dt[year==2014,-c("date","lat","lon", "day","fecha","holidays","wday","year_day","week_num","y","FC_today","FC_yesterday"),with=FALSE]
dat[,hour:=as.factor(hour)]
dat[,month:=as.factor(month)]
dat[,weekday:=as.factor(weekday)]
dat[,id_station:=as.factor(id_station)]
dummy<-dummyVars( ~weekday+hour+month+id_station, data = dat, sep=NULL)
colin<-colnames(dat[,-c("weekday","hour","month","id_station","no2"),with=FALSE])
# colin<-c("no2_2","height","FC_T_2","FC_Y_2","school","holidays_dummy",
#          "obs_hour","obs_day", "pred_hour", "pred_day","pred_year","pred_Yhour","pred_Yday","pred_Yyear")
dataset <- cbind.data.frame(dat[,..colin], as.data.frame(predict(dummy, newdata = dat)))


control <- trainControl(method="cv",
                        number=2,
                        verboseIter = TRUE,
                        allowParallel = TRUE)

seed <- 7
metric <- "RMSE"
tunegrid <- expand.grid(committees=c(4), neighbors=c(5))
rf_default <- train(no2_2~.,
                    data=dataset,
                    method="cubist",
                    metric=metric,
                    tuneGrid=tunegrid,
                    trControl=control)

plot(rf_default)
# probability model
dataset[,y:=ifelse(no2_2>100,1,0)]
dataset[,y:=factor(y, levels = c(0,1), labels = c("no", "yes"))]
metric <- "ROC"
control <- trainControl(method = "cv",
                     number = 2,
                     summaryFunction = twoClassSummary,
                     classProbs = TRUE,
                     verboseIter = TRUE,
                     allowParallel = TRUE)
rf_prob <- train(y~.,
                    data=dataset,
                    method="cubist",
                    metric=metric,
                    tuneGrid=tunegrid,
                    trControl=control)

save(rf_default, file = "cubist_reg.rdata")
# save(rf_prob, file = "cubist_prob.rdata")

dat[,pred_reg:=predict(rf_default,dataset)]
dt2=cbind.data.frame(dt[year==2014],dat$pred_reg)
dt2=dt2[,.(date,id_station,prob_NO2=V2)]
write.table(dt2,"00_Dataset/cubist_2014.csv",sep=";", row.names = FALSE)
dttt=fread("00_Dataset/cubist_2014.csv",sep=";")
dt2[,.(date,id_station,prob_NO2=V2)]
mape(dat$pred_reg,dat$no2_2)
dat[,pred_prob:=predict(rf_prob,dataset, type ="prob")]
mape(dat$pred_reg,dat$no2_2)
