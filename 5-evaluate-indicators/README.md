# Evaluate Indicators
This SQL shows how the indicators were evaluated using the assumed exit strategy from the previous step.  Run it in your Redshift cluster.

## In the SQL Script
* **f_calculate_roi** - function to calculate ROI based on # of win_1_atr, # of win_2_atr and # of total signals assuming the stop loss and take profit points based on the previous step and a total risk of 2% (1% for each trade) of your total trading principal.  For example, if you had a $10,000 account and an indicator gave a signal, you would enter two $100 trades.  Also, if the ROI returned from this function was 1.09 it means your total account would be $10,000 * 1.09 =  $10,900 if you took ALL trades and traded specific to the [exit strategy](https://github.com/timsgrignoli/forex-technical-indicators/tree/master/4-calculate-wins#exit-strategy).
* **roi_symbol_indicator_setting(start, end)** - stored procedure used for some reports evaluating ROI over symbol, indicator_name, and indicator_setting for a specific time range from *start* to *end*.
* **roi_strategy_simulation(start_eval, end_eval, start_sim, end_sim)** - stored procedure used for some reports simulating if you chose indicators using a specific strategy.  It evaluates the indicators from *start_eval* to *end_eval*, chooses the "best" based on a strategy (see below), then simulates what would've happened if you traded that strategy from *start_sim* to *end_sim*.

### Strategies
All these strategies are ran with a particular *start_eval, end_eval, start_sim* and *end_sim* date based on re-usable logic that can be used to decide what indicators to choose for your trading.  These are only a couple examples on how to start evaluating but the filters, combinations, and time ranges are unlimited!

Please note, as with all market [backtesting](https://www.investopedia.com/terms/b/backtesting.asp), past performance does not implicate future results.

* **Simple ROI Low Setting** - this picks the indicator for each symbol based on the best ROI from the *start_eval* to *end_eval* period, splitting ties of ROI by the lowest setting of the indicator.  The thought is the best performing indicators over a month or year evaluation period might perform well over a *start_sim* to *end_sim* simulation period and lower settings may give a faster signal on indicators over a high setting that may miss trends.
* **Simple ROI High Setting** - same as above except higher settings may give a signal on indicators that has less noise and less false signals than a low setting.
* **No Lose Streak Average Win1 > 80% High Setting** - this shows how to use some filter logic to create a strategy.  It assumes the longest lose streak = 0 and the average win percentage of win_1_atr is greater than 80% sorting ties by setting high (see above).
* **Winningest Signals Low Setting** - this uses complicated logic to first find the winningest indicator (regardless of setting) for a symbol, then sort by the best ROI from the evaluation period, splitting ties by lowest setting
* **Winningest Signals High Setting** - same as above but by highest setting
