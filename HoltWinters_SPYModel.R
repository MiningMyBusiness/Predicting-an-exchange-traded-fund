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
# compute mean estimate for each of the 126 days based on the Holt Winter's model
spScore = 0
for (j in 1:modelDays) {
	spScore[j] = mean(myPredScores[j,])
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

# compute sensitivity and specificty of this model
scoreDiff = max(spScore) - min(spScore)
myDivis = 1000
scoreSeq = seq(min(spScore) + (scoreDiff/myDivis),max(spScore) - (scoreDiff/myDivis),
			scoreDiff/myDivis)
truePos = 0
trueNeg = 0
for (i in 1:length(scoreSeq)) {
	fakeGuess = rep(0,length(spScore))
	fakeGuess[which(spScore > scoreSeq[i])] = 1
	confMat = xtabs(~fakeGuess + last100Act)
	truePos[i] = confMat[2,2]/sum(confMat[,2])
	trueNeg[i] = confMat[1,1]/sum(confMat[,1])
}

# plot sensitvity and specificity curve
plot(scoreSeq, truePos, type = 'l', lwd = 2, col = 4, xlab = 'Holt Winters Estimate', ylab = 'Proportion')
lines(scoreSeq, trueNeg, lwd = 2, col = 2)
title('Specificity vs. Sensitivity')
legend('topright',c('True Positive', 'True Negative'), text.col = c(4,2))

# find and plot the point of intersection for the two curves
trueDiffs = abs(truePos - trueNeg)
myThreshIndx = which(trueDiffs == min(trueDiffs))
points(scoreSeq[myThreshIndx], (truePos[myThreshIndx] + trueNeg[myThreshIndx])/2, pch = "O", col = 1, cex = 2)
abline(v = scoreSeq[myThreshIndx], lty = 2)

# compute the confusions matrix for based on the ideal threshold score
myThresh = scoreSeq[myThreshIndx]
spGuess = rep(0,length(spScore))
spGuess[which(spScore > myThresh)] = 1

print('Confusion Matrix')
xtabs(~spGuess + last100Act)

### Section 4: Comparing the model and naive investment strategies
modelInt = last100Diff[which(spGuess == 1)] + 1
nonModelInt = last100Diff[which(spGuess == 0)] + 1
naiveInt = last100Diff + 1

print('Model')
prod(modelInt)
prin('Naive')
prod(naiveInt)

### Section 5: Projecting into the future
# compute monthly return through bootstrapping daily model and naive returns
modelMonthReturn = 0
naiveMonthReturn = 0

for (k in 1:1000) {
	tradeDays = sum(runif(21,0,1) < (length(modelInt)/length(naiveInt)))
	modelIntSample = sample(modelInt, tradeDays, replace = TRUE)
	naiveIntSample = c(modelIntSample, sample(nonModelInt, 21 - tradeDays, replace = TRUE))
	modelMonthReturn[k] = prod(modelIntSample)
	naiveMonthReturn[k] = prod(naiveIntSample)
}

# compute quarterly returns by bootstrapping monthly returns
modelQuarterReturn = 0
naiveQuarterReturn = 0

for (k in 1:2000) {
	modelQuarterReturn[k] = prod(sample(modelMonthReturn, 3, replace = TRUE))
	naiveQuarterReturn[k] = prod(sample(naiveMonthReturn, 3, replace = TRUE))
}

# compute yearly returns by bootstrapping quarterly returns
modelYearReturn = 0
naiveYearReturn = 0

for (k in 1:2000) {
	modelYearReturn[k] = prod(sample(modelQuarterReturn, 4, replace = TRUE))
	naiveYearReturn[k] = prod(sample(naiveQuarterReturn, 4, replace = TRUE))
}

# compute the likelihood of beating the market over a quarter and a year
#	 by random sampling and comparison
beatMarketYear = 0
beatMarketQuarter = 0
for (k in 1:2000) {
	# for the quarter
	modelSample = sample(modelQuarterReturn, 1)
	naiveSample = sample(naiveQuarterReturn, 1)
	beatMarketQuarter[k] = 0
	if (modelSample > naiveSample) {
		beatMarketQuarter[k] = 1
	}

	# for the year
	modelSample = sample(modelYearReturn, 1)
	naiveSample = sample(naiveYearReturn, 1)
	beatMarketYear[k] = 0
	if (modelSample > naiveSample) {
		beatMarketYear[k] = 1
	}
}

# generate boxplots with summary results
quarterBeatMarket = sum(beatMarketQuarter)/2000
myQuarterSub = c(as.character(quarterBeatMarket*100), '% chance of beating the market over 1 quarter')
myQuarterSub = paste(myQuarterSub, collapse = ' ')

yearBeatMarket = sum(beatMarketYear)/2000
myYearSub = c(as.character(yearBeatMarket*100), '% chance of beating the market over 1 year.')
myYearSub = paste(myYearSub, collapse = ' ')

quantile(modelYearReturn)
quantile(naiveYearReturn)

dev.new()
boxplot(modelQuarterReturn,naiveQuarterReturn, main = "Quarterly Returns", sub = myQuarterSub, ylab = "Proportional Return")
abline(h = 1.0)
axis(1, at = c(1, 2), labels = c('Model', 'Naive'))

dev.new()
boxplot(modelYearReturn,naiveYearReturn, main = "Yearly Returns", sub = myYearSub, ylab = "Proportional Return")
abline(h = 1.0)
axis(1, at = c(1, 2), labels = c('Model', 'Naive'))


