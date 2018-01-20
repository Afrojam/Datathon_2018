library(xgboost)
library(data.table)
library(caret)

DF_h <- fread("00_Dataset/new_dataset_hours.csv", sep=";")

DF_h$date <- as.Date(DF_h$fecha)
DF_h$id_station <- as.factor(DF_h$id_station)
DF_h[, y:= ifelse(col_count>0, 1, 0)]

DF <- fread("00_Dataset/dataset_main.csv", sep=";")
DF$date <- as.Date(DF$date)
DF$fecha <- NULL

DF2 <- DF[, list(
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
by = c("id_station", "date")]

DF_perhour <- DF

DF_covariates <- unique(DF[, c("date", "id_station", "month", "year", "lat", "lon", 
                               "height", "day", "school", "wday", "year_day",
                               "week_num", "holidays_dummy")])

DF_all <- merge(DF_h, DF_covariates, by.x=c("id_station", "date"), by.y=c("id_station", "date"))

Y_name <- "y"
exclude_names <- c("fecha", "date","no2", "FC_today", "FC_yesterday", "date", "weekday", "Date", "holidays", "y", "no2_2")

#####


my_accuracy <- function(v_real, v_FC) {
  
  V <- -(log(v_FC)*(1-v_real)+(v_real)*log(1-v_FC))
  
  return (V)
}

MAPE_accuracy <- function(v_real, v_FC) {
  
  V <- (abs(v_real-v_FC))/v_real
  
  return (V)
}

DF <- DF_all
DF$id_station <- as.factor(DF$id_station)
covariatesUse <- names(DF)[! names(DF) %in%  c(Y_name, exclude_names)]
fit <- as.formula(paste(Y_name, "~", paste(covariatesUse, collapse = "+")))
model2 <- DF[complete.cases(DF[, .SD, .SDcols = c(covariatesUse)])]
model2 <- model2[, c(covariatesUse, Y_name), with=FALSE]
model2 <- model2[year %in% c(2013,2014)]

# Perform a cross-validation.
number.of.folds <- 5
set.seed(1234)
train <- copy(model2)
input.variables <- covariatesUse
# test.fold <- 1
folds <- createFolds(train[, get(Y_name)], k = number.of.folds, list = T)
total.accuracy <- data.table()
ACC <- c()
for(test.fold in 1:number.of.folds) {
  # Divide into train and test.
  train.fold.indices <- which(!(1:number.of.folds) %in% test.fold) 
  training.data <- train[ unlist(folds[train.fold.indices]), ]
  test.data <- train[ folds[[test.fold]], ]
  # The model.
  dm.train  <- xgb.DMatrix(data = data.matrix(training.data[,.SD, .SDcols = covariatesUse]),
                           label = training.data[, get(Y_name)], missing = NA)
  dm.test  <- xgb.DMatrix(data = data.matrix(test.data[,.SD, .SDcols = covariatesUse]),
                          label = test.data[, get(Y_name)], missing = NA)
  set.seed(1234)
  clf <- xgboost(data = dm.train,
                 nrounds = 1000,
                 booster = "gbtree",
                 objective = "reg:logistic",
                 tree_method = "approx",
                 eta = 0.01,
                 nthread = 6,
                 max_depth =15,
                 subsample = 0.95, 
                 colsample_bytree = 0.95, 
                 min_child_weight = 1,
                 gamma = 0.0,
                 #watchlist = watchlist, 
                 #early.stop.round = 50, 
                 maximize = T,
                 verbose = 1
  )  
  
  name_clf <- paste0("xgb_fin_reg_", test.fold)
  assign(name_clf, clf)
  # Compute prediction.
  Y_pred <- predict(get(name_clf), dm.test)
  acc_value <- my_accuracy(test.data[,get(Y_name)], Y_pred)
  accuracy <- data.table(Fold = test.fold, 
                         id_estacion = test.data$id_station, 
                         real_value = test.data[, get(Y_name)],
                         prob_value = Y_pred, 
                         accuracy = acc_value)
  s_acc <- sum(acc_value)/length(acc_value)
  ACC <- c(ACC, s_acc)
  total.accuracy <- rbind(total.accuracy, accuracy)
  
  # mat <- xgb.importance (feature_names = covariatesUse, model = clf)
  # xgb.plot.importance (importance_matrix = mat[1:20])
  
}


print(ACC)
summary(total.accuracy)


dm.train  <- xgb.DMatrix(data = data.matrix(train[,.SD, .SDcols = covariatesUse]),
                         label = train[, get(Y_name)], missing = NA)
set.seed(1234)
clf <- xgboost(data = dm.train,
               nrounds = 1000,
               booster = "gbtree",
               objective = "reg:logistic",
               tree_method = "approx",
               eta = 0.01,
               nthread = 6,
               max_depth =15,
               subsample = 0.95, 
               colsample_bytree = 0.95, 
               min_child_weight = 1,
               gamma = 0.0,
               #watchlist = watchlist, 
               #early.stop.round = 50, 
               maximize = T,
               verbose = 1
)  

name_clf <- ("xgb_fin_reg_TOTAL")
assign(name_clf, clf)



#########################

targets <- fread("00_Dataset/Original_Folder/targets.csv", sep=",")
targets <- targets[,date := as.Date(date)]

days_to_predict <- unique(as.character(targets$date))
DF_perhour$id_station <- as.factor(DF_perhour$id_station)
covariatesUse_hourly <- covariatesUse_hourly[1:(length(covariatesUse_hourly)-1)]


target_xgb <- data.table()
for(i in days_to_predict){
  print(i)
  DF_available <- DF_all[date <= i]
  
  A <- DF_perhour[date == i]
  dm.train  <- xgb.DMatrix(data = data.matrix(A[,.SD, .SDcols = covariatesUse_hourly]),
                           label = A[, get(Y_name_hourly)], missing = NA)
  A$no2_FC <- predict(clf_TOTAL,dm.train)
  
  values <- dcast(A, date+id_station ~ hour, fun=sum,value.var="no2_FC")
  
  DF_today <- DF_available[date==i]
  DF_other <- DF_available[date!=i]
  
  DF_today2 <- merge(DF_today[, c("id_station", "date",     "fecha","col_count","y", "month",  
               "year","lat", "lon", "height",  "day", "school", "wday","year_day" ,"week_num","holidays_dummy")],
        values, by.x =c("id_station", "date"), by.y=c("id_station", "date")) 
  
  DF_ava2 <- DF_today2
  
  
  dm.train  <- xgb.DMatrix(data = data.matrix(DF_ava2[,.SD, .SDcols = covariatesUse]),
                           label = DF_ava2[, get(Y_name)], missing = NA)
  
  DF_ava2$target <- predict(xgb_fin_reg_TOTAL, dm.train)
  
  targ_prov <- DF_ava2[, c("id_station", "target")]
  targ_prov$date <- as.Date(i, origin = "1970-01-01")
  
  
  target_xgb <- rbind(target_xgb, targ_prov)
  
}

to_deliver_xgb <- merge(targets[,c("date", "station")], target_xgb, by.x=c("date", "station"), by.y =c("date", "id_station"), all.x=T)

write.table(to_deliver_xgb, "02_Submissions/xgb_to_deliver.csv", sep=",", row.names = F)

