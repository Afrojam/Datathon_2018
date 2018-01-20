###################################
#
#         # FINAL SUBMISSION
#
###################################

# Read csv
path <- "~/Datathon_2018/00_Dataset/"
dataName <- "data.csv"
finalData <- read.csv(paste0(path, dataName))


# Order columns
finalData <- finalData[order(finalData$date, finalData$station),]

# Seect probability
finalSubmission <- finalData$prob

write.csv(finalSubmission, "submission.csv", row.names = FALSE)