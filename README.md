# forex-technical-indicators
Create a data flow analyzing technical entry indicators using MQL and your favorite broker on MetaTrader.  Each folder is a consecutive step in the data flow pipeline.  Check out the overview website [here](https://s3-us-west-1.amazonaws.com/forex.timsgrignoli.com/index.html).
This project specifically targets the Forex market but it can be easily reused for any market and most indicators compatible with MQL.  This project uses Moving Averages as an entry using a price crossover method.  Learn more [here](https://www.investopedia.com/articles/active-trading/052014/how-use-moving-average-buy-stocks.asp), but essentially when price closes above MA, go long and when it closes below, go short.  There are also an example of a "Zero-Cross" and "Two Lines Cross" indicators included.  For more information on these types of indicators look [here](https://nononsenseforex.com/indicators/forex-trend-indicators/) (I am not affiliated with this site but have used it for technical strategies).

## About the folders
1. Generate CSV - MQL to extract information to CSV file(s)
1. Upload CSV to S3 - Python to upload the CSV file(s) to S3 bucket
1. Trigger Lambda from S3 - Python to import CSV file(s) from S3 bucket to Redshift (or other SQL database)
1. Calculate Wins - SQL to calculate a win based on a specific exit strategy
1. Evaluate Indicators - SQL to find indicators based on different performance strategies

There are additional README.md files in the corresponding folders for more specific information.  Also, see some reporting using this data pipeline [here](https://s3-us-west-1.amazonaws.com/forex.timsgrignoli.com/index.html#reports).

## Additional Ideas
There are lots of forks that can be made in this project or even just changes to parameters that can give great data.  I keep some ideas here:
1. In the Generate CSV step, you could change the market or broker (cryptocurrency, stocks, precious metals, anything that MQL/MetaTrader support), set of indicators (there are lots to sift through [MQL4](https://www.mql5.com/en/code/mt4/indicators) or [MQL5](https://www.mql5.com/en/code/mt5/indicators)), range of settings (some indicators take in several parameters), set of symbols (I started with the 28 most traded first), frequency of data (I chose the daily chart, drop to the 1 minute to generate LOTS of data) and overall date range of the data.
1. In the Calculate Wins step, the amount of risk, stop loss positions, and take profit points can all be adjusted.  Also, indicators can be combined.  This can create elaborate strategies where some indicators can act as entries or confirmations for other indicators and when indicators agree, then trade. *This is how valuable strategies are formed!* This project implements a simple (yet effective) exit strategy because the main purpose was to evaluate overall entry indicators.  With some slight modifications, it can be used to test exit strategies in combination with entries to find *very* effective solutions.
1. In the Evaluate Indicators step, there are many different "picking" strategies that could be used to find which combination was most effective for your "win" strategy in the step before.  I included some expressions to filter and rank the best strategies but lots of other combinations exist with the current data given let alone if you added other calculated columns (longest win streak, weighted average based on number of signals, etc.).
