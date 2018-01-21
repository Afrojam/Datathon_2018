setwd("C:/Users/Ana/Dropbox (Personal)/Datathon_2018")

library(caret)
library(data.table)
library(Metrics)

dataset <- as.data.table(read.csv("00_Dataset/dataset_main.csv", sep = ";"))
dataset$id_row <- rownames(dataset)


##### LINEAR MODEL ######
dataset_train <- dataset[, c("id_row", "id_station", "school", "holidays_dummy", "obs_hour", 
                                   "obs_day", "month", "weekday", "year", "hour", "no2_2", "y")]

dataset_train$month <- as.factor(as.character(dataset_train$month))
dataset_train$hour <- as.factor(as.character(dataset_train$hour))
dataset_train_train <- dataset_train[dataset_train$year == 2014,]
dataset_train_train$year <- NULL
dataset_train_train$y <- NULL

id_row_train_train <- dataset_train$id_row
id_row_train_train$id_row <- NULL

apply(dataset_train_train, 2, function(x) any(is.na(x)))

lmFit <- train(no2_2 ~ ., data = dataset_train_train, method = 'lm')
summary(lmFit)

predictedVal <- predict(lmFit, dataset_train[dataset_train$year == 2015,])
modelvalues <- data.frame(obs = dataset_train[dataset_train$year == 2015,]$no2_2, pred = predictedVal)
modelvalues$abserror <- abs(modelvalues$obs - modelvalues$pred)

mape(modelvalues$obs, modelvalues$pred)


##### LOGISTIC REGRESSION ######
dataset_train <- dataset[, c("id_row", "id_station", "school", "holidays_dummy", "obs_hour", 
                             "obs_day", "obs_year", "month", "weekday", "year", "hour", "y")]

dataset_train$month <- as.factor(as.character(dataset_train$month))
dataset_train$hour <- as.factor(as.character(dataset_train$hour))
dataset_train_train <- dataset_train[dataset_train$year == 2014,]
dataset_train_train$year <- NULL
dataset_train_train$y <- as.factor(as.character(dataset_train_train$y))

id_row_train_train <- as.factor(dataset_train_train$id_row)
dataset_train_train$id_row <- NULL

apply(dataset_train_train, 2, function(x) any(is.na(x)))


logFit <- train(y ~ ., data = dataset_train_train, method="glm", 
                family="binomial")

summary(logFit)

predictedVal <- predict(logFit, dataset_train[dataset_train$year == 2014,], type="prob")[,2]

modelvalues <- data.frame(id_row = dataset_train[dataset_train$year == 2014,]$id_row, obs = dataset_train[dataset_train$year == 2014,]$y, prob = predictedVal)

dataset_train <- merge(dataset_train, modelvalues[,c(1,3)], by = c("id_row"))

dataset_Manu <- merge(dataset, modelvalues[,c(1,3)], by = c("id_row"))
dataset_Manu <- dataset_Manu[,c("date", "id_station", "prob")]
colnames(dataset_Manu) <- c("fecha", "id_station", "prob")

write.csv(dataset_Manu, "00_Dataset/lg_2014.csv", row.names = FALSE)

logLoss = function(actual, pred){
  -1*mean(log(pred[model.matrix(~ actual + 0) - pred > 0]))
}

logLoss(modelvalues$obs, modelvalues$prob)

predictedVal <- predict(logFit, dataset_train[dataset_train$year == 2014,])


