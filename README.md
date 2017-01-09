# Predicting an exchange-traded fund
The objective of this project is to predict the movement of the exchange-traded fund SPY, which is based on the S&P 500. We will use our predictor to predict if SPY will go up or down over the last 126 days (~2 quarters in trading days) and then compare it to what actually happened. We will do this by predicting what will happen each day for every stock which composes the S&P 500 and then take an average of the all stocks in a given day. Then we will make some projections as to what we may expect if we use this model to play the market. 

## The Data
The data is provided as zip folder with .csv files containing historical data from all of the tickers (505 total) in the S&P 500 from Jan 6, 2010 until Jan 6, 2014. This data was downloaded using a variant of some python code that you will find in a different repo called [SP-500-Data-Puller](https://github.com/MiningMyBusiness/SP500-Data-Puller). The code in SP-500-Data-Puller can be easily changed to also get the historical data for SPY. We are going to predict the last 126 days of this ETF. The historical data for SPY is also included in the data for a grand total of 506 files. 

#### Note: 
Be forewarned that this data is based on the composition of the S&P 500 on Dec 28, 2016. Some of these tickers may not have been in the S&P 500 in 2010. In our following analysis, we will exclude companies who do not have ticker data going far enough back in time. 

## The Code

### Section 1: Read data
The first section of the code reads in the historical data of one ticker. It excludes tickers which do not have a sufficient amount of historical data (in this case, before 2014). It aggregates the daily closing price data of the ticker over the last few years into one vector.

### Section 2: Holt-Winters time series analysis
This part fits a Holt-Winters exponential smoothing model to the time series data of the daily closing price of the ticker for about two years of data and uses it to predict the percent movement of the stock on the next day. It does this for 126 days (2 quarters in trading days) previous to Jan 5, 2016. 

*Sections 1 and 2 are repeated for every stock in the S&P 500 of which there are 506. The data is stored in a 505 by 126 matrix (n_stocks by n_days). For each stock, there are 126 days of predictions.*

### Section 3: The prediction and comparison
Next we take the average percent movement of all the stocks for a given day for every day of prediction. This will be our Holt-Winter's estimate. Next we, compare this to what actually happened to SPY for last 126 days by reading in the historical data and determining whether the stock went up or down. 

By using a sliding decision threshold in our Holt-Winter's estimate to predict if SPY went up or down, we construct a sensitivity vs. specificity curve. ([Wikipedia article for sensitivity and specificity](https://en.wikipedia.org/wiki/Sensitivity_and_specificity)). 

![alt text](https://github.com/MiningMyBusiness/Predicting-an-exchange-traded-fund/raw/master/SensVsSpec2.png "Sensitivity vs. Specificity")

The intersection of the true positive and true negative curves is the ideal decision threshold to maximize accuracy. Using this decision threshold we get the following confusion matrix:

|              | Actual down | Actual up |
| -------------|:------------| ---------:|
| Predict down |      36     |     25    |
| Predict up   |      23     |     42    |

This is a 61.9% over all accuracy rate. This is a statistically significant result with a p-value of 0.008 suggesting that this model is able to predict the movement of SPY. However, the model is slightly better at predicting when the stock will go up (64.6% accruate), than when it will go down (59%). 

### Section 4: Comparing the model and the naive the investment strategies
Here we test what would have happened over the last 126 days if we actually had used this model to bet on SPY. We compare this result to what would have happened if we just left our money in SPY for the same about of time without buying and selling when our model told us to. 

We do this by collecting the proportional movement of SPY every day (1 is no movement, > 1 is up, and < 1 is down) over the last 126 days and store it in a vector. We compare this to the porportional movement of SPY only on the days our model would have predicted 'Up'. The product of each of these vectors is the total proportional gain we would have had over the last two quarters if we followed that investment strategy. Here is the result:

Model: 1.110

Naive: 1.076

So following this strategy, we would have performed 3.4% above market over the last two quarters. This isn't bad but may not be as high as we expect because the stock actually went up when we predicted it would go down so we lost out on those gains by selling at those times. 

### Section 5: Projecting into the future
Now we try to get an estimate for what we can expect if we were to follow this investment strategy for the next quarter and the next year. We can do this with a [Bootstrapping method](https://en.wikipedia.org/wiki/Bootstrapping_(statistics)). We resample our distributions of daily proportional changes for our model and naive investment strategies to generate different scenarios going forward in time. We account for the fact that with our model we are only betting about half of the time since we only bet when we say it goes up. We simulte 1000 potential future outcomes over 1 month, which we then bootstrap to simulate 2000 potential outcomes over 1 quarter and 1 full year. Here are the distributions of the quarterly and yearly returns made with each strategy:

![alt text](https://github.com/MiningMyBusiness/Predicting-an-exchange-traded-fund/raw/master/QuarterlyReturns.png "Quarterly Returns")

![alt text](https://github.com/MiningMyBusiness/Predicting-an-exchange-traded-fund/raw/master/YearlyReturns.png "Yearly Returns")

The median returns from the model are higher and the interquartile range is lower suggesting the model increases returns and reduces volatility. With this model, one has a 64.5% chance of beating the market over 1 quarter and a 72.5% of beating the market over 1 year. Moreover, it is highly unlikely that some one would lose money using this model over the next year (only 3 out of 2000 simulations over a year produced a return of less than 1). I'll be testing it out over the next quarter and year to see if this is indeed the case. 

#### Warnings:
* The numerical results of bootstrapping may be slightly different when you run your code since this is a random sampling method. However, the general conclusions will still be the same. 
* The results may be even more different if you choose to test a different set of 126 days than I did. However, in my experience this model is about 60-65% accurate regardless of which stretch of 126 days are tested. 
* The future projections are based off of the S&P 500 performance over the last 2 quarters. If this performance changes signficantly, it will influence the future projections. 
* Buying and selling this etf on a daily basis will incur fees which can offset the gains made from the model predictions. However, this can be addressed by using a free trading platfrom to buy stocks, like [Robinhood](https://www.robinhood.com/).

## The Future
Anyone could easily implement this for any exchange-traded fund as long as they knew the holdings of that fund and the weight of the those holdings. For instance, I've tried this algorithm with XLE, enery-sector exchange traded fund from SPDR, and XLV, the healthcare sector etf from SPDR, with some success. One could potentially scrape this [Wikipedia list of American ETFs](https://en.wikipedia.org/wiki/List_of_American_exchange-traded_funds) and query the website of the financial firm which runs the ETF to get the holdings and run this code to see how it performs. Of course, the ability to predict these stocks suggests that there are [market inefficiencies](https://en.wikipedia.org/wiki/Efficient-market_hypothesis). 
