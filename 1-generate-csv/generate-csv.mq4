//+------------------------------------------------------------------+
//|                                                 generate-csv.mq4 |
//|                                                    Tim Sgrignoli |
//|      https://github.com/timsgrignoli/forex-technical-indicators/ |
//+------------------------------------------------------------------+
#property copyright "Tim Sgrignoli"
#property link      "https://github.com/timsgrignoli/forex-technical-indicators/"
#property version   "1.00"
#property strict
#property script_show_inputs

#include <utility-functions.mqh>

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+

// Sample will test a couple currencies and indicators to make sure it works
// check the utility-functions.mqh "defines" section for declarations
// in order to run with Sample = false you'll need to download the Aroon and Cmf indicators; see README
input bool Sample = true;

// StartDate is how far back to get data
// good for bulk loading from a specific date
// not required, if left unchanged it will use NumberBarsBack (below) instead
// will go from StartDate to 1 bar
// *the zeroth bar will still be forming and indicator data may be changing
input datetime StartDate = NULL;

// NumberBarsBack is the number of bars back to get data from
// default to 1 for an incremental load
// *if StartDate is set above it will override this
input int NumberBarsBack = 60;

// Split files on number of records i.e. 1040000 fits in excel
input int Split = 1040000;

// SettingMin and SettingMax determine the range of test settings
// minimum and maximum setting to test for ALL indicators
input int SettingMin = 7;
input int SettingMax = 10;

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   // Currencies and Indicators to test
   string Currencies[];
   string Indicators[];
   
   // set based on Sample input
   if(Sample)
   {
      ArrayResize(Currencies, ArraySize(_CurrencySample));
      ArrayCopy(Currencies, _CurrencySample);
      
      ArrayResize(Indicators, ArraySize(_IndicatorSample));
      ArrayCopy(Indicators, _IndicatorSample);
   }
   else
   {
      ArrayResize(Currencies, ArraySize(_CurrencyAll));
      ArrayCopy(Currencies, _CurrencyAll);
      
      ArrayResize(Indicators, ArraySize(_IndicatorAll));
      ArrayCopy(Indicators, _IndicatorAll);
   }
   
   // calculate newBars which is the number of bars back to go based on StartDate or NumberBarsBack
   int newBars = NumberBarsBack;
   string using = "";
   if(StartDate != NULL)
   {
      newBars = Bars(Currencies[0], _TimeFrame, StartDate, TimeGMT()) - 1;
      using = " (using start date " + GetDateString(StartDate) + ")";
   }

   // started
   Alert(GetDatetimeString(TimeLocal()) + "  Generating for " + IntegerToString(ArraySize(Currencies)) + " Currencies over " + IntegerToString(newBars) + " Bars" + using + " over " + IntegerToString(ArraySize(Indicators)) + " indicators with min " + IntegerToString(SettingMin) + " and max " + IntegerToString(SettingMax) + " settings.");

   // create output files
   int file = 1;
   int rows = 0;
   int detailFile = CreateDetailFile(file);
   
   // print error
   if(detailFile < 1)
   {
      Alert("Err ", GetLastError());
      return;
   }
         
   // loop through currency pairs
   for(int pair = 0; pair < ArraySize(Currencies); pair++)
   {
      string currentPair = Currencies[pair];
      Alert(GetDatetimeString(TimeLocal()) + "  Pair " + currentPair);
      
      // loop through indicators
      for(int ind = 0; ind < ArraySize(Indicators); ind++)
      {
         Alert(GetDatetimeString(TimeLocal()) + "  Indicator " + Indicators[ind] + " for " + currentPair);
         
         // loop through settings
         for(int setting = SettingMin; setting < (SettingMax + 1); setting++)
         {
            // loop through days
            for(int bar = 1; bar <= newBars; bar++)
            {
               // close
               double close = iClose(currentPair, _TimeFrame, bar);
               
               // write non-indicator data
               WriteBasicDetailData(currentPair, bar, _TimeFrame, close, detailFile);
               
               // indicator data
               WriteIndicatorData(bar, setting, currentPair, _TimeFrame, close, Indicators[ind], detailFile);
               
               // increase row count to split files
               rows++;
               if(rows % Split == 0)
               {
                  //set back to 0 so we don't overflow an int
                  rows = 0;
                  
                  // close files
                  FileClose(detailFile);
                  Alert(GetDatetimeString(TimeLocal()) + " Closed file - " + IntegerToString(file));
                  
                  // create new file
                  file++;
                  detailFile = CreateDetailFile(file);
                  
                  // print error
                  if(detailFile < 1)
                  {
                     Alert("Err ", GetLastError());
                     return;
                  }
               }
            }
         }
      }
   }
   
   // close files
   FileClose(detailFile);
   Alert(GetDatetimeString(TimeLocal()) + " Done.");
   
   return;
}