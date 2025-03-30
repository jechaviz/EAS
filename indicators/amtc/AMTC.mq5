//+------------------------------------------------------------------+
//|                         AMTC.mq5                                 |
//| Copyright 2025, jechaviz                                         |
//| jechaviz@gmail.com                                               |
//+------------------------------------------------------------------+
#property copyright "2025, jechaviz"
#property link      "jechaviz@gmail.com"
#property version   "4.02"
#property indicator_chart_window
#property indicator_buffers 10
#property indicator_plots   1

// Plot 0: Medium-term HMA with color coding
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrLimeGreen, clrOrange, clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

// Includes
#include "AMTC_Utils.mqh"
#include "AMTC_Visualizer.mqh"
#include "AMTC_Optimizer.mqh"
#include "AMTC_HMM.mqh"
#include "AMTC_UKF.mqh"

// Input Parameters
input int    Short_Period = 9;             // Short-term base period (min 5)
input int    Medium_Period = 21;           // Medium-term base period (min 5)
input int    Long_Period = 50;             // Long-term base period (min 5)
input double VolatilitySensitivity = 1.0;  // Volatility adjustment (0.5-2.0)
input double UKF_ProcessNoise = 0.001;     // UKF process noise covariance
input double UKF_MeasurementNoise = 0.01;  // UKF measurement noise covariance
input bool   ShowSignals  = true;          // Show buy/sell/flat arrows
input bool   ShowSHAP     = false;         // Show SHAP dashboard
input color  UpArrowColor = clrLime;       // Up arrow color
input color  DownArrowColor = clrRed;      // Down arrow color
input color  FlatArrowColor = clrGray;     // Flat arrow color
input int    ArrowSize    = 1;             // Arrow width (1-5)
input double ArrowOffsetPoints = 10;       // Arrow offset in points
input string CorrelatedAssets = "EURUSD,GBPUSD,USDJPY"; // Correlated assets

// Buffers
double HmaShort[], HmaMedium[], HmaLong[], HmaColorBuffer[], TrendSlope[], FuzzyUp[], FuzzyDown[], FuzzyFlat[], SlopeVariance[], RegimeBuffer[];

// Global Variables
int minBarsRequired;
int atrHandle = INVALID_HANDLE;

// Initialization
int OnInit() {
   // Input validation
   if(Short_Period < 5 || Medium_Period < 5 || Long_Period < 5) {
      Print("Error: HMA periods must be >= 5");
      return(INIT_PARAMETERS_INCORRECT);
   }
   if(VolatilitySensitivity < 0.5 || VolatilitySensitivity > 2.0) {
      Print("Error: VolatilitySensitivity must be between 0.5 and 2.0");
      return(INIT_PARAMETERS_INCORRECT);
   }
   if(UKF_ProcessNoise <= 0 || UKF_MeasurementNoise <= 0) {
      Print("Error: UKF noise parameters must be positive");
      return(INIT_PARAMETERS_INCORRECT);
   }

   // Set buffers
   SetIndexBuffer(0, HmaMedium, INDICATOR_DATA);
   SetIndexBuffer(1, HmaColorBuffer, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2, HmaMedium, INDICATOR_DATA);
   SetIndexBuffer(3, FuzzyUp, INDICATOR_DATA);
   SetIndexBuffer(4, FuzzyDown, INDICATOR_DATA);
   SetIndexBuffer(5, FuzzyFlat, INDICATOR_DATA);
   SetIndexBuffer(6, HmaShort, INDICATOR_DATA);
   SetIndexBuffer(7, HmaLong, INDICATOR_DATA);
   SetIndexBuffer(8, SlopeVariance, INDICATOR_DATA);
   SetIndexBuffer(9, RegimeBuffer, INDICATOR_DATA);

   // Configure plot
   PlotIndexSetString(0, PLOT_LABEL, "AMTC_HMA_Medium");
   IndicatorSetString(INDICATOR_SHORTNAME, "AMTC v4 (" + IntegerToString(Short_Period) + "," + IntegerToString(Medium_Period) + "," + IntegerToString(Long_Period) + ")");
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);

   // Minimum bars required
   minBarsRequired = Long_Period + (int)MathSqrt(Long_Period) + 30;

   // Initialize components
   atrHandle = iATR(_Symbol, _Period, 14);
   if(atrHandle == INVALID_HANDLE) {
      Print("Error: Failed to initialize ATR");
      return(INIT_FAILED);
   }
   InitUKF(UKF_ProcessNoise, UKF_MeasurementNoise);
   InitHMM();

   // Optimize periods (no modification of inputs)
   int optShort = Short_Period, optMedium = Medium_Period, optLong = Long_Period;
   OptimizeParameters(optShort, optMedium, optLong);
   Print("Optimized periods: Short=", optShort, ", Medium=", optMedium, ", Long=", optLong);

   return(INIT_SUCCEEDED);
}

// Calculation
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
   if(rates_total < 1) return(0); // Minimum check relaxed

   // Prepare arrays
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(time, true);
   ArraySetAsSeries(HmaShort, true);
   ArraySetAsSeries(HmaMedium, true);
   ArraySetAsSeries(HmaLong, true);
   ArraySetAsSeries(HmaColorBuffer, true);
   ArraySetAsSeries(TrendSlope, true);
   ArraySetAsSeries(FuzzyUp, true);
   ArraySetAsSeries(FuzzyDown, true);
   ArraySetAsSeries(FuzzyFlat, true);
   ArraySetAsSeries(SlopeVariance, true);
   ArraySetAsSeries(RegimeBuffer, true);

   double atrArray[];
   if(CopyBuffer(atrHandle, 0, 0, rates_total, atrArray) < rates_total) {
      Print("Error: Failed to copy ATR data");
      return(0);
   }
   ArraySetAsSeries(atrArray, true);

   // Initialize TrendSlope with close prices to ensure continuity
   for(int i = 0; i < rates_total; i++) {
      TrendSlope[i] = close[i];
      HmaColorBuffer[i] = 1; // Default to orange (flat)
   }

   int start = prev_calculated > 0 ? prev_calculated - 1 : 0; // Start from 0 to fill all bars

   for(int i = start; i < rates_total && !IsStopped(); i++) {
      // Volatility-adjusted periods
      double atr = atrArray[i];
      if(atr == 0) continue;

      double adjShort = CalculateAdjustedPeriod(Short_Period, atr, VolatilitySensitivity);
      double adjMedium = CalculateAdjustedPeriod(Medium_Period, atr, VolatilitySensitivity);
      double adjLong = CalculateAdjustedPeriod(Long_Period, atr, VolatilitySensitivity);

      // Multi-scale HMA
      HmaShort[i] = CalculateHMA(close, i, (int)adjShort, rates_total);
      HmaMedium[i] = CalculateHMA(close, i, (int)adjMedium, rates_total);
      HmaLong[i] = CalculateHMA(close, i, (int)adjLong, rates_total);

      // Non-linear slopes
      double slopeShort = i >= (int)adjShort ? CalculateNonLinearSlope(HmaShort, i, (int)adjShort, rates_total) : 0.0;
      double slopeMedium = i >= (int)adjMedium ? CalculateNonLinearSlope(HmaMedium, i, (int)adjMedium, rates_total) : 0.0;
      double slopeLong = i >= (int)adjLong ? CalculateNonLinearSlope(HmaLong, i, (int)adjLong, rates_total) : 0.0;

      // UKF-filtered slope, scaled conservatively
      double rawSlope = i >= minBarsRequired ? UKFUpdate(slopeMedium) : 0.0;
      TrendSlope[i] = close[i] + rawSlope * 10.0; // Reduced scaling from Medium_Period to 10 for visibility
      SlopeVariance[i] = i >= 30 ? CalculateSlopeVariance(TrendSlope, i, 30, rates_total) : 0.0;

      // Additional features
      double consensus = i >= 30 ? CalculateCrossAssetConsensus(i, CorrelatedAssets, rates_total) : 0.0;
      double skewAdjustment = i >= 30 ? CalculateSkewnessAdjustment(close, i, rates_total) : 0.0;
      RegimeBuffer[i] = i >= minBarsRequired ? UpdateHMM(atr, SlopeVariance[i]) : 0.0;

      // Fuzzy logic consensus
      if(i >= minBarsRequired) {
         CalculateFuzzyScores(slopeShort, slopeMedium, slopeLong, consensus, skewAdjustment, RegimeBuffer[i],
                              FuzzyUp[i], FuzzyDown[i], FuzzyFlat[i]);

        // Color coding
         HmaColorBuffer[i] = (FuzzyUp[i] > FuzzyDown[i] && FuzzyUp[i] > FuzzyFlat[i]) ? 0 :
                             (FuzzyDown[i] > FuzzyUp[i] && FuzzyDown[i] > FuzzyFlat[i]) ? 2 : 1;
      }

      // Debug output for the first few bars
      if(i < 5) {
         Print("Bar ", i, ": Close=", close[i], ", TrendSlope=", TrendSlope[i], ", Color=", HmaColorBuffer[i]);
      }
      
      // Visualization
      if(ShowSignals && i >= minBarsRequired) {
         PlotSignals(i, time[i], high[i], low[i], FuzzyUp[i], FuzzyDown[i], FuzzyFlat[i],
                     TrendSlope[i], UpArrowColor, DownArrowColor, FlatArrowColor, ArrowSize, ArrowOffsetPoints);
      }
      if(ShowSHAP && i >= minBarsRequired && i % 5 == 0) {
         double shapValues[4];
         CalculateSHAPValues(slopeMedium, consensus, skewAdjustment, RegimeBuffer[i], shapValues);
         PlotSHAPChart(i, time[i], shapValues, TrendSlope[i]);
      }
   }
   return(rates_total);
}

// Deinitialization
void OnDeinit(const int reason) {
   if(atrHandle != INVALID_HANDLE) IndicatorRelease(atrHandle);
   ObjectsDeleteAll(0, "AMTC_");
   DeinitUKF();
   Print("AMTC v4.02 deinitialized");
}