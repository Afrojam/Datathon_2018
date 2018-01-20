# Xavi

# Prova xgboost

library(xgboost)
library(data.table)
library(caret)

DF <- fread("00_Dataset/dataset.csv", sep=";")

DF <- DF[year %in% c(2013, 2014)]
DF[,is_high100 := ifelse(no2_2 > 100, 1, 0)]

Y_name <- "is_high100"
exclude_names <- c("no2", "no2_2")

covariatesUse <- names(DF)[! names(DF) %in%  c(Y_name, exclude_names)]
setDT(DF)


#########################################################################
# Feature Engineering

DF[ , wday := as.POSIXlt(DF$date)$wday]

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


my_accuracy <- function(v_real, v_FC) {
  
  V <- -(log(v_FC)*v_real)
  
  return (V)
}


fit <- as.formula(paste(Y_name, "~", paste(covariatesUse, collapse = "+")))
model2 <- DF[complete.cases(DF[, .SD, .SDcols = c(covariatesUse)])]

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
  dm.train  <- xgb.DMatrix(data = data.matrix(training.data[,.SD, .SDcols = (names(training.data) %in% c(input.variables))]),
                           label = training.data[, get(Y_name)], missing = NA)
  dm.test  <- xgb.DMatrix(data = data.matrix(test.data[,.SD, .SDcols = (names(test.data) %in% c(input.variables))]),
                          label = test.data[, get(Y_name)], missing = NA)
  set.seed(1234)
  clf <- xgboost(data = dm.train,
                 nrounds = 900,
                 booster = "gbtree",
                 objective = "binary:logistic",
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
  # Compute prediction.
  Y_pred <- predict(clf, dm.test)
  acc_value <- my_accuracy(test.data[,get(Y_name)], Y_pred)
  accuracy <- data.table(Fold = test.fold, 
                         id_estacion = test.data$id_station, 
                         real_value = test.data$is_high100,
                         prob_value = Y_pred, 
                         accuracy = acc_value)
  s_acc <- sum(acc_value)/length(acc_value)
  ACC <- c(ACC, s_acc)
  total.accuracy <- rbind(total.accuracy, accuracy)
  
}
print(ACC)
summary(total.accuracy)