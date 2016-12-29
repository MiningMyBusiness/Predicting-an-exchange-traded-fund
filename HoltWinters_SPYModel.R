rm(list = ls())
library(forecast)

# Predict daily change in SPY using past data
# Date created: 12-8-2016
# Kiran D Bhattacharyya

# set working directory
setwd("C:/Users/Kiran Bhattacharyya/Desktop/Kaggle/StockData/SP500")

myFiles = dir(pattern = "\\.csv$")

modelDays = 126

myPredScores = matrix(0, nrow = modelDays, ncol = (length(myFiles) - 1))

myStart = 1
myEnd = length(myFiles) - 1

modelGain = 0
modelDailySd = 0
numOfBets = 0
naiveGain = 0
naiveSd = 0

for (i in myStart:myEnd) {
	#load in file of interest
	currFile = myFiles[i]
	myData = read.csv(currFile)
	allDates = as.character(myData$Date)
	# dates of interest
	myDOI = c("2014","2015","2016")
	dailyClose = 0
	if (length(which(grepl(myDOI[1],allDates))) > 0 & (currFile != "SPY.csv")) {
	for (currDOI in 1:length(myDOI)) {
		dateIndx = which(grepl(myDOI[currDOI],allDates) == 1)
		if (currDOI == 1 & length(dateIndx) > 0) {
			dailyClose[1:length(dateIndx)] = myData$Close[dateIndx]
		}
		if (currDOI > 1) {
			dailyClose[(length(dailyClose)+1):(length(dailyClose)+length(dateIndx))] = myData$Close[dateIndx]
		}
	}
	
	predDiff = 0
	actDiff = 0
	investIter = 0
	modelInt = 0
	naiveInt = 0
	for (mySlide in 1:modelDays) {
		trainStart = mySlide
		trainEnd = length(dailyClose) - ((modelDays + 1) - mySlide)
		
		closeTimeSeries = ts(dailyClose[trainStart:trainEnd], frequency = 1)
		closeForecast = HoltWinters(closeTimeSeries, beta = FALSE, gamma = FALSE)
		closeForecast2 = predict(closeForecast, n.ahead = 1, prediction.interval = TRUE, level = 0.68)
		forecastSd = closeForecast2[1] - closeForecast2[3]
		myPredScores[mySlide,i] = (closeForecast2[1] - dailyClose[trainEnd])/dailyClose[trainEnd]
	}
	}
}

spScore = 0
spGuess = 0
for (j in 1:modelDays) {
	spScore[j] = mean(myPredScores[j,])
	spGuess[j] = (spScore[j] > 0)
}

myData = read.csv("SPY.csv")
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
}

dayOfStart = length(dailyClose) - (modelDays - 1)
dayOfEnd = length(dailyClose)
dayBeforeStart = length(dailyClose) - modelDays
dayBeforeEnd = length(dailyClose) - 1
last100Diff = (dailyClose[dayOfStart:dayOfEnd] - dailyClose[dayBeforeStart:dayBeforeEnd])/dailyClose[dayBeforeStart:dayBeforeEnd]
last100Act = rep(0,length(last100Diff))
last100Act[which(last100Diff > 0)] = 1

modelInt = last100Diff[which(spGuess == 1)] + 1
naiveInt = last100Diff + 1

modelQuarterReturn = 0
naiveQuarterReturn = 0

for (k in 1:200) {
	tradeDays = sum(runif(63,0,1) < (length(modelInt)/length(naiveInt)))
	modelQuarterReturn[k] = prod(rnorm(tradeDays, mean(modelInt), sd(modelInt)))
	naiveQuarterReturn[k] = prod(rnorm(63, mean(naiveInt), sd(naiveInt)))
}

modelYearReturn = 0
naiveYearReturn = 0

for (k in 1:200) {
	modelYearReturn[k] = prod(rnorm(4, mean(modelQuarterReturn), sd(modelQuarterReturn)))
	naiveYearReturn[k] = prod(rnorm(4, mean(naiveQuarterReturn), sd(naiveQuarterReturn)))
}






