//+--------------------------+
//| RecursiveBands.mq5       |
//| Copyright 2025, jechaviz |
//| jechaviz@gmail.com       |
//+--------------------------+
#property copyright "2025, jechaviz"
#property link      "jechaviz@gmail.com"
#property version   "1.15"

// **Indicator Properties**
#property indicator_chart_window
#property indicator_buffers 22 // Increased for additional buffers
#property indicator_plots   6  // 6 plots: HMA, 2 band pairs, HMA over Avg

// **Plot 0: HMA (colored)**
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrGray, clrMediumPurple, clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

// **Plot 1: Recursive Upper Band 1 (colored)**
#property indicator_type2   DRAW_COLOR_LINE
#property indicator_color2  clrDodgerBlue, clrDarkKhaki
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

// **Plot 2: Recursive Lower Band 1 (colored)**
#property indicator_type3   DRAW_COLOR_LINE
#property indicator_color3  clrGold, clrRed
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2

// **Plot 3: HMA over Average Price (colored)**
#property indicator_type4   DRAW_COLOR_LINE
#property indicator_color4  clrLime, clrDarkGreen
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2

// **Plot 4: Recursive Upper Band 2 (colored)**
#property indicator_type5   DRAW_COLOR_LINE
#property indicator_color5  clrBlue, clrOrange
#property indicator_style5  STYLE_SOLID
#property indicator_width5  2

// **Plot 5: Recursive Lower Band 2 (colored)**
#property indicator_type6   DRAW_COLOR_LINE
#property indicator_color6  clrBlue, clrOrange
#property indicator_style6  STYLE_SOLID
#property indicator_width6  2

// **Input Parameters**
input bool ShowHMAPlot = true;          // Show HMA
input int HMA_Period = 13;              // Period HMA
input int HMA_Avg_Period = 13;          // Period HMA over average price
input int RB_Length = 100;              // Length used in recursive bands

// Unified Volatility Methods
enum RB_Method {
   RB_Classic,  // Classic volatility
   RB_ATR,      // Average True Range
   RB_Stdev,    // Standard Deviation
   RB_Ahlr,     // Average High-Low Range
   RB_Rfv,      // Range for Volatility
   RB_HMA       // HMA-based Volatility
};
input RB_Method RecursiveMethod1 = RB_Classic; // Volatility method for bands 1
input RB_Method RecursiveMethod2 = RB_ATR;     // Volatility method for bands 2

// Specific lengths per method for bands 1
input int Length_ATR1 = 64;    // ATR Length for bands 1
input int Length_Stdev1 = 306; // Stdev Length for bands 1
input int Length_Ahlr1 = 64;   // Ahlr Length for bands 1
input int Length_Rfv1 = 9;     // Rfv Length for bands 1
input int Length_HMA1 = 9;     // HMA Volatility Length for bands 1

// Specific lengths per method for bands 2
input int Length_ATR2 = 14;    // ATR Length for bands 2
input int Length_Stdev2 = 100; // Stdev Length for bands 2
input int Length_Ahlr2 = 20;   // Ahlr Length for bands 2
input int Length_Rfv2 = 5;     // Rfv Length for bands 2
input int Length_HMA2 = 20;    // HMA Volatility Length for bands 2

// Arrow settings
input bool ShowArrows = false;            // Show HMA arrows
input color UpArrowColor = clrYellow;     // HMA Color arrows up
input color DownArrowColor = clrPink;     // HMA Color arrows down
input int ArrowSize = 1;                  // HMA Arrow width
input double ArrowOffsetPoints = 10;      // HMA Arrow Offset in points

// **Indicator Buffers**
double HmaBuffer[];       // Plot 0: HMA data
double HmaColorBuffer[];  // Plot 0: color index for HMA
double UpperBandBuffer1[];// Plot 1: Recursive Upper Band 1 data
double UpperBandColorBuffer1[];// Plot 1: color index for Upper Band 1
double LowerBandBuffer1[];// Plot 2: Recursive Lower Band 1 data
double LowerBandColorBuffer1[];// Plot 2: color index for Lower Band 1
double HmaAvgBuffer[];    // Plot 3: HMA over average price data
double HmaAvgColorBuffer[];// Plot 3: color index for HMA over average
double UpperBandBuffer2[];// Plot 4: Recursive Upper Band 2 data
double UpperBandColorBuffer2[];// Plot 4: color index for Upper Band 2
double LowerBandBuffer2[];// Plot 5: Recursive Lower Band 2 data
double LowerBandColorBuffer2[];// Plot 5: color index for Lower Band 2

// Intermediate Buffers for Optimization
double WmaHalfBuffer[];   // WMA with half period for HMA
double WmaFullBuffer[];   // WMA with full period for HMA
double DiffBuffer[];      // Difference for HMA
double AvgBandBuffer1[];  // Average of upper and lower bands 1
double AvgBandBuffer2[];  // Average of upper and lower bands 2
double WmaHalfAvgBuffer[];// WMA with half period for HMA over AvgBand
double WmaFullAvgBuffer[];// WMA with full period for HMA over AvgBand
double DiffAvgBuffer[];   // Difference for HMA over AvgBand
double ATRBuffer1[];      // Buffer for ATR of bands 1
double ATRBuffer2[];      // Buffer for ATR of bands 2

// **Global Variables**
int halfPeriod, halfPeriodAvg;
int sqrtPeriod, sqrtPeriodAvg;
double denom_half, denom_full, denom_sqrt;
double denom_half_avg, denom_full_avg, denom_sqrt_avg;
double sc; // Smoothing constant = 2 / (RB_Length+1)
int atrHandle1 = INVALID_HANDLE; // Handle for ATR of bands 1
int atrHandle2 = INVALID_HANDLE; // Handle for ATR of bands 2

// **Custom Functions**

// Calculate Linear Weighted Moving Average (LWMA)
double CalculateLWMA(const double &data[], int bar, int period, double denominator) {
   double sum = 0.0;
   for (int i = 0; i < period && (bar - i) >= 0; i++) {
      if (data[bar - i] == EMPTY_VALUE) return EMPTY_VALUE;
      sum += data[bar - i] * (period - i);
   }
   return (sum / denominator);
}

// Calculate Standard Deviation
double CalcStdev(int bar, int period, const double &price[]) {
   if (bar < period - 1) return 0.0;
   double sum = 0.0, sumSq = 0.0;
   for (int i = 0; i < period; i++) {
      double p = price[bar - i];
      sum += p;
      sumSq += p * p;
   }
   double mean = sum / period;
   double variance = (sumSq / period) - (mean * mean);
   return MathSqrt(variance);
}

// Calculate Average High-Low Range
double CalculateAhlr(int bar, int length, const double &high[], const double &low[]) {
   if (bar < length - 1) return 0.0;
   double sum = 0.0;
   for (int i = 0; i < length; i++) {
      sum += high[bar - i] - low[bar - i];
   }
   return sum / length;
}

// Calculate Range for Volatility (Rfv)
double CalculateRfv(int bar, int length, const double &price[]) {
   if (bar < length) return 0.0;
   double prev = price[bar - length];
   double curr = price[bar];
   bool rising = true, falling = true;
   for (int i = 1; i < length; i++) {
      if (price[bar - i] <= price[bar - i - 1]) rising = false;
      if (price[bar - i] >= price[bar - i - 1]) falling = false;
   }
   if (rising || falling) return MathAbs(curr - prev);
   return 0.0; // Persists previous value if no clear trend
}

// Calculate HMA-based Volatility
double CalculateHmaVol(int bar, int length, const double &price[]) {
   if (bar < length - 1) return 0.0;
   double hma = CalculateLWMA(price, bar, length, length * (length + 1) / 2.0);
   double sum = 0.0;
   for (int i = 0; i < length; i++) {
      sum += MathAbs(price[bar - i] - hma);
   }
   return sum / length;
}

// Get Volatility based on method and band pair
double GetVolatility(int bar, RB_Method method, int length, const double &price[], const double &high[], const double &low[], int bandPair) {
   switch (method) {
      case RB_ATR:
         if (bandPair == 1) return (atrHandle1 != INVALID_HANDLE) ? ATRBuffer1[bar] : 0.0;
         else if (bandPair == 2) return (atrHandle2 != INVALID_HANDLE) ? ATRBuffer2[bar] : 0.0;
         break;
      case RB_Stdev:
         return CalcStdev(bar, length, price);
      case RB_Ahlr:
         return CalculateAhlr(bar, length, high, low);
      case RB_Rfv:
         return CalculateRfv(bar, length, price);
      case RB_HMA:
         return CalculateHmaVol(bar, length, price);
      default:
         return 0.0;
   }
   return 0.0;
}

// Get length for the selected method
int GetLengthForMethod(RB_Method method, int bandPair) {
   if (bandPair == 1) {
      switch (method) {
         case RB_ATR: return Length_ATR1;
         case RB_Stdev: return Length_Stdev1;
         case RB_Ahlr: return Length_Ahlr1;
         case RB_Rfv: return Length_Rfv1;
         case RB_HMA: return Length_HMA1;
         default: return RB_Length;
      }
   } else if (bandPair == 2) {
      switch (method) {
         case RB_ATR: return Length_ATR2;
         case RB_Stdev: return Length_Stdev2;
         case RB_Ahlr: return Length_Ahlr2;
         case RB_Rfv: return Length_Rfv2;
         case RB_HMA: return Length_HMA2;
         default: return RB_Length;
      }
   }
   return RB_Length;
}

// **Initialization**
int OnInit() {
   // Set up buffers
   SetIndexBuffer(0, HmaBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, HmaColorBuffer, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2, UpperBandBuffer1, INDICATOR_DATA);
   SetIndexBuffer(3, UpperBandColorBuffer1, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(4, LowerBandBuffer1, INDICATOR_DATA);
   SetIndexBuffer(5, LowerBandColorBuffer1, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(6, HmaAvgBuffer, INDICATOR_DATA);
   SetIndexBuffer(7, HmaAvgColorBuffer, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(8, UpperBandBuffer2, INDICATOR_DATA);
   SetIndexBuffer(9, UpperBandColorBuffer2, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(10, LowerBandBuffer2, INDICATOR_DATA);
   SetIndexBuffer(11, LowerBandColorBuffer2, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(12, WmaHalfBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(13, WmaFullBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(14, DiffBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(15, AvgBandBuffer1, INDICATOR_CALCULATIONS);
   SetIndexBuffer(16, AvgBandBuffer2, INDICATOR_CALCULATIONS);
   SetIndexBuffer(17, WmaHalfAvgBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(18, WmaFullAvgBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(19, DiffAvgBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(20, ATRBuffer1, INDICATOR_CALCULATIONS);
   SetIndexBuffer(21, ATRBuffer2, INDICATOR_CALCULATIONS);

   // Plot labels
   PlotIndexSetString(0, PLOT_LABEL, "HMA");
   PlotIndexSetString(1, PLOT_LABEL, "Upper Band 1");
   PlotIndexSetString(2, PLOT_LABEL, "Lower Band 1");
   PlotIndexSetString(3, PLOT_LABEL, "HMA over Avg");
   PlotIndexSetString(4, PLOT_LABEL, "Upper Band 2");
   PlotIndexSetString(5, PLOT_LABEL, "Lower Band 2");

   // Indicator name
   string method1_str = EnumToString(RecursiveMethod1);
   string method2_str = EnumToString(RecursiveMethod2);
   IndicatorSetString(INDICATOR_SHORTNAME,
      "HMA + Recursive Bands (" + IntegerToString(HMA_Period) + ", " + IntegerToString(RB_Length) + ", " + method1_str + ", " + method2_str + ")");
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);

   // HMA calculations
   halfPeriod = HMA_Period / 2;
   sqrtPeriod = (int) MathSqrt(HMA_Period);
   denom_half = halfPeriod * (halfPeriod + 1) / 2.0;
   denom_full = HMA_Period * (HMA_Period + 1) / 2.0;
   denom_sqrt = sqrtPeriod * (sqrtPeriod + 1) / 2.0;

   // HMA over average price calculations
   halfPeriodAvg = HMA_Avg_Period / 2;
   sqrtPeriodAvg = (int) MathSqrt(HMA_Avg_Period);
   denom_half_avg = halfPeriodAvg * (halfPeriodAvg + 1) / 2.0;
   denom_full_avg = HMA_Avg_Period * (HMA_Avg_Period + 1) / 2.0;
   denom_sqrt_avg = sqrtPeriodAvg * (sqrtPeriodAvg + 1) / 2.0;

   // Smoothing constant
   sc = 2.0 / (RB_Length + 1);

   // Set up ATR handles if needed
   if (RecursiveMethod1 == RB_ATR) atrHandle1 = iATR(_Symbol, _Period, Length_ATR1);
   if (RecursiveMethod2 == RB_ATR) atrHandle2 = iATR(_Symbol, _Period, Length_ATR2);

   return INIT_SUCCEEDED;
}

// **Deinitialization**
void OnDeinit(const int reason) {
   // Array of object name prefixes to delete
   string prefixes[] = {"UpArrow_", "DownArrow_"};

   // Loop through each prefix
   for (int p = 0; p < ArraySize(prefixes); p++) {
      string prefix = prefixes[p];
      // Get total number of objects on the chart
      int obj_total = ObjectsTotal(0, 0, -1); // Chart ID 0, main window, all object types
      // Iterate backwards to safely delete objects
      for (int i = obj_total - 1; i >= 0; i--) {
         string name = ObjectName(0, i, 0, -1); // Get object name
         // Check if the object name starts with the prefix
         if (StringFind(name, prefix) == 0) {
            ObjectDelete(0, name); // Delete the object
         }
      }
   }
}

// **Main Calculation Function**
int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[]) {
   if (rates_total < MathMax(HMA_Period + sqrtPeriod - 1, RB_Length))
      return 0;

   // Copy additional price data
   double highArray[], lowArray[];
   datetime Time[];
   if (CopyHigh(_Symbol, _Period, 0, rates_total, highArray) <= 0) return 0;
   if (CopyLow(_Symbol, _Period, 0, rates_total, lowArray) <= 0) return 0;
   if (CopyTime(_Symbol, _Period, 0, rates_total, Time) <= 0) return 0;

   // Copy ATR data if applicable
   if (atrHandle1 != INVALID_HANDLE) CopyBuffer(atrHandle1, 0, 0, rates_total, ATRBuffer1);
   if (atrHandle2 != INVALID_HANDLE) CopyBuffer(atrHandle2, 0, 0, rates_total, ATRBuffer2);

   // Set arrays as timeseries
   ArraySetAsSeries(HmaBuffer, true);
   ArraySetAsSeries(HmaColorBuffer, true);
   ArraySetAsSeries(UpperBandBuffer1, true);
   ArraySetAsSeries(UpperBandColorBuffer1, true);
   ArraySetAsSeries(LowerBandBuffer1, true);
   ArraySetAsSeries(LowerBandColorBuffer1, true);
   ArraySetAsSeries(HmaAvgBuffer, true);
   ArraySetAsSeries(HmaAvgColorBuffer, true);
   ArraySetAsSeries(UpperBandBuffer2, true);
   ArraySetAsSeries(UpperBandColorBuffer2, true);
   ArraySetAsSeries(LowerBandBuffer2, true);
   ArraySetAsSeries(LowerBandColorBuffer2, true);
   ArraySetAsSeries(WmaHalfBuffer, true);
   ArraySetAsSeries(WmaFullBuffer, true);
   ArraySetAsSeries(DiffBuffer, true);
   ArraySetAsSeries(AvgBandBuffer1, true);
   ArraySetAsSeries(AvgBandBuffer2, true);
   ArraySetAsSeries(WmaHalfAvgBuffer, true);
   ArraySetAsSeries(WmaFullAvgBuffer, true);
   ArraySetAsSeries(DiffAvgBuffer, true);
   ArraySetAsSeries(price, true);
   ArraySetAsSeries(highArray, true);
   ArraySetAsSeries(lowArray, true);
   ArraySetAsSeries(Time, true);
   ArraySetAsSeries(ATRBuffer1, true);
   ArraySetAsSeries(ATRBuffer2, true);

   // Determine starting point
   int start = prev_calculated > 0 ? prev_calculated - 1 : 0;

   for (int bar = start; bar < rates_total; bar++) {
      // **1) HMA Calculation**
      if (bar >= halfPeriod - 1) {
         WmaHalfBuffer[bar] = CalculateLWMA(price, bar, halfPeriod, denom_half);
      } else {
         WmaHalfBuffer[bar] = EMPTY_VALUE;
      }

      if (bar >= HMA_Period - 1) {
         WmaFullBuffer[bar] = CalculateLWMA(price, bar, HMA_Period, denom_full);
         DiffBuffer[bar] = (WmaHalfBuffer[bar] != EMPTY_VALUE && WmaFullBuffer[bar] != EMPTY_VALUE)
                           ? 2.0 * WmaHalfBuffer[bar] - WmaFullBuffer[bar] : EMPTY_VALUE;
      } else {
         WmaFullBuffer[bar] = EMPTY_VALUE;
         DiffBuffer[bar] = EMPTY_VALUE;
      }

      if (bar >= HMA_Period - 1 + sqrtPeriod - 1) {
         double hma = CalculateLWMA(DiffBuffer, bar, sqrtPeriod, denom_sqrt);
         if (ShowHMAPlot && hma != EMPTY_VALUE) {
            HmaBuffer[bar] = hma;
            if (bar > 0 && HmaBuffer[bar - 1] != EMPTY_VALUE) {
               if (hma > HmaBuffer[bar - 1])
                  HmaColorBuffer[bar] = 0; // Gray (up)
               else if (hma < HmaBuffer[bar - 1])
                  HmaColorBuffer[bar] = 2; // Red (down)
               else
                  HmaColorBuffer[bar] = 1; // Purple (flat)
            } else {
               HmaColorBuffer[bar] = 0;
            }
         } else {
            HmaBuffer[bar] = EMPTY_VALUE;
            HmaColorBuffer[bar] = 0;
         }
      } else {
         HmaBuffer[bar] = EMPTY_VALUE;
         HmaColorBuffer[bar] = 0;
      }

      // **2) Draw Arrows**
      if (bar > 0 && ShowArrows && ShowHMAPlot) {
         if (HmaColorBuffer[bar] == 0 && HmaColorBuffer[bar - 1] != 0) {
            string objName = "UpArrow_" + IntegerToString(bar);
            if (ObjectFind(0, objName) < 0) {
               double offset = ArrowOffsetPoints * _Point;
               double arrowPrice = lowArray[bar] - offset;
               ObjectCreate(0, objName, OBJ_ARROW, 0, Time[bar], arrowPrice);
               ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, 233);
               ObjectSetInteger(0, objName, OBJPROP_COLOR, UpArrowColor);
               ObjectSetInteger(0, objName, OBJPROP_WIDTH, ArrowSize);
               ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_TOP);
            }
         } else if (HmaColorBuffer[bar] == 2 && HmaColorBuffer[bar - 1] != 2) {
            string objName = "DownArrow_" + IntegerToString(bar);
            if (ObjectFind(0, objName) < 0) {
               double offset = ArrowOffsetPoints * _Point;
               double arrowPrice = highArray[bar] + offset;
               ObjectCreate(0, objName, OBJ_ARROW, 0, Time[bar], arrowPrice);
               ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, 234);
               ObjectSetInteger(0, objName, OBJPROP_COLOR, DownArrowColor);
               ObjectSetInteger(0, objName, OBJPROP_WIDTH, ArrowSize);
               ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
            }
         }
      }

      // **3) Recursive Bands Calculation - Band Pair 1**
      if (bar < RB_Length - 1) {
         UpperBandBuffer1[bar] = EMPTY_VALUE;
         LowerBandBuffer1[bar] = EMPTY_VALUE;
         AvgBandBuffer1[bar] = price[bar];
         UpperBandColorBuffer1[bar] = 0;
         LowerBandColorBuffer1[bar] = 0;
      } else if (bar == RB_Length - 1) {
         UpperBandBuffer1[bar] = price[bar];
         LowerBandBuffer1[bar] = price[bar];
         AvgBandBuffer1[bar] = price[bar];
         UpperBandColorBuffer1[bar] = 0;
         LowerBandColorBuffer1[bar] = 0;
      } else {
         double prevUpper1 = UpperBandBuffer1[bar - 1];
         double prevLower1 = LowerBandBuffer1[bar - 1];
         double volUpper1, volLower1;
         if (RecursiveMethod1 == RB_Classic) {
            volUpper1 = MathAbs(price[bar] - prevUpper1);
            volLower1 = MathAbs(price[bar] - prevLower1);
         } else {
            int length1 = GetLengthForMethod(RecursiveMethod1, 1);
            double volatility1 = GetVolatility(bar, RecursiveMethod1, length1, price, highArray, lowArray, 1);
            volUpper1 = volatility1;
            volLower1 = volatility1;
         }
         UpperBandBuffer1[bar] = MathMax(prevUpper1, price[bar]) - sc * volUpper1;
         LowerBandBuffer1[bar] = MathMin(prevLower1, price[bar]) + sc * volLower1;
         AvgBandBuffer1[bar] = (UpperBandBuffer1[bar] + LowerBandBuffer1[bar]) / 2.0;
         if (UpperBandBuffer1[bar] > UpperBandBuffer1[bar - 1])
            UpperBandColorBuffer1[bar] = 0; // Rising
         else
            UpperBandColorBuffer1[bar] = 1; // Falling
         if (LowerBandBuffer1[bar] > LowerBandBuffer1[bar - 1])
            LowerBandColorBuffer1[bar] = 0; // Rising
         else
            LowerBandColorBuffer1[bar] = 1; // Falling
      }

      // **4) Recursive Bands Calculation - Band Pair 2**
      if (bar < RB_Length - 1) {
         UpperBandBuffer2[bar] = EMPTY_VALUE;
         LowerBandBuffer2[bar] = EMPTY_VALUE;
         AvgBandBuffer2[bar] = price[bar];
         UpperBandColorBuffer2[bar] = 0;
         LowerBandColorBuffer2[bar] = 0;
      } else if (bar == RB_Length - 1) {
         UpperBandBuffer2[bar] = price[bar];
         LowerBandBuffer2[bar] = price[bar];
         AvgBandBuffer2[bar] = price[bar];
         UpperBandColorBuffer2[bar] = 0;
         LowerBandColorBuffer2[bar] = 0;
      } else {
         double prevUpper2 = UpperBandBuffer2[bar - 1];
         double prevLower2 = LowerBandBuffer2[bar - 1];
         double volUpper2, volLower2;
         if (RecursiveMethod2 == RB_Classic) {
            volUpper2 = MathAbs(price[bar] - prevUpper2);
            volLower2 = MathAbs(price[bar] - prevLower2);
         } else {
            int length2 = GetLengthForMethod(RecursiveMethod2, 2);
            double volatility2 = GetVolatility(bar, RecursiveMethod2, length2, price, highArray, lowArray, 2);
            volUpper2 = volatility2;
            volLower2 = volatility2;
         }
         UpperBandBuffer2[bar] = MathMax(prevUpper2, price[bar]) - sc * volUpper2;
         LowerBandBuffer2[bar] = MathMin(prevLower2, price[bar]) + sc * volLower2;
         AvgBandBuffer2[bar] = (UpperBandBuffer2[bar] + LowerBandBuffer2[bar]) / 2.0;
         if (UpperBandBuffer2[bar] > UpperBandBuffer2[bar - 1])
            UpperBandColorBuffer2[bar] = 0; // Rising
         else
            UpperBandColorBuffer2[bar] = 1; // Falling
         if (LowerBandBuffer2[bar] > LowerBandBuffer2[bar - 1])
            LowerBandColorBuffer2[bar] = 0; // Rising
         else
            LowerBandColorBuffer2[bar] = 1; // Falling
      }

      // **5) HMA over AvgBand (using AvgBandBuffer1)**
      if (bar >= halfPeriodAvg - 1) {
         WmaHalfAvgBuffer[bar] = CalculateLWMA(AvgBandBuffer1, bar, halfPeriodAvg, denom_half_avg);
      } else {
         WmaHalfAvgBuffer[bar] = EMPTY_VALUE;
      }

      if (bar >= HMA_Avg_Period - 1) {
         WmaFullAvgBuffer[bar] = CalculateLWMA(AvgBandBuffer1, bar, HMA_Avg_Period, denom_full_avg);
         DiffAvgBuffer[bar] = (WmaHalfAvgBuffer[bar] != EMPTY_VALUE && WmaFullAvgBuffer[bar] != EMPTY_VALUE)
                              ? 2.0 * WmaHalfAvgBuffer[bar] - WmaFullAvgBuffer[bar] : EMPTY_VALUE;
      } else {
         WmaFullAvgBuffer[bar] = EMPTY_VALUE;
         DiffAvgBuffer[bar] = EMPTY_VALUE;
      }

      if (bar >= HMA_Avg_Period - 1 + sqrtPeriodAvg - 1) {
         HmaAvgBuffer[bar] = CalculateLWMA(DiffAvgBuffer, bar, sqrtPeriodAvg, denom_sqrt_avg);
         if (HmaAvgBuffer[bar] != EMPTY_VALUE) {
            if (bar > 0 && HmaAvgBuffer[bar - 1] != EMPTY_VALUE) {
               HmaAvgColorBuffer[bar] = (HmaAvgBuffer[bar] > HmaAvgBuffer[bar - 1]) ? 0 : 1; // Lime or DarkGreen
            } else {
               HmaAvgColorBuffer[bar] = 0;
            }
         } else {
            HmaAvgColorBuffer[bar] = 0;
         }
      } else {
         HmaAvgBuffer[bar] = EMPTY_VALUE;
         HmaAvgColorBuffer[bar] = 0;
      }
   }

   return rates_total;
}