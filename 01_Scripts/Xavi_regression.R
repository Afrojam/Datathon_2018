# Xavi

# Prova xgboost

library(xgboost)
library(data.table)
library(caret)

DF <- fread("00_Dataset/dataset_main.csv", sep=";")

DF <- DF[year %in% c(2013, 2014)]
DF[,is_high100 := ifelse(no2_2 > 100, 1, 0)]
DF$id_station <- as.factor(DF$id_station)

Y_name <- "is_high100"
exclude_names <- c("fecha", "date","no2", "FC_today", "FC_yesterday", "date", "weekday", "Date", "holidays", "y", "no2_2")

setDT(DF)


#########################################################################
# Feature Engineering

stations <- unique(DF[, c("id_station", "lat", "lon")])

compute_distance <- function(lat1, lon1, lat2, lon2) {
  R <- 6371
  
  dlat <- (lat2-lat1)*pi/180
  dlon <- (lon2-lon1)*pi/180
  
  a <- sin(dlat/2)^2 + cos(lat1*pi/180)*cos(lat2*pi/180) * sin(dlon/2)^2
  
  c= 2*atan2(sqrt(a), sqrt(1-a))
  d = R*c
  return(d)
}

cross_st <- as.data.table(t(combn(stations$id_station, 2)))
setDT(cross_st)
setnames(cross_st, "V1", "sta1") 
setnames(cross_st, "V2", "sta2") 
cross_st <- merge(cross_st, stations, by.x = "sta1", by.y="id_station", all.x=T)
setnames(cross_st, "lat", "lat1")
setnames(cross_st, "lon", "lon1")
cross_st <- merge(cross_st, stations, by.x = "sta2", by.y="id_station", all.x=T)
setnames(cross_st, "lat", "lat2")
setnames(cross_st, "lon", "lon2")

D <- c()
for (i in 1:nrow(cross_st)) {
  line <- cross_st[i,]
  d <- compute_distance(as.numeric(line$lat1), 
                        as.numeric(line$lon1),
                        as.numeric(line$lat2),
                        as.numeric(line$lon2))
  D <- c(D, d)
  
}

cross_st$dist <- D

#########################################################################

my_accuracy <- function(v_real, v_FC) {
  
  V <- -(log(v_FC)*(1-v_real)+(v_real)*log(1-v_FC))
  
  return (V)
}

MAPE_accuracy <- function(v_real, v_FC) {
  
  V <- (abs(v_real-v_FC))/v_real
  
  return (V)
}

covariatesUse <- names(DF)[! names(DF) %in%  c(Y_name, exclude_names)]
fit <- as.formula(paste(Y_name, "~", paste(covariatesUse, collapse = "+")))
model2 <- DF[complete.cases(DF[, .SD, .SDcols = c(covariatesUse)])]
model2 <- model2[, c(covariatesUse, Y_name), with=FALSE]

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
  
  name_clf <- paste0("clf_reg_", test.fold)
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

training.data <- model2
# The model.
dm.train  <- xgb.DMatrix(data = data.matrix(training.data[,.SD, .SDcols = covariatesUse]),
                         label = training.data[, get(Y_name)], missing = NA)
set.seed(1234)
clf_reg_TOTAL <- xgboost(data = dm.train,
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

summary(predict(clf_reg_TOTAL, dm.train))


