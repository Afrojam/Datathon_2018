#  model data

library(data.table)
library(stringr)

path_line <- "00_Dataset/Original_Folder/mod/"
years <- c("2013", "2014","2015")

DF_all <- data.table()
for (i in years) {
  LF <- list.files(paste0(path_line, i))
  print(i)
  for (L in LF) {
    id <- substr(L, 14, 20)
    DF <- fread(paste0(paste0(path_line, i, "/", L)))
    names(DF) <- c("lat", "long", "fecha_1", "H", "X", "NO2")
    
    if(substr(L, 1, 8) %in% c("20150804", "20150824", "20150826",
                              "20150924")) {
      DF <- DF[, date := as.POSIXct(paste0(fecha_1, " ", H), format = "%Y%m%d %H:%M:%S")]
    }else{
      DF <- DF[, date := as.POSIXct(paste0(fecha_1, " ", H))]
    }
    
    DF[, short_date := ifelse(str_replace_all(substr(DF$date,1,10), "-", "") == substr(L, 1, 8), "P0", "P1")]
    
    
    
    DF <- DF[, station := id]
    
    DF <- dcast(DF, station + lat + long + date~ short_date, value.var = "NO2")
    
    DF <- DF[, c("lat", "long", "date", "station", "P0", "P1")]
    
    DF_all <- rbind(DF_all, DF)
    
  }
  
}

DF_all2 <- DF_all[, list(
  P0_sum = sum(P0, na.rm=T),
  P1_sum = sum(P1, na.rm = T)
), by = c("lat", "long", "date", "station")]

setnames(DF_all2, "P0_sum", "P0")
setnames(DF_all2, "P1_sum", "P1")

DF_all2[P0 ==0]$P0 <- NA
DF_all2[P1 ==0]$P1 <- NA

times=as.POSIXct("2013-01-01 00:00:00" )+(1:(365*3*24-1))*3600
stat= unique(DF_all2$station)
dat=expand.grid(stat,times)
dt=merge(DF_all2,dat,by.x = c("station","date"),by.y = c("Var1","Var2"),all = TRUE)

write.table(dt, "00_Dataset/model_data.csv")

