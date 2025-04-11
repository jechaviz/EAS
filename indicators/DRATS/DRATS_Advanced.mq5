//+------------------------------------------------------------------+
//|                         DRATS_Advanced.mq5                       |
//| Copyright 2025, jechaviz                                         |
//| jechaviz@gmail.com                                               |
//+------------------------------------------------------------------+
#property copyright "2025, jechaviz"
#property link      "jechaviz@gmail.com"
#property version   "1.01"
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   1

// Plot 0: DRATS with color-coded states (up: green, flat: yellow, down: red)
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrLimeGreen, clrYellow, clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

// Includes
#include "DRATS_HMA.mqh"
#include "DRATS_QuantumFilter.mqh"
#include "DRATS_Fuzzy.mqh"

// Input Parameters (aligned with paper)
input int    BasePeriod     = 9;          // Base period for HMA
input double Beta           = 0.6;        // Volatility adjustment factor
input double Delta          = 5.0;        // Slope scaling for tanh
input double Alpha          = 1.2;        // Threshold scaling
input double Eta            = 0.25;       // Skewness adjustment

// Buffers
double DRATS[],          // Main indicator output with stepped visualization
       ColorBuffer[],    // Color indices: 0=green (up), 1=yellow (flat), 2=red (down)
       HMA[],            // Hull Moving Average
       ATR[],            // ATR values
       SlopeFiltered[],  // Quantum-filtered slope
       Skewness[];       // Skewness values

// Global Variables
int atrHandle = INVALID_HANDLE;
int minBarsRequired = 50; // Minimum bars for ATR average and HMA calculation

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
   // Set indicator buffers
   SetIndexBuffer(0, DRATS, INDICATOR_DATA);
   SetIndexBuffer(1, ColorBuffer, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2, HMA, INDICATOR_DATA);
   SetIndexBuffer(3, ATR, INDICATOR_DATA);
   SetIndexBuffer(4, SlopeFiltered, INDICATOR_DATA);
   SetIndexBuffer(5, Skewness, INDICATOR_DATA);

   // Configure plot properties
   PlotIndexSetString(0, PLOT_LABEL, "DRATS");
   IndicatorSetString(INDICATOR_SHORTNAME, "DRATS Advanced v1.01");
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);

   // Initialize ATR indicator
   atrHandle = iATR(_Symbol, _Period, 14);
   if (atrHandle == INVALID_HANDLE) {
      Print("Error: Failed to initialize ATR indicator");
      return INIT_FAILED;
   }

   Print("DRATS Advanced v1.01 initialized successfully");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
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
   if (rates_total < minBarsRequired) {
      Print("Insufficient bars: ", rates_total, " < ", minBarsRequired);
      return 0;
   }

   // Set arrays as series
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(time, true);
   ArraySetAsSeries(DRATS, true);
   ArraySetAsSeries(ColorBuffer, true);
   ArraySetAsSeries(HMA, true);
   ArraySetAsSeries(ATR, true);
   ArraySetAsSeries(SlopeFiltered, true);
   ArraySetAsSeries(Skewness, true);

   // Copy ATR data
   if (CopyBuffer(atrHandle, 0, 0, rates_total, ATR) < rates_total) {
      Print("Error: Failed to copy ATR data");
      return 0;
   }

   int start = (prev_calculated == 0) ? minBarsRequired : prev_calculated - 1;

   for (int i = start; i < rates_total && !IsStopped(); i++) {
      // Calculate ATR average (50-period SMA)
      double atr_avg = 0.0;
      int atr_count = MathMin(i + 1, 50);
      for (int j = 0; j < atr_count; j++) atr_avg += ATR[i - j];
      atr_avg /= atr_count;

      // Volatility-adjusted HMA period
      double p1_t = BasePeriod * (1 + Beta * (ATR[i] / (atr_avg > 0 ? atr_avg : ATR[i])));

      // Calculate HMA
      HMA[i] = CalculateHMA(close, i, p1_t, rates_total);

      if (i >= minBarsRequired) {
         // Calculate slope
         double slope = (HMA[i] - HMA[i - (int)(p1_t / 2)]) / (p1_t / 2);
         double s_t = QuantumFilter(slope, Delta);
         SlopeFiltered[i] = s_t;

         // Calculate skewness
         Skewness[i] = CalculateSkewness(close, i, 20, rates_total);

         // Fuzzy classification
         double theta_t = Alpha * ATR[i] * (1 + Eta * MathAbs(Skewness[i]));
         double mu_up = MathMax(0, MathMin(1, (s_t - theta_t) / (theta_t > 0 ? theta_t : 1e-10)));
         double mu_down = MathMax(0, MathMin(1, (-s_t - theta_t) / (theta_t > 0 ? theta_t : 1e-10)));
         double mu_flat = 1 - MathMax(mu_up, mu_down);

         // Determine state
         int state;
         if (mu_up > mu_down && mu_up > mu_flat) state = 0; // Up
         else if (mu_down > mu_up && mu_down > mu_flat) state = 2; // Down
         else state = 1; // Flat

         ColorBuffer[i] = state;

         // Stepped visualization
         if (i == minBarsRequired) DRATS[i] = HMA[i];
         else DRATS[i] = (state == 1) ? DRATS[i-1] : HMA[i];
      } else {
         DRATS[i] = HMA[i];
         ColorBuffer[i] = 1; // Flat
         SlopeFiltered[i] = 0.0;
         Skewness[i] = 0.0;
      }
   }

   return rates_total;
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   if (atrHandle != INVALID_HANDLE) {
      IndicatorRelease(atrHandle);
      atrHandle = INVALID_HANDLE;
   }
   Print("DRATS Advanced v1.01 deinitialized, reason: ", reason);
}