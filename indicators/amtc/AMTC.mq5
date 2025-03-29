//+------------------------------------------------------------------+
//|                         AMTC.mq5                                 |
//| Copyright 2025, jechaviz                                         |
//| jechaviz@gmail.com                                               |
//+------------------------------------------------------------------+
#property copyright "2025, jechaviz"
#property link      "jechaviz@gmail.com"
#property version   "3.00"
#property indicator_chart_window
#property indicator_buffers 8
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
input bool   ShowSignals  = true;          // Show buy/sell/flat arrows
input bool   ShowSHAP     = false;         // Show SHAP dashboard
input color  UpArrowColor = clrLime;       // Up arrow color
input color  DownArrowColor = clrRed;      // Down arrow color
input color  FlatArrowColor = clrGray;     // Flat arrow color
input int    ArrowSize    = 1;             // Arrow width (1-5)
input double ArrowOffsetPoints = 10;       // Arrow offset in points
input string CorrelatedAssets = "EURUSD,GBPUSD,USDJPY"; // Correlated assets
input int    ParticleCount = 100;          // Number of particles for filtering (50-500)

// Buffers
double HmaShort[], HmaMedium[], HmaLong[], HmaColorBuffer[], TrendSlope[], FuzzyUp[], FuzzyDown[], FuzzyFlat[];

// Global Variables
int minBarsRequired;
double particleStates[];

// Initialization
int OnInit() {
   // Validate inputs
   if(Short_Period < 5 || Medium_Period < 5 || Long_Period < 5) {
      Print("Error: HMA periods must be at least 5");
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
   SetIndexBuffer(0, HmaMedium, INDICATOR_DATA);
   SetIndexBuffer(1, HmaColorBuffer, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2, TrendSlope, INDICATOR_DATA);
   SetIndexBuffer(3, FuzzyUp, INDICATOR_DATA);
   SetIndexBuffer(4, FuzzyDown, INDICATOR_DATA);
   SetIndexBuffer(5, FuzzyFlat, INDICATOR_DATA);
   SetIndexBuffer(6, HmaShort, INDICATOR_DATA);
   SetIndexBuffer(7, HmaLong, INDICATOR_DATA);

   // Configure plot
   PlotIndexSetString(0, PLOT_LABEL, "AMTC_HMA_Medium");
   IndicatorSetString(INDICATOR_SHORTNAME, "AMTC v3 (" + IntegerToString(Short_Period) + "," + IntegerToString(Medium_Period) + "," + IntegerToString(Long_Period) + ")");
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);

   // Calculate minimum bars required
   minBarsRequired = Long_Period + (int)MathSqrt(Long_Period) + 30;

   // Initialize particle filter and other components
   ArrayResize(particleStates, ParticleCount);
   InitHMM();
   InitUKF();
   OptimizeParameters(Short_Period, Medium_Period, Long_Period);

   Print("Initialized with optimized periods: Short=", Short_Period, ", Medium=", Medium_Period, ", Long=", Long_Period);
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
   if(rates_total < minBarsRequired) {
      Print("Insufficient bars: ", rates_total, " < ", minBarsRequired);
      return(0);
   }

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

   int atrHandle = iATR(_Symbol, _Period, 14);
   if(atrHandle == INVALID_HANDLE) {
      Print("Error: Failed to initialize ATR");
      return(0);
   }
   double atrArray[];
   CopyBuffer(atrHandle, 0, 0, rates_total, atrArray);
   ArraySetAsSeries(atrArray, true);

   int start = prev_calculated > 0 ? prev_calculated - 1 : minBarsRequired;

   for(int i = start; i < rates_total && !IsStopped(); i++) {
      // Volatility-adjusted periods
      double atr = atrArray[i];
      if(atr == 0) continue;
      double adjustedShort = CalculateAdjustedPeriod(Short_Period, atr, VolatilitySensitivity);
      double adjustedMedium = CalculateAdjustedPeriod(Medium_Period, atr, VolatilitySensitivity);
      double adjustedLong = CalculateAdjustedPeriod(Long_Period, atr, VolatilitySensitivity);

      // Multi-scale HMA calculation
      HmaShort[i] = CalculateHMA(close, i, (int)adjustedShort, rates_total);
      HmaMedium[i] = CalculateHMA(close, i, (int)adjustedMedium, rates_total);
      HmaLong[i] = CalculateHMA(close, i, (int)adjustedLong, rates_total);

      // Non-linear slope estimation
      double slopeShort = CalculateNonLinearSlope(HmaShort, i, (int)adjustedShort, rates_total);
      double slopeMedium = CalculateNonLinearSlope(HmaMedium, i, (int)adjustedMedium, rates_total);
      double slopeLong = CalculateNonLinearSlope(HmaLong, i, (int)adjustedLong, rates_total);

      // UKF filtering on medium-term slope
      TrendSlope[i] = UKFUpdate(slopeMedium);

      // Additional features
      double consensus = CalculateCrossAssetConsensus(i, CorrelatedAssets, rates_total);
      double skewAdjustment = CalculateSkewnessAdjustment(close, i, rates_total);
      double regime = GetCurrentRegime();

      // Fuzzy logic consensus
      CalculateFuzzyScores(slopeShort, slopeMedium, slopeLong, consensus, skewAdjustment, regime,
                           FuzzyUp[i], FuzzyDown[i], FuzzyFlat[i]);

      // Color coding
      HmaColorBuffer[i] = (FuzzyUp[i] > FuzzyDown[i] && FuzzyUp[i] > FuzzyFlat[i]) ? 0 : // Up (LimeGreen)
                          (FuzzyDown[i] > FuzzyUp[i] && FuzzyDown[i] > FuzzyFlat[i]) ? 2 : // Down (Red)
                          1; // Flat (Orange)

      // Plot signals
      if(ShowSignals && i > minBarsRequired) {
         PlotSignals(i, time[i], high[i], low[i], FuzzyUp[i], FuzzyDown[i], FuzzyFlat[i],
                     HmaMedium[i], UpArrowColor, DownArrowColor, FlatArrowColor, ArrowSize, ArrowOffsetPoints);
      }

      // SHAP dashboard
      if(ShowSHAP && i > minBarsRequired && i % 5 == 0) {
         double shapValues[4];
         CalculateSHAPValues(slopeMedium, consensus, skewAdjustment, regime, shapValues);
         PlotSHAPChart(i, time[i], shapValues, HmaMedium[i]);
      }
   }
   return(rates_total);
}

// Deinitialization
void OnDeinit(const int reason) {
   ObjectsDeleteAll(0, "AMTC_");
}