# Calculate Wins
An indicator will tell which direction to trade; next we need to find when to exit.

This script calculates whether a given symbol, indicator_name, indicator_setting (indicating an indicator_direction) will win_1_atr, win_2_atr and when the trade will finish by a finish_date.  Run it in your Redshift cluster.

It uses the Average True Range ([ATR](https://www.investopedia.com/terms/a/atr.asp)) indicator to determine where to place stop losses and take profit points for your trades.  The period used is 14.

It should be run after data is imported from *indicator_staging* to *indicator_result*.  It is included as part of the Lambda function to be used after an incremental import.  It can easily be moved and scheduled any time after new rows are in *indicator_result*.

*If you have many rows to process or lots of new files generated (like first time import), it would be best to run this separate from the Lambda function to avoid any timeout.

## Exit Strategy
1. Assuming a trade is taken by an indicator and setting for a symbol right before a candle closes (assuming you enter at the close price the day a signal is given), this logic will assume 2 trades will be placed (the amount of the trade will be discussed in the next step) a [stop loss](https://www.investopedia.com/terms/s/stop-lossorder.asp) is placed at 1.5 * ATR for both initially.  The [take profit](https://www.investopedia.com/terms/t/take-profitorder.asp) of the first trade will be 1 * ATR and the take profit of the second trade will be 2 * ATR.
   1. If the first take profit is hit, win_1_atr = 1, you adjust the stop loss of the second trade to the price you entered at, which is your [breakeven point](https://www.investopedia.com/terms/b/breakevenpoint.asp).
      1. If the second take profit is hit, win_2_atr = 1 and finish_date is set
      1. If stop loss is hit (breakeven point) win_2_atr = 0 and finish date is set
   1. If the stop loss is hit, then both trades lose, win_1_atr = win_2_atr = 0, and finish_date is set

These points have been chosen to allow some room to drop (1.5 * ATR) as well as gauge how much of a run a trade may hit.  If a trade hits a take profit at 2 * ATR, it means the trade ran **TWICE** the average true range for the symbol the 14 days before you entered.  Further, it was a strong run because it hit a take profit at 1 * ATR, didn't fluctuate back to the breakeven point, and ran to a 2 * ATR take profit.  This exit strategy is helpful in evaluating what indicators are good at finding trends.

## Additions
Besides adjusting the values of this strategy (i.e. change stop loss to 1 * ATR, change second take profit to 3 * ATR, etc.), you could calculate an entry based on 2 indicators.  Use one as a signal and the other to decide if the directions agree before entering a trade.  You could also use an indicator as an exit instead of waiting for the trade to hit your stop loss or take profit points.  While the above exit strategy is good for evaluating, it could be improved to maximize profits.  A hard take profit point that takes all your risk out of a trade puts an absolute max on your profits, when a trade could have ran for 4 * ATR and you could've exited later!  Even something as simple as a [trailing stop](https://www.investopedia.com/terms/t/trailingstop.asp) for the second trade could maximize profits more.
