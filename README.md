# Predicting an exchange-traded fund
The objective of this project is to predict the movement of the exchange-traded fund SPY, which is based on the S&P 500. We will use our predictor to predict if SPY will go up or down over the last 126 days (~2 quarters in trading days) and then compare it to what actually happened. We will do this by predicting what will happen each day for every stock which composes the S&P 500 and then take an average of the all stocks in a given day. Then we will make some projections as to what we may expect if we use this model to play the market. 

## The Data
The data is provided as zip folder with .csv files containing historical data from all of the tickers (506 total) in the S&P 500 from Jan 1, 2010 until Dec 29, 2016. This data was downloaded using a variant of some python code that you will find in a different repo called [SP-500-Data-Puller](https://github.com/MiningMyBusiness/SP500-Data-Puller). The code in SP-500-Data-Puller can be easily changed to also get the historical data for SPY. We are going to predict the last 126 days of this ETF. The historical data for SPY is also included in the data for a grand total of 507 files. 

#### Note: 
Be forewarned that this data is based on the composition of the S&P 500 on Dec 28, 2016. Some of these tickers may not have been in the S&P 500 in 2010. In our following analysis, we will exclude companies who do not have ticker data going far enough back in time. 

## The Code

### Section 1: Read data
The first section of the code reads in the historical data of one ticker. It excludes tickers which do not have a sufficient amount of historical data (in this case, before 2014). It aggregates the daily closing price data of the ticker over the last few years into one vector.

### Section 2: Holt-Winters time series analysis
This part fits a Holt-Winters exponential smoothing model to the time series data of the daily closing price of the ticker for about two years of data and uses it to predict the percent movement of the stock on the next day. It does this for 126 days (2 quarters in trading days) previous to Dec 28, 2016. 

*Sections 1 and 2 are repeated for every stock in the S&P 500 of which there are 506. The data is stored in a 506 by 126 matrix (n_stocks by n_days). For each stock, there are 126 days of predictions.*

### Section 3: The prediction and comparison
Next we take the average percent movement of all the stocks for a given day. If this is above zero we predict that SPY will go up and if this is below zero we predict that SPY will go down. We can compare this to what actually happened to SPY for last 126 days by reading in the historical data and determining whether the stock went up or down. With this data we get the following confusion matrix:

|              | Actual down | Actual up |
| -------------|:------------| ---------:|
| Predict down |      37     |     29    |
| Predict up   |      21     |     39    |

This is a 60.3% over all accuracy rate. This is a statistically significant result with a p-value of 0.02 suggesting that this model is able to predict the movement of SPY. However, the model is slightly better at predicting when the stock will go up (65% accruate) than when it will go down (56%). 

### Section 4: Comparing the model and the naive the investment strategies
Here we test what would have happened over the last 126 days if we actually had used this model to bet on SPY. We compare this result to what would have happened if we just left our money in SPY for the same about of time without buying and selling when our model told us to. 

We do this by collecting the proportional movement of SPY every day (1 is no movement, > 1 is up, and < 1 is down) over the last 126 days and store it in a vector. We compare this to the porportional movement of SPY only on the days our model would have predicted 'Up'. The product of each of these vectors is the total proportional gain we would have had over the last two quarters if we followed that investment strategy. Here is the result:

Model: 1.108

Naive: 1.071

So following this strategy, we would have performed 3.7% above market over the last two quarters. This isn't bad but may not be as high as we expect because the stock actually went up when we predicted it would go down so we lost out on those gains by selling at those times. 

### Section 5: Projecting into the future
Now we try to get an estimate for what we can expect if we were to follow this investment strategy for the next quarter and the next year. We can do this with a [Monte Carlo simulation](https://en.wikipedia.org/wiki/Monte_Carlo_method). We use the mean and standard deviation of the daily proportional changes of SPY and also the mean and standard devation of proportional changes if we betted according to our model and sample each distribution randomly. We account for the fact that with our model we are only betting about half of the time since we only bet when we say it goes up. We simulte 200 potential future outcomes over 1 quarter and then follow the Monte Carlo method again to simulate what might happen over a full year. Here are the results with mean +/- standard deviation of potential outcomes shown over the next quarter and year:

|       |     1 Quarter   |     1 Year      |
|-------|:----------------| ---------------:|
| Model | 1.054 +/- 0.037 | 1.230 +/- 0.083 |
| Naive | 1.032 +/- 0.047 | 1.134 +/- 0.104 |

So with this model one should be able to consistently beat the market (the model mean in bigger) and reduce volatility (the model standard deviation is smaller) over time. I'll be testing it out over the next quarter and year to see if this is indeed the case. 

#### Warnings:
* The numerical results of the Monte Carlo may be slightly different when you run your code since this is a random sampling method. However, the general conclusions will still be the same. 
* The results may be even more different if you choose to test a different set of 126 days than I did. However, in my experience this model is about 60-65% accurate regardless of which stretch of 126 days are tested. 

## The Future
Anyone could easily implement this for any exchange-traded fund as long as they knew the holdings of that fund and the weight of the those holdings. For instance, I've tried this algorithm with XLE, enery-sector exchange traded fund from SPDR, and XLV, the healthcare sector etf from SPDR, with some success. One could potentially scrape this [Wikipedia list of American ETFs](https://en.wikipedia.org/wiki/List_of_American_exchange-traded_funds) and query the website of the financial firm which runs the ETF to get the holdings and run this code to see how it performs. Of course, the ability to predict these stocks suggests that there are [market inefficiencies](https://en.wikipedia.org/wiki/Efficient-market_hypothesis). 
