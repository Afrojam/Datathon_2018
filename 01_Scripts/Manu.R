results_join <- read.table("C:/Users/xavier.ros.roca/Downloads/results_join_5.txt", quote="\"", comment.char="")
targets <- fread("00_Dataset/Original_Folder/targets.csv", sep=",")
targets <- targets[,date := as.Date(date)]

days_to_predict <- unique(as.character(targets$date))


DTP <- rep(days_to_predict, 7)
DTP <- DTP[order(DTP)]


st <- unique(targets$station)
st <- st[order(st)]
st <- rep(st, 121)

A <- data.frame(date = as.character(DTP), station = as.character(st), target = results_join$V1 )
setDT(A)
A$date <- as.Date(A$date)
A$station <- as.character(A$station)

to_deliver <- merge(targets[, c("date", "station")], A, by.x= c("date", "station"), by.y= c("date", "station"), all.x=T)
to_deliver <- to_deliver[, c("target")]

write.table(to_deliver, "02_Submissions/wax_to_deliver3.csv", sep=",", row.names = F)
