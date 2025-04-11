//+------------------------------------------------------------------+
//|                      DRATS_Wavelet.mqh                           |
//| Copyright 2025, jechaviz                                         |
//| jechaviz@gmail.com                                               |
//+------------------------------------------------------------------+
#ifndef DRATS_WAVELET_MQH
#define DRATS_WAVELET_MQH

// Persistent state variables
static double ema_short  = 0.0;  // EMA for short scale
static double ema_medium = 0.0;  // EMA for medium scale
static double ema_long   = 0.0;  // EMA for long scale
static double atr_avg    = 0.0;  // EMA of ATR for volatility adjustment
static bool   initialized = false;

//+------------------------------------------------------------------+
//| Initialize wavelet decomposition state                          |
//+------------------------------------------------------------------+
void InitWavelet() {
   ema_short = 0.0;
   ema_medium = 0.0;
   ema_long = 0.0;
   atr_avg = 0.0;
   initialized = false;
}

//+------------------------------------------------------------------+
//| Perform volatility-modulated fractal decomposition              |
//| Inputs:                                                         |
//|   close[]      - Price series (close prices)                    |
//|   bar          - Current bar index                              |
//|   atr          - Current ATR value                              |
//|   baseWindow   - Base window size for EMA periods               |
//|   gamma        - Volatility sensitivity factor                  |
//| Outputs:                                                        |
//|   shortScale   - Short-term trend signal                        |
//|   mediumScale  - Medium-term trend signal                       |
//|   longScale    - Long-term trend signal                         |
//+------------------------------------------------------------------+
void DecomposeWavelet(const double &close[], int bar, double atr, double baseWindow, double gamma, 
                      double &shortScale, double &mediumScale, double &longScale) {
   if (bar == 0) {
      // Initialize at first bar
      ema_short = close[0];
      ema_medium = close[0];
      ema_long = close[0];
      atr_avg = atr;
      initialized = true;
   } else if (!initialized) {
      // Fallback initialization if not properly initialized
      ema_short = close[bar];
      ema_medium = close[bar];
      ema_long = close[bar];
      atr_avg = atr;
      initialized = true;
   } else {
      // Update ATR average (EMA with period 50)
      double alpha_atr = 2.0 / (50 + 1);
      atr_avg = alpha_atr * atr + (1 - alpha_atr) * atr_avg;
      if (atr_avg == 0) atr_avg = atr; // Prevent division by zero

      // Compute volatility adjustment factor
      double volAdj = 1 + gamma * (atr / atr_avg - 1);

      // Calculate adaptive EMA periods
      double p1 = baseWindow * volAdj;       // Short scale
      double p2 = p1 * 2;                    // Medium scale
      double p3 = p1 * 4;                    // Long scale

      // Compute EMA smoothing factors
      double alpha1 = 2.0 / (p1 + 1);
      double alpha2 = 2.0 / (p2 + 1);
      double alpha3 = 2.0 / (p3 + 1);

      // Update EMAs
      ema_short  = alpha1 * close[bar] + (1 - alpha1) * ema_short;
      ema_medium = alpha2 * close[bar] + (1 - alpha2) * ema_medium;
      ema_long   = alpha3 * close[bar] + (1 - alpha3) * ema_long;
   }

   // Output the decomposed signals
   shortScale  = ema_short;
   mediumScale = ema_medium;
   longScale   = ema_long;
}

#endif