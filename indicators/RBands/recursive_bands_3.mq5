//+--------------------------+
//| RecursiveBands.mq5       |
//| Copyright 2025, jechaviz |
//| jechaviz@gmail.com       |
//+--------------------------+
#property copyright "2025, jechaviz"
#property link      "jechaviz@gmail.com"
#property version   "1.14"

// **Indicator Properties**
#property indicator_chart_window
#property indicator_buffers 15 // Increased to include new color buffers
#property indicator_plots   4  // HMA, 1 band pair, HMA over Avg

// **Plot 0: HMA (colored)**
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  Gray, MediumPurple, Red
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

// **Input Parameters**
input bool ShowHMAPlot = true;    // Show HMA
input int HMA_Period = 13;         // Period HMA
input int HMA_Avg_Period = 13;     // Period HMA over average price
input int RB_Length = 100;         // Length used in recursive bands
enum RB_Method { RB_Classic, RB_Stdev };
input RB_Method RecursiveMethod = RB_Classic; // Volatility method for bands

// Arrow settings
input bool ShowArrows = false;            // Show HMA arrows
input color UpArrowColor = clrYellow;     // HMA Color arrows up
input color DownArrowColor = clrPink;     // HMA Color arrows down
input int ArrowSize = 1;                  // HMA Arrow width
input double ArrowOffsetPoints = 10;      // HMA Arrow Offset in points

// **Indicator Buffers**
double HmaBuffer[];       // Plot 0: HMA data
double HmaColorBuffer[];  // Plot 0: color index for HMA
double UpperBandBuffer[]; // Plot 1: Recursive Upper Band data
double UpperBandColorBuffer[]; // Plot 1: color index for Upper Band
double LowerBandBuffer[]; // Plot 2: Recursive Lower Band data
double LowerBandColorBuffer[]; // Plot 2: color index for Lower Band
double HmaAvgBuffer[];    // Plot 3: HMA over average price data
double HmaAvgColorBuffer[]; // Plot 3: color index for HMA over average

// Intermediate Buffers for Optimization
double WmaHalfBuffer[];   // WMA with half period for HMA
double WmaFullBuffer[];   // WMA with full period for HMA
double DiffBuffer[];      // Difference for HMA
double AvgBandBuffer[];   // Average of upper and lower bands
double WmaHalfAvgBuffer[];// WMA with half period for HMA over AvgBand
double WmaFullAvgBuffer[];// WMA with full period for HMA over AvgBand
double DiffAvgBuffer[];   // Difference for HMA over AvgBand

// **Global Variables**
int halfPeriod, halfPeriodAvg;
int sqrtPeriod, sqrtPeriodAvg;
double denom_half, denom_full, denom_sqrt;
double denom_half_avg, denom_full_avg, denom_sqrt_avg;
double sc; // Smoothing constant = 2 / (RB_Length+1)

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

double GetRecursiveVolatility(int bar, double delta, const double &price[]) {
   double vol = 0.0;
   switch (RecursiveMethod) {
      case RB_Stdev:
         vol = CalcStdev(bar, RB_Length, price);
         break;
      default: // RB_Classic
         vol = delta;
         break;
   }
   return vol;
}

int OnInit() {
   // Set up buffers
   SetIndexBuffer(0, HmaBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, HmaColorBuffer, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2, UpperBandBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, UpperBandColorBuffer, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(4, LowerBandBuffer, INDICATOR_DATA);
   SetIndexBuffer(5, LowerBandColorBuffer, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(6, HmaAvgBuffer, INDICATOR_DATA);
   SetIndexBuffer(7, HmaAvgColorBuffer, INDICATOR_COLOR_INDEX);
   // Intermediate buffers (calculation only)
   SetIndexBuffer(8, WmaHalfBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(9, WmaFullBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(10, DiffBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(11, AvgBandBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(12, WmaHalfAvgBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(13, WmaFullAvgBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(14, DiffAvgBuffer, INDICATOR_CALCULATIONS);

   // Set plot labels
   PlotIndexSetString(0, PLOT_LABEL, "HMA");
   PlotIndexSetString(1, PLOT_LABEL, "Recursive Upper Band");
   PlotIndexSetString(2, PLOT_LABEL, "Recursive Lower Band");
   PlotIndexSetString(3, PLOT_LABEL, "HMA over Avg");

   // Set indicator name
   IndicatorSetString(INDICATOR_SHORTNAME,
      "HMA + Recursive Bands (" + IntegerToString(HMA_Period) + ", " + IntegerToString(RB_Length) + ")");
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

   return (INIT_SUCCEEDED);
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
   if (CopyHigh(_Symbol, _Period, 0, rates_total, highArray) <= 0) return (0);
   if (CopyLow(_Symbol, _Period, 0, rates_total, lowArray) <= 0) return (0);
   if (CopyTime(_Symbol, _Period, 0, rates_total, Time) <= 0) return (0);

   // Set arrays as series
   ArraySetAsSeries(WmaHalfBuffer, true);
   ArraySetAsSeries(WmaFullBuffer, true);
   ArraySetAsSeries(DiffBuffer, true);
   ArraySetAsSeries(AvgBandBuffer, true);
   ArraySetAsSeries(WmaHalfAvgBuffer, true);
   ArraySetAsSeries(WmaFullAvgBuffer, true);
   ArraySetAsSeries(DiffAvgBuffer, true);

   // Determine starting point
   int start = (prev_calculated == 0 ? MathMax(HMA_Period + sqrtPeriod - 1, RB_Length) : prev_calculated - 1);

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

      // 3) Recursive Bands Calculation
      if (bar < RB_Length - 1) {
         UpperBandBuffer[bar] = EMPTY_VALUE;
         LowerBandBuffer[bar] = EMPTY_VALUE;
         AvgBandBuffer[bar] = price[bar];
         UpperBandColorBuffer[bar] = 0;
         LowerBandColorBuffer[bar] = 0;
      } else if (bar == RB_Length - 1) {
         UpperBandBuffer[bar] = price[bar];
         LowerBandBuffer[bar] = price[bar];
         AvgBandBuffer[bar] = price[bar];
         UpperBandColorBuffer[bar] = 0; // Default for first point
         LowerBandColorBuffer[bar] = 0;
      } else {
         double prevUpper = UpperBandBuffer[bar - 1];
         double prevLower = LowerBandBuffer[bar - 1];
         double deltaUpper = MathAbs(price[bar] - prevUpper);
         double deltaLower = MathAbs(price[bar] - prevLower);
         double volUpper = GetRecursiveVolatility(bar, deltaUpper, price);
         double volLower = GetRecursiveVolatility(bar, deltaLower, price);

         UpperBandBuffer[bar] = MathMax(prevUpper, price[bar]) - sc * volUpper;
         LowerBandBuffer[bar] = MathMin(prevLower, price[bar]) + sc * volLower;
         AvgBandBuffer[bar] = (UpperBandBuffer[bar] + LowerBandBuffer[bar]) / 2.0;

         // Set Upper Band color
         if (UpperBandBuffer[bar] > UpperBandBuffer[bar - 1])
            UpperBandColorBuffer[bar] = 0; // Rising (clrDodgerBlue)
         else
            UpperBandColorBuffer[bar] = 1; // Falling (clrNavy)

         // Set Lower Band color
         if (LowerBandBuffer[bar] > LowerBandBuffer[bar - 1])
            LowerBandColorBuffer[bar] = 0; // Rising (clrGold)
         else
            LowerBandColorBuffer[bar] = 1; // Falling (clrRed)
      }

      // **5) HMA over AvgBand (using AvgBandBuffer1)**
      if (bar >= halfPeriodAvg - 1) {
         WmaHalfAvgBuffer[bar] = CalculateLWMA(AvgBandBuffer, bar, halfPeriodAvg, denom_half_avg);
      } else {
         WmaHalfAvgBuffer[bar] = EMPTY_VALUE;
      }

      if (bar >= HMA_Avg_Period - 1) {
         WmaFullAvgBuffer[bar] = CalculateLWMA(AvgBandBuffer, bar, HMA_Avg_Period, denom_full_avg);
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
               if (HmaAvgBuffer[bar] > HmaAvgBuffer[bar - 1])
                  HmaAvgColorBuffer[bar] = 0; // Rising (clrLime)
               else
                  HmaAvgColorBuffer[bar] = 1; // Falling (clrDarkGreen)
            } else {
               HmaAvgColorBuffer[bar] = 0; // Default for first point
            }
         } else {
            HmaAvgColorBuffer[bar] = 0;
         }
      } else {
         HmaAvgBuffer[bar] = EMPTY_VALUE;
         HmaAvgColorBuffer[bar] = 0;
      }
   }

   return (rates_total);
}