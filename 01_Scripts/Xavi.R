# Xavi

# Prova xgboost

library(xgboost)
library(data.table)
library(caret)

DF <- read.csv("C:/Users/xavier.ros.roca/Desktop/Datathon_2018/00_Dataset/madrid_data.csv", sep=";")
DF$fecha <- as.POSIXct(DF$fecha, format="%d/%m/%Y %H:%M")

Y_name <- "no2"

covariatesUse <- names(DF)[names(DF) != Y_name]
setDT(DF)


compute_distance <- function(lat1, lon1, lat2, lon2) {
  R <- 6371
  
  dlat <- (lat2-lat1)*pi/180
  dlon <- (lon2-lon1)*pi/180
  
  a <- sin(dlat/2)^2 + cos(lat1*pi/180)*cos(lat2*pi/180) * sin(dlon/2)^2
  
  c= 2*atan2(sqrt(a), sqrt(1-a))
  d = R*c
  return(d)
}


my_accuracy <- function(v_real, v_FC) {
  return (sqrt(sum((v_real-v_FC)^2/length(v_real))))
}


fit <- as.formula(paste(Y_name, "~", paste(covariatesUse, collapse = "+")))
model2 <- DF[complete.cases(DF[, .SD, .SDcols = c(covariatesUse)])]

# Perform a cross-validation.
number.of.folds <- 5
set.seed(1234)
train <- copy(model2)
input.variables <- covariatesUse
# test.fold <- 1
folds <- createFolds(train$no2, k = number.of.folds, list = T)
total.accuracy <- data.table()
ACC <- c()
for(test.fold in 1:number.of.folds) {
  # Divide into train and test.
  train.fold.indices <- which(!(1:number.of.folds) %in% test.fold) 
  training.data <- train[ unlist(folds[train.fold.indices]), ]
  test.data <- train[ folds[[test.fold]], ]
  # The model.
  dm.train  <- xgb.DMatrix(data = data.matrix(training.data[,.SD, .SDcols = (names(training.data) %in% c(input.variables))]),
                           label = training.data$no2, missing = NA)
  dm.test  <- xgb.DMatrix(data = data.matrix(test.data[,.SD, .SDcols = (names(test.data) %in% c(input.variables))]),
                          label = test.data$no2, missing = NA)
  set.seed(1234)
  clf <- xgboost(data = dm.train,
                 nrounds = 900,
                 booster = "gbtree",
                 objective = "reg:linear",
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
  FC_no2 <- predict(clf, dm.test)
  acc_value <- my_accuracy(test.data$no2, FC_no2)
  accuracy <- data.table(Fold = test.fold, 
                         id_estacion = test.data$id_estacion, 
                         no2 = test.data$no2,
                         FC_no2 = FC_no2, 
                         accuracy = acc_value)
  ACC <- c(ACC, acc_value)
  total.accuracy <- rbind(total.accuracy, accuracy)
  
}
print(ACC)
summary(total.accuracy)