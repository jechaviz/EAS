//+------------------------------------------------------------------+
//|                      AMTC_Visualizer.mqh                         |
//+------------------------------------------------------------------+
#ifndef AMTC_VISUALIZER_MQH
#define AMTC_VISUALIZER_MQH

// Plot buy/sell/flat signals as arrows
void PlotSignals(int bar, datetime time, double high, double low, double upScore, double downScore, double flatScore,
                 double hma, color upColor, color downColor, color flatColor, int size, double offset) {
   string prefix = "AMTC_Signal_";
   double offsetPoints = offset * _Point;

   // Up signal
   if(upScore > downScore && upScore > flatScore && (bar == 0 || FuzzyUp[bar-1] <= MathMax(FuzzyDown[bar-1], FuzzyFlat[bar-1]))) {
      string name = prefix + "Up_" + IntegerToString(bar);
      if(ObjectFind(0, name) < 0) {
         ObjectCreate(0, name, OBJ_ARROW_UP, 0, time, low - offsetPoints);
         ObjectSetInteger(0, name, OBJPROP_COLOR, upColor);
         ObjectSetInteger(0, name, OBJPROP_WIDTH, MathMin(5, MathMax(1, size)));
      }
   }

   // Down signal
   if(downScore > upScore && downScore > flatScore && (bar == 0 || FuzzyDown[bar-1] <= MathMax(FuzzyUp[bar-1], FuzzyFlat[bar-1]))) {
      string name = prefix + "Down_" + IntegerToString(bar);
      if(ObjectFind(0, name) < 0) {
         ObjectCreate(0, name, OBJ_ARROW_DOWN, 0, time, high + offsetPoints);
         ObjectSetInteger(0, name, OBJPROP_COLOR, downColor);
         ObjectSetInteger(0, name, OBJPROP_WIDTH, MathMin(5, MathMax(1, size)));
      }
   }

   // Flat signal
   if(flatScore > upScore && flatScore > downScore && (bar == 0 || FuzzyFlat[bar-1] <= MathMax(FuzzyUp[bar-1], FuzzyDown[bar-1]))) {
      string name = prefix + "Flat_" + IntegerToString(bar);
      if(ObjectFind(0, name) < 0) {
         ObjectCreate(0, name, OBJ_ARROW, 0, time, hma);
         ObjectSetInteger(0, name, OBJPROP_ARROWCODE, 159);
         ObjectSetInteger(0, name, OBJPROP_COLOR, flatColor);
         ObjectSetInteger(0, name, OBJPROP_WIDTH, MathMin(5, MathMax(1, size)));
      }
   }
}

// Plot SHAP dashboard with bars
void PlotSHAPChart(int bar, datetime time, double &shapValues[], double hma) {
   string prefix = "AMTC_SHAP_";
   double basePrice = hma;
   double barWidth = PeriodSeconds() / 2;
   for(int i = 0; i < 4; i++) {
      string name = prefix + IntegerToString(bar) + "_" + IntegerToString(i);
      if(ObjectFind(0, name) < 0) {
         double height = shapValues[i] * 0.001;
         ObjectCreate(0, name, OBJ_RECTANGLE, 0, time - barWidth, basePrice + i * 0.002,
                      time + barWidth, basePrice + i * 0.002 + height);
         ObjectSetInteger(0, name, OBJPROP_COLOR, i == 0 ? clrGreen : (i == 1 ? clrBlue : (i == 2 ? clrMagenta : clrYellow)));
         ObjectSetInteger(0, name, OBJPROP_FILL, true);
      }
   }
}

#endif