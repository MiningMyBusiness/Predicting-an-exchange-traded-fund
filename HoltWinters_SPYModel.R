rm(list = ls())

# Predict daily change in SPY using past data
# Date created: 12-8-2016
# Author: Kiran D Bhattacharyya
# License: MIT License

# IMPORTANT USER NOTE: Please place this .R file in the same folder as the .csv files in SP500.zip after uncompressing. 

myFiles = dir(pattern = "\\.csv$") # find all files with .csv extension in the directory

modelDays = 126 # number of days to model

myPredScores = matrix(0, nrow = modelDays, ncol = (length(myFiles) - 1)) # defining the matrix which will be populated with predictions

myStart = 1
myEnd = length(myFiles)

modelGain = 0
modelDailySd = 0
numOfBets = 0
naiveGain = 0
naiveSd = 0

for (i in myStart:myEnd) {
	### Section 1: Read data
	#load in file of interest
	currFile = myFiles[i]
	myData = read.csv(currFile)
	allDates = as.character(myData$Date)
	# dates of interest
	myDOI = c("2014","2015","2016") # pull data since 2014
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
	
	### Section 2: Holt-Winters time series analysis
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
		myPredScores[mySlide,i] = (closeForecast2[1] - dailyClose[trainEnd])/dailyClose[trainEnd]
	}
	}
}

### Section 3: The prediction and comparison
spScore = 0
spGuess = 0
for (j in 1:modelDays) {
	spScore[j] = mean(myPredScores[j,])
	spGuess[j] = (spScore[j] > 0) # vector of predictions for SPY for the last 126 days
}

myData = read.csv("SPY.csv") # read in SPY data
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

# compute the actual changes in SPY over the last 126 days
dayOfStart = length(dailyClose) - (modelDays - 1)
dayOfEnd = length(dailyClose)
dayBeforeStart = length(dailyClose) - modelDays
dayBeforeEnd = length(dailyClose) - 1
last100Diff = (dailyClose[dayOfStart:dayOfEnd] - dailyClose[dayBeforeStart:dayBeforeEnd])/dailyClose[dayBeforeStart:dayBeforeEnd]
last100Act = rep(0,length(last100Diff))
last100Act[which(last100Diff > 0)] = 1 # the actual change in SPY over the last 126 days

print('Confusion Matrix')
xtabs(~spGuess + last100Act)

### Section 4: Comparing the model and naive investment strategies
modelInt = last100Diff[which(spGuess == 1)] + 1
naiveInt = last100Diff + 1

print('Model')
prod(modelInt)
prin('Naive')
prod(naiveInt)

### Section 5: Projecting into the future
modelQuarterReturn = 0
naiveQuarterReturn = 0

for (k in 1:200) {
	tradeDays = sum(runif(63,0,1) < (length(modelInt)/length(naiveInt)))
	modelQuarterReturn[k] = prod(rnorm(tradeDays, mean(modelInt), sd(modelInt)))
	naiveQuarterReturn[k] = prod(rnorm(63, mean(naiveInt), sd(naiveInt)))
}

print('Model Mean and Standard Deviation for Quarter')
mean(modelQuarterReturn)
sd(modelQuarterReturn)

print('Naive Mean and Standard Deviation for Quarter')
mean(naiveQuarterReturn)
sd(naiveQuarterReturn)

modelYearReturn = 0
naiveYearReturn = 0

for (k in 1:200) {
	modelYearReturn[k] = prod(rnorm(4, mean(modelQuarterReturn), sd(modelQuarterReturn)))
	naiveYearReturn[k] = prod(rnorm(4, mean(naiveQuarterReturn), sd(naiveQuarterReturn)))
}

print('Model Mean and Standard Deviation for Year')
mean(modelYearReturn)
sd(modelYearReturn)

print('Naive Mean and Standard Deviation for Year')
mean(naiveYearReturn)
sd(naiveYearReturn)
