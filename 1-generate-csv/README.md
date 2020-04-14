# Generate CSV
This MQL4 script can be used to generate a CSV across different symbols, indicators, and indicator settings over a period of time of for a particular timeframe.

## How to Use
1. Make sure MetaTrader 4 is installed and connected to your broker.  This may be different depending on your country.  In the US, I use [Oanda](https://www.oanda.com/us-en/trading/platforms/metatrader-4/) (which is also why this is written in MQL4 because they did not support MT5).
1. Download **utility-functions.mqh** and move to your **Include** folder
1. Download **generate-csv.mq4** and move to your **Scripts** folder
![Install](/images/mql-install.png)
1. Run **generate-csv** script from MT4
![Input](/images/mql-input.png)

### Input Parameters
* Sample - True will run a *sample* of indicators and *sample* of symbols to check it works.  False will run the *full* set of indicators and *full* set of currencies (all 28 major pairs).
  * In order to run the *full* set, download the [Aroon_Up_Down](https://www.earnforex.com/metatrader-indicators/Aroon-Up-Down/) indicator and the [CMF_v1](https://forex-indicators.net/volume/chaikin-money-flow) indicators and put them in **Indicators** folder (see picture above for file path).
  * The sample set and full set can be found at the top of the **utility-functions.mqh** file.
* StartDate - (optional) use this to select a begin date.  This will override *NumberBarsBack* below.
* NumberBarsBack - use instead of *StartDate* to select a number of bars.  Default = 60 for sample.
* Split - use as number of records before splitting to a new file.  Default = 1040000 which fits in Excel.
* SettingMin - lowest setting to test for all indicators.  Default = 7 for sample.
* SettingMax - highest setting to test for all indicators.  Default = 10 for sample.

Generated files will output in the **Files** folder (see picture above for file path) with the following format:

**IndicatorDump_yyyy-mm-dd_n.csv**

where n = file number (if multiple files were split).  See [here](/1-generate-csv/sample-file) for a sample file ran on April 13, 2020 with Sample = True.
