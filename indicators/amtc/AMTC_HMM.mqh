//+------------------------------------------------------------------+
//|                      AMTC_HMM.mqh                                |
//+------------------------------------------------------------------+
#ifndef AMTC_HMM_MQH
#define AMTC_HMM_MQH

double currentRegime;

void InitHMM() {
   currentRegime = 0.5; // Neutral start
}

double GetCurrentRegime() {
   double volatility = iATR(_Symbol, _Period, 14, 0);
   double avgVol = iMA(NULL, 0, 50, 0, MODE_SMA, iATR(_Symbol, _Period, 14, 0), 0);
   currentRegime = volatility > avgVol ? 1.0 : 0.0; // Trending (1) or ranging (0)
   return currentRegime;
}

#endif