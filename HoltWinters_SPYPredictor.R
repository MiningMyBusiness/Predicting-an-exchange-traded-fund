rm(list = ls())
library(forecast)

# Predict daily change in stocks using past data
# Date created: 12-15-2016
# Kiran D Bhattacharyya

# set working directory
setwd("C:/Users/Kiran Bhattacharyya/Desktop/Kaggle/StockData/SP500")

myFiles = dir(pattern = "\\.csv$")
predStocks = read.csv("C:/Users/Kiran Bhattacharyya/Desktop/Kaggle/StockData/SimpleModel2Candidates.csv")

myStart = 1
myEnd = nrow(predStocks)

predPrice = 0
predSd = 0
diffScore = 0 
upOrDown = 0

for (i in myStart:myEnd) {
	#load in file of interest
	currFile = as.character(predStocks$predTickers[i])
	myData = read.csv(currFile)
	allDates = as.character(myData$Date)
	# dates of interest
	myDOI = c("2014","2015","2016")
	dailyClose = 0
	if (length(which(grepl(myDOI[1],allDates))) > 0) {
	for (currDOI in 1:length(myDOI)) {
		dateIndx = which(grepl(myDOI[currDOI],allDates) == 1)
		if (currDOI == 1 & length(dateIndx) > 0) {
			dailyClose[1:length(dateIndx)] = myData$Close[dateIndx]
		}
		if (currDOI > 1) {
			dailyClose[(length(dailyClose)+1):(length(dailyClose)+length(dateIndx))] = myData$Close[dateIndx]
		}
	}

	trainStart = 1 # length(dailyClose) - 643
	trainEnd = length(dailyClose)

	closeTimeSeries = ts(dailyClose[trainStart:trainEnd], frequency = 1)
	closeForecast = HoltWinters(closeTimeSeries, beta = FALSE, gamma = FALSE)
	myForecast = predict(closeForecast, n.ahead = 1, prediction.interval = TRUE, level = 0.68)
	predPrice[i] = myForecast[1]
	predSd[i] = myForecast[1] - myForecast[3]
	diffScore[i] = (predPrice[i] - dailyClose[trainEnd])/dailyClose[trainEnd]
	upOrDown[i] = diffScore[i] > 0
	}
}

myTickers = predStocks$predTickers
mySd = predStocks$predModelDailySd
day100Gain = predStocks$predModel

dailyPred = data.frame(myTickers, upOrDown, mySd, day100Gain, predPrice, diffScore)

byScore = sort(diffScore, index.return = TRUE)

dailyPred[byScore$ix,]