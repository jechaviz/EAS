//+------------------------------------------------------------------+
//|                      AMTC_UKF.mqh                                |
//+------------------------------------------------------------------+
#ifndef AMTC_UKF_MQH
#define AMTC_UKF_MQH

double state;

void InitUKF() {
   state = 0.0;
}

double UKFUpdate(double observedSlope) {
   // Simplified UKF: exponential smoothing as a proxy
   state = 0.9 * state + 0.1 * observedSlope;
   return state;
}

#endif