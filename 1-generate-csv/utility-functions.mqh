//+------------------------------------------------------------------+
//|                                            utility-functions.mqh |
//|                                                    Tim Sgrignoli |
//|      https://github.com/timsgrignoli/forex-technical-indicators/ |
//+------------------------------------------------------------------+
#property copyright "Tim Sgrignoli"
#property link      "https://github.com/timsgrignoli/forex-technical-indicators/"
#property strict

//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+

// if sample = true
// small sample of 5 covering all 8 major currencies
string _CurrencySample[] = {"EURUSD","AUDNZD","EURGBP","CHFJPY","AUDCAD"};
string _IndicatorSample[] = {"Sma", "Ema"};

// if sample = false
// all 28 major pairs
string _CurrencyAll[] = {"AUDCAD", "AUDCHF", "AUDJPY", "AUDNZD", "AUDUSD", "CADCHF", "CADJPY", "CHFJPY", "EURAUD", "EURCAD", "EURCHF", "EURGBP", "EURJPY", "EURNZD", "EURUSD", "GBPAUD", "GBPCAD", "GBPCHF", "GBPJPY", "GBPNZD", "GBPUSD", "NZDCAD", "NZDCHF", "NZDJPY", "NZDUSD", "USDCAD", "USDCHF", "USDJPY"};
string _IndicatorAll[] = {"Sma", "Ema", "Smma", "Lwma", "Aroon", "Cmf"};

// use daily time frame but easily configurable to others
int _TimeFrame = PERIOD_D1;

//+------------------------------------------------------------------+
//| Commonly Used Functions                                          |
//+------------------------------------------------------------------+

// create detail file
int CreateDetailFile(int file)
{
   int result = FileOpen("IndicatorDump_" + GetFileDateString(TimeLocal()) + "_" + IntegerToString(file) + ".csv", FILE_BIN|FILE_WRITE);
      
   // error
   if(result < 1)
   {
      return result;
   }
   
   Alert("FileOpen - " + IntegerToString(file));
         
   // create header row
   WriteDetailHeader(result);
   
   return result;
}

// write string to a file
void WriteData(string data, int file)
{
   FileWriteString(file, data, StringLen(data));

   return;
}

// write header for detail file
void WriteDetailHeader(int detailFile)
{
   WriteData("Symbol,", detailFile);
   WriteData("Date,", detailFile);
   WriteData("Open,", detailFile);
   WriteData("High,", detailFile);
   WriteData("Low,", detailFile);
   WriteData("Close,", detailFile);
   WriteData("Direction,", detailFile);
   WriteData("Atr,", detailFile);
   
   WriteData("IndicatorName,", detailFile);
   WriteData("IndicatorSetting,", detailFile);
   WriteData("IndicatorDirection,", detailFile);
   WriteData("IndicatorSignal,", detailFile);
   WriteData("\n", detailFile);
   
   return;
}

// write non-indicator related data to detail file
void WriteBasicDetailData(string symbol, int bar, int timeFrame, double close, int detailFile)
{
   // basic specific to pair
   datetime time = iTime(symbol, timeFrame, bar);
   int digits = (int) MarketInfo(symbol, MODE_DIGITS);
   
   // basic ohl (already have close)
   double open = iOpen(symbol, timeFrame, bar);
   double high = iHigh(symbol, timeFrame, bar);
   double low = iLow(symbol, timeFrame, bar);
   
   // candle direction
   int candleDirection = GetCandleDirection(open, close);
   
   // ATR
   double atr = iATR(symbol, timeFrame, 14, bar);
   
   // write all data
   WriteData(symbol + ",", detailFile);
   WriteData(GetDatetimeString(time) + ",", detailFile);
   
   WriteData(DoubleToStr(open, digits) + ",", detailFile);
   WriteData(DoubleToStr(high, digits) + ",", detailFile);
   WriteData(DoubleToStr(low, digits) + ",", detailFile);
   WriteData(DoubleToStr(close, digits) + ",", detailFile);
   
   WriteData(IntegerToString(candleDirection) + ",", detailFile);
   
   WriteData(DoubleToStr(atr, digits) + ",", detailFile);
   
   return;
}

// write indicator data to detail file
void WriteIndicatorData(int bar, int setting, string symbol, int timeFrame, double close, string indicator, int detailFile)
{
   int direction = GetIndicatorDirection(bar, setting, symbol, timeFrame, close, indicator);
   int signal = GetIndicatorSignal(bar, setting, symbol, timeFrame, close, indicator);
   
   WriteData(indicator + ",", detailFile);
   WriteData(IntegerToString(setting) + ",", detailFile);
   WriteData(IntegerToString(direction) + ",", detailFile);
   WriteData(IntegerToString(signal) + ",", detailFile);
   
   WriteData("\n", detailFile);
}

// get formatted datetime
string GetDatetimeString(datetime date)
{
   return StringFormat("%i-%02i-%02i %02i:%02i:%02i", TimeYear(date), TimeMonth(date), TimeDay(date), TimeHour(date), TimeMinute(date), TimeSeconds(date));
}

// get formatted date
string GetDateString(datetime date)
{
   return StringFormat("%02i-%02i-%i", TimeMonth(date), TimeDay(date), TimeYear(date));
}

// get file formatted date
string GetFileDateString(datetime date)
{
   return StringFormat("%i-%02i-%02i", TimeYear(date), TimeMonth(date), TimeDay(date));
}

// get direction of candle based on open and close
int GetCandleDirection(double open, double close)
{
   if(close > open)
   {
      return 1;
   }
   else if(close < open)
   {
      return -1;
   }
   else
   {
      return 0;
   }
}

// get indicator direction
// when adding indicators, determine what the val1 and val2 need to be to give longs vs shorts
int GetIndicatorDirection(int bar, int setting, string symbol, int timeFrame, double close, string indicator)
{
   double value1 = 0.0;
   double value2 = 0.0;
   
   // Using Moving Averages as Indicators when they cross close price (like two lines cross)
   //	ENUM_MA_METHOD
   //	MODE_SMA    0  Simple averaging
   //	MODE_EMA    1  Exponential averaging
   //	MODE_SMMA   2  Smoothed averaging
   //	MODE_LWMA   3  Linear-weighted averaging
   //	
   //	ENUM_APPLIED_PRICE
   //	PRICE_CLOSE 	0	Close price
   //	PRICE_OPEN	   1	Open price
   //	PRICE_HIGH	   2	The maximum price for the period
   //	PRICE_LOW	   3	The minimum price for the period
   //	PRICE_MEDIAN	4	Median price, (high + low)/2
   //	PRICE_TYPICAL	5	Typical price, (high + low + close)/3
   //	PRICE_WEIGHTED	6	Weighted close price, (high + low + close + close)/4
   
   if(indicator == "Sma")
   {
      // compare ma to close price
      value1 = close;
      value2 = iMA(symbol, timeFrame, setting, 0, MODE_SMA, PRICE_CLOSE, bar);
   }
   else if(indicator == "Ema")
   {
      // compare ma to close price
      value1 = close;
      value2 = iMA(symbol, timeFrame, setting, 0, MODE_EMA, PRICE_CLOSE, bar);
   }
   else if(indicator == "Smma")
   {
      // compare ma to close price
      value1 = close;
      value2 = iMA(symbol, timeFrame, setting, 0, MODE_SMMA, PRICE_CLOSE, bar);
   }
   else if(indicator == "Lwma")
   {
      // compare ma to close price
      value1 = close;
      value2 = iMA(symbol, timeFrame, setting, 0, MODE_LWMA, PRICE_CLOSE, bar);
   }
   
   // example of two lines cross indicator
   // see README for link to download; put in "Indicators" folder
   else if(indicator == "Aroon")
   {
      // up
      value1 = iCustom(symbol, timeFrame, "aroon_up_down", setting, false, false, 0, bar);
      
      // down
      value2 = iCustom(symbol, timeFrame, "aroon_up_down", setting, false, false, 1, bar);
   }
   
   // example of zero cross indicator
   // see README for link to download; put in "Indicators" folder
   else if(indicator == "Cmf")
   {
      value1 = iCustom(symbol, timeFrame, "CMF_v1", setting, 0, bar);
   }
   
   if(value1 > value2)
   {
      return 1;
   }
   else if(value1 < value2)
   {
      return -1;
   }
   else
   {
      return 0;
   }
}

// getting the signal is as simple as seeing when the direction changed
int GetIndicatorSignal(int bar, int setting, string symbol, int timeFrame, double close, string indicator)
{
   int direction1 = GetIndicatorDirection(bar, setting, symbol, timeFrame, close, indicator);
   
   for(int i=1;i<1000000;i++)
   {
      int direction2 = GetIndicatorDirection(bar + i, setting, symbol, timeFrame, iClose(symbol, timeFrame, bar + i), indicator);
      if(direction1 > 0)
      {
         if(direction2 < 0)
         {
            return 1;
         }
         else if(direction2 > 0)
         {
            return 0;
         }
      }
      else if(direction1 < 0)
      {
         if(direction2 > 0)
         {
            return 1;
         }
         else if(direction2 < 0)
         {
            return 0;
         }
      }
      else
      {
         return 0;
      }
   }
   Alert("ERROR - GetIndicatorSignal - No value in a million bars!");
   return -1;
}