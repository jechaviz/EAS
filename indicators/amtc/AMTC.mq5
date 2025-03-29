// #                         AMTC.mq5
// # Copyright 2025, jechaviz
// # jechaviz@gmail.com
#property copyright "2025, jechaviz"
#property link      "jechaviz@gmail.com"
#property version   "2.00"
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   1

// Plot 0: HMA (colored line)
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrLimeGreen, clrOrange, clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

// Includes
#include "AMTC_Utils.mqh"
#include "AMTC_Visualizer.mqh"
#include "AMTC_Optimizer.mqh"

// Input Parameters
input int    HMA_Period   = 13;            // Base HMA Period (min 5)
input double VolatilitySensitivity = 1.0;  // Volatility adjustment factor (0.5 to 2.0)
input bool   ShowSignals  = true;          // Show buy/sell/flat arrows
input bool   ShowSHAP     = false;         // Show SHAP explainability chart
input color  UpArrowColor = clrLime;       // Up arrow color
input color  DownArrowColor = clrRed;      // Down arrow color
input color  FlatArrowColor = clrGray;     // Flat arrow color
input int    ArrowSize    = 1;             // Arrow width (1-5)
input double ArrowOffsetPoints = 10;       // Arrow offset in points
input bool   UseCrossAsset = false;        // Enable cross-asset consensus
input string CorrelatedSymbol = "EURUSD";  // Correlated asset symbol
input int    ParticleCount = 100;          // Number of particles for filtering (50-500)

// Buffers
double HmaBuffer[];        // HMA values
double HmaColorBuffer[];   // HMA color index
double TrendSlope[];       // Filtered trend slope
double FuzzyUp[];          // Fuzzy score for up trend
double FuzzyDown[];        // Fuzzy score for down trend
double FuzzyFlat[];        // Fuzzy score for flat trend

// Global Variables
int minBarsRequired;
double particleStates[];

// # Custom indicator initialization function
int OnInit() {
   // Validate inputs
   if(HMA_Period < 5) {
      Print("Error: HMA_Period must be at least 5");
      return(INIT_PARAMETERS_INCORRECT);
   }
   if(VolatilitySensitivity < 0.5 || VolatilitySensitivity > 2.0) {
      Print("Error: VolatilitySensitivity must be between 0.5 and 2.0");
      return(INIT_PARAMETERS_INCORRECT);
   }
   if(ParticleCount < 50 || ParticleCount > 500) {
      Print("Error: ParticleCount must be between 50 and 500");
      return(INIT_PARAMETERS_INCORRECT);
   }

   // Set buffers
   SetIndexBuffer(0, HmaBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, HmaColorBuffer, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2, TrendSlope, INDICATOR_DATA);
   SetIndexBuffer(3, FuzzyUp, INDICATOR_DATA);
   SetIndexBuffer(4, FuzzyDown, INDICATOR_DATA);
   SetIndexBuffer(5, FuzzyFlat, INDICATOR_DATA);

   // Configure plot
   PlotIndexSetString(0, PLOT_LABEL, "AMTC_HMA");
   IndicatorSetString(INDICATOR_SHORTNAME, "AMTC v2 (" + IntegerToString(HMA_Period) + ")");
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);

   // Calculate minimum bars required
   minBarsRequired = HMA_Period + (int)MathSqrt(HMA_Period) + 20; // Extra buffer for skewness

   // Initialize particle filter
   ArrayResize(particleStates, ParticleCount);

   // Optimize parameters
   int optimizedPeriod = HMA_Period;
   OptimizeParameters(optimizedPeriod);
   Print("Optimized HMA Period: ", optimizedPeriod);

   return(INIT_SUCCEEDED);
}

// # Custom indicator iteration function
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const double &price[]) {
   if(rates_total < minBarsRequired) {
      Print("Insufficient bars: ", rates_total, " < ", minBarsRequired);
      return(0);
   }

   // Prepare arrays
   double highArray[], lowArray[], atrArray[];
   datetime timeArray[];
   ArraySetAsSeries(price, true);
   ArraySetAsSeries(HmaBuffer, true);
   ArraySetAsSeries(HmaColorBuffer, true);
   ArraySetAsSeries(TrendSlope, true);
   ArraySetAsSeries(FuzzyUp, true);
   ArraySetAsSeries(FuzzyDown, true);
   ArraySetAsSeries(FuzzyFlat, true);

   CopyHigh(_Symbol, _Period, 0, rates_total, highArray);
   CopyLow(_Symbol, _Period, 0, rates_total, lowArray);
   CopyTime(_Symbol, _Period, 0, rates_total, timeArray);
   int atrHandle = iATR(_Symbol, _Period, 14);
   if(atrHandle == INVALID_HANDLE) {
      Print("Error: Failed to initialize ATR");
      return(0);
   }
   CopyBuffer(atrHandle, 0, 0, rates_total, atrArray);

   int start = prev_calculated > 0 ? prev_calculated - 1 : minBarsRequired;

   for(int i = start; i < rates_total; i++) {
      // Volatility-adjusted HMA period
      double atr = atrArray[i];
      if(atr == 0) continue; // Skip invalid ATR
      double adjustedPeriod = CalculateAdjustedPeriod(HMA_Period, atr, VolatilitySensitivity);
      HmaBuffer[i] = CalculateHMA(price, i, (int)adjustedPeriod, rates_total);

      // Trend slope with particle filtering
      double rawSlope = CalculateNonLinearSlope(HmaBuffer, i, (int)adjustedPeriod, rates_total);
      TrendSlope[i] = ParticleFilterUpdate(rawSlope, particleStates, ParticleCount);

      // Cross-asset consensus
      double consensus = 0.0;
      if(UseCrossAsset) {
         consensus = CalculateCrossAssetConsensus(i, CorrelatedSymbol, rates_total);
      }

      // Skewness adjustment
      double skewAdjustment = CalculateSkewnessAdjustment(price, i, rates_total);

      // Fuzzy logic scores
      CalculateFuzzyScores(TrendSlope[i], consensus, skewAdjustment, FuzzyUp[i], FuzzyDown[i], FuzzyFlat[i]);

      // Assign HMA color
      if(FuzzyUp[i] > FuzzyDown[i] && FuzzyUp[i] > FuzzyFlat[i])
         HmaColorBuffer[i] = 0;  // Up (LimeGreen)
      else if(FuzzyDown[i] > FuzzyUp[i] && FuzzyDown[i] > FuzzyFlat[i])
         HmaColorBuffer[i] = 2;  // Down (Red)
      else
         HmaColorBuffer[i] = 1;  // Flat (Orange)

      // Plot signals
      if(ShowSignals && i > minBarsRequired) {
         PlotSignals(i, timeArray[i], highArray[i], lowArray[i], FuzzyUp[i], FuzzyDown[i], FuzzyFlat[i],
                     HmaBuffer[i], UpArrowColor, DownArrowColor, FlatArrowColor, ArrowSize, ArrowOffsetPoints);
      }

      // SHAP explainability
      if(ShowSHAP && i > minBarsRequired && i % 5 == 0) {
         double shapValues[3];
         CalculateSHAPValues(TrendSlope[i], consensus, skewAdjustment, shapValues);
         PlotSHAPChart(i, timeArray[i], shapValues, HmaBuffer[i]);
      }
   }

   return(rates_total);
}

// # Custom indicator deinitialization function
void OnDeinit(const int reason) {
   ObjectsDeleteAll(0, "AMTC_");
}