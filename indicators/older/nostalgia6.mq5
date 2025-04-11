#include <Trade\Trade.mqh>

CTrade trade;

// **Input Parameters**
// Enable/disable conditions (55 long conditions + 10 short conditions)
input bool long_entry_condition_1_enable = true;
input bool long_entry_condition_2_enable = true;
input bool long_entry_condition_3_enable = true;
input bool long_entry_condition_4_enable = true;
input bool long_entry_condition_5_enable = true;
input bool long_entry_condition_6_enable = true;
input bool long_entry_condition_7_enable = true;
input bool long_entry_condition_8_enable = true;
input bool long_entry_condition_9_enable = true;
input bool long_entry_condition_10_enable = true;
input bool long_entry_condition_11_enable = true;
input bool long_entry_condition_12_enable = true;
input bool long_entry_condition_13_enable = true;
input bool long_entry_condition_14_enable = true;
input bool long_entry_condition_15_enable = true;
input bool long_entry_condition_16_enable = true;
input bool long_entry_condition_17_enable = true;
input bool long_entry_condition_18_enable = true;
input bool long_entry_condition_19_enable = true;
input bool long_entry_condition_20_enable = true;
input bool long_entry_condition_21_enable = true;
input bool long_entry_condition_22_enable = true;
input bool long_entry_condition_23_enable = true;
input bool long_entry_condition_24_enable = true;
input bool long_entry_condition_25_enable = true;
input bool long_entry_condition_26_enable = true;
input bool long_entry_condition_27_enable = true;
input bool long_entry_condition_28_enable = true;
input bool long_entry_condition_29_enable = true;
input bool long_entry_condition_30_enable = true;
input bool long_entry_condition_31_enable = true;
input bool long_entry_condition_32_enable = true;
input bool long_entry_condition_33_enable = true;
input bool long_entry_condition_34_enable = true;
input bool long_entry_condition_35_enable = true;
input bool long_entry_condition_36_enable = true;
input bool long_entry_condition_37_enable = true;
input bool long_entry_condition_38_enable = true;
input bool long_entry_condition_39_enable = true;
input bool long_entry_condition_40_enable = true;
input bool long_entry_condition_41_enable = true;
input bool long_entry_condition_42_enable = true;
input bool long_entry_condition_43_enable = true;
input bool long_entry_condition_44_enable = true;
input bool long_entry_condition_45_enable = true;
input bool long_entry_condition_46_enable = true;
input bool long_entry_condition_47_enable = true;
input bool long_entry_condition_48_enable = true;
input bool long_entry_condition_49_enable = true;
input bool long_entry_condition_50_enable = true;
input bool long_entry_condition_51_enable = true;
input bool long_entry_condition_52_enable = true;
input bool long_entry_condition_53_enable = true;
input bool long_entry_condition_54_enable = true;
input bool long_entry_condition_55_enable = true;
input bool short_entry_condition_1_enable = true;
input bool short_entry_condition_2_enable = true;
input bool short_entry_condition_3_enable = true;
input bool short_entry_condition_4_enable = true;
input bool short_entry_condition_5_enable = true;
input bool short_entry_condition_6_enable = true;
input bool short_entry_condition_7_enable = true;
input bool short_entry_condition_8_enable = true;
input bool short_entry_condition_9_enable = true;
input bool short_entry_condition_10_enable = true;

// Trade management inputs
input double base_lot_size = 0.1;     // Base lot size (will be adjusted dynamically)
input double grinding_factor = 0.24;  // Lot size increment for grinding
input double derisk_loss = -0.24;     // Loss threshold for de-risking (account currency per lot)
input double profit_target = 0.05;    // Default profit target (5% price movement)
input double stop_loss = 0.05;        // Default stop loss (5% price movement)
input double risk_percent = 1.0;      // Risk percentage of equity per trade (e.g., 1%)

// **Indicator Parameters**
input int ema_fast_period = 12;       // Fast EMA period
input int ema_slow_period = 26;       // Slow EMA period
input int ema_200_period = 200;       // EMA 200 period
input int rsi_period = 14;            // RSI period
input int cci_period = 14;            // CCI period
input int sma_50_period = 50;         // SMA 50 period
input int sma_200_period = 200;       // SMA 200 period
input int ewo_fast_period = 5;        // EWO fast EMA
input int ewo_slow_period = 35;       // EWO slow EMA

// **Indicator Handles**
// (All indicator handles remain unchanged)
// 5-minute timeframe
int ema_fast_handle_5m, ema_slow_handle_5m, ema_200_handle_5m;
int rsi_handle_5m, cci_handle_5m, sma_50_handle_5m, sma_200_handle_5m;
int ewo_fast_handle_5m, ewo_slow_handle_5m;
// 15-minute timeframe
int ema_fast_handle_15m, ema_slow_handle_15m;
// 1-hour timeframe
int ema_fast_handle_1h, ema_slow_handle_1h;
// 4-hour timeframe
int ema_fast_handle_4h, ema_slow_handle_4h;
// Daily timeframe
int ema_fast_handle_1d, ema_slow_handle_1d;

// **Data Arrays**
double ema_fast_5m[], ema_slow_5m[], ema_200_5m[], rsi_5m[], cci_5m[], sma_50_5m[], sma_200_5m[];
double ewo_fast_5m[], ewo_slow_5m[];
double ema_fast_15m[], ema_slow_15m[];
double ema_fast_1h[], ema_slow_1h[];
double ema_fast_4h[], ema_slow_4h[];
double ema_fast_1d[], ema_slow_1d[];
MqlRates rates_5m[], rates_15m[], rates_1h[], rates_4h[], rates_1d[];
double pivot[], res1[], sup1[];

// **Initialization**
void OnInit()
{
   // 5-minute indicators
   ema_fast_handle_5m = iMA(NULL, PERIOD_M5, ema_fast_period, 0, MODE_EMA, PRICE_CLOSE);
   ema_slow_handle_5m = iMA(NULL, PERIOD_M5, ema_slow_period, 0, MODE_EMA, PRICE_CLOSE);
   ema_200_handle_5m = iMA(NULL, PERIOD_M5, ema_200_period, 0, MODE_EMA, PRICE_CLOSE);
   rsi_handle_5m = iRSI(NULL, PERIOD_M5, rsi_period, PRICE_CLOSE);
   cci_handle_5m = iCCI(NULL, PERIOD_M5, cci_period, PRICE_TYPICAL);
   sma_50_handle_5m = iMA(NULL, PERIOD_M5, sma_50_period, 0, MODE_SMA, PRICE_CLOSE);
   sma_200_handle_5m = iMA(NULL, PERIOD_M5, sma_200_period, 0, MODE_SMA, PRICE_CLOSE);
   ewo_fast_handle_5m = iMA(NULL, PERIOD_M5, ewo_fast_period, 0, MODE_EMA, PRICE_CLOSE);
   ewo_slow_handle_5m = iMA(NULL, PERIOD_M5, ewo_slow_period, 0, MODE_EMA, PRICE_CLOSE);

   // 15-minute indicators
   ema_fast_handle_15m = iMA(NULL, PERIOD_M15, ema_fast_period, 0, MODE_EMA, PRICE_CLOSE);
   ema_slow_handle_15m = iMA(NULL, PERIOD_M15, ema_slow_period, 0, MODE_EMA, PRICE_CLOSE);

   // 1-hour indicators
   ema_fast_handle_1h = iMA(NULL, PERIOD_H1, ema_fast_period, 0, MODE_EMA, PRICE_CLOSE);
   ema_slow_handle_1h = iMA(NULL, PERIOD_H1, ema_slow_period, 0, MODE_EMA, PRICE_CLOSE);

   // 4-hour indicators
   ema_fast_handle_4h = iMA(NULL, PERIOD_H4, ema_fast_period, 0, MODE_EMA, PRICE_CLOSE);
   ema_slow_handle_4h = iMA(NULL, PERIOD_H4, ema_slow_period, 0, MODE_EMA, PRICE_CLOSE);

   // Daily indicators
   ema_fast_handle_1d = iMA(NULL, PERIOD_D1, ema_fast_period, 0, MODE_EMA, PRICE_CLOSE);
   ema_slow_handle_1d = iMA(NULL, PERIOD_D1, ema_slow_period, 0, MODE_EMA, PRICE_CLOSE);

   // Resize all arrays and set as series
   ArraySetAsSeries(ema_fast_5m, true);
   ArraySetAsSeries(ema_slow_5m, true);
   ArraySetAsSeries(ema_200_5m, true);
   ArraySetAsSeries(rsi_5m, true);
   ArraySetAsSeries(cci_5m, true);
   ArraySetAsSeries(sma_50_5m, true);
   ArraySetAsSeries(sma_200_5m, true);
   ArraySetAsSeries(ewo_fast_5m, true);
   ArraySetAsSeries(ewo_slow_5m, true);
   ArraySetAsSeries(ema_fast_15m, true);
   ArraySetAsSeries(ema_slow_15m, true);
   ArraySetAsSeries(ema_fast_1h, true);
   ArraySetAsSeries(ema_slow_1h, true);
   ArraySetAsSeries(ema_fast_4h, true);
   ArraySetAsSeries(ema_slow_4h, true);
   ArraySetAsSeries(ema_fast_1d, true);
   ArraySetAsSeries(ema_slow_1d, true);
   ArraySetAsSeries(rates_5m, true);
   ArraySetAsSeries(rates_15m, true);
   ArraySetAsSeries(rates_1h, true);
   ArraySetAsSeries(rates_4h, true);
   ArraySetAsSeries(rates_1d, true);
   ArraySetAsSeries(pivot, true);
   ArraySetAsSeries(res1, true);
   ArraySetAsSeries(sup1, true);
}

// **Deinitialization**
void OnDeinit(const int reason)
{
   // No specific cleanup needed
}

// **New Function: Calculate Lot Size Based on Risk**
double CalculateLotSize(double price, double sl_distance)
{
   double account_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   // Calculate risk amount (e.g., 1% of equity)
   double risk_amount = account_equity * (risk_percent / 100.0);
   // Calculate pip value and risk in pips
   double pip_value = tick_value / tick_size;
   double risk_pips = sl_distance / tick_size;
   // Calculate lot size
   double lot_size = risk_amount / (risk_pips * pip_value);
   // Normalize lot size to allowed steps
   lot_size = MathFloor(lot_size / lot_step) * lot_step;
   lot_size = MathMax(min_lot, MathMin(max_lot, lot_size));

   return lot_size;
}

// **New Function: Check Margin Availability**
bool CheckMargin(double lot_size, double price, ENUM_ORDER_TYPE order_type)
{
   double margin_required;
   if (!OrderCalcMargin(order_type, _Symbol, lot_size, price, margin_required))
      return false;
   double free_margin = AccountInfoDouble(ACCOUNT_FREEMARGIN);
   return (free_margin > margin_required);
}

// **Custom Indicator Functions**
double CalculateEWO()
{
   double close[];
   ArraySetAsSeries(close, true);
   CopyClose(NULL, PERIOD_M5, 0, 3, close);
   double ewo = (ewo_fast_5m[0] - ewo_slow_5m[0]) / close[0] * 100.0;
   return ewo;
}

void CalculatePivotPoints()
{
   CopyRates(NULL, PERIOD_D1, 1, 1, rates_1d); // Previous day
   ArrayResize(pivot, 1); ArrayResize(res1, 1); ArrayResize(sup1, 1);
   pivot[0] = (rates_1d[0].high + rates_1d[0].low + rates_1d[0].close) / 3;
   double hl_range = rates_1d[0].high - rates_1d[0].low;
   res1[0] = pivot[0] + 0.382 * hl_range;
   sup1[0] = pivot[0] - 0.382 * hl_range;
}

// **Data Fetching**
void FetchMultiTimeframeData()
{
   CopyRates(NULL, PERIOD_M5, 0, 3, rates_5m);
   CopyRates(NULL, PERIOD_M15, 0, 3, rates_15m);
   CopyRates(NULL, PERIOD_H1, 0, 3, rates_1h);
   CopyRates(NULL, PERIOD_H4, 0, 3, rates_4h);
   CopyRates(NULL, PERIOD_D1, 0, 3, rates_1d);
}

void UpdateIndicators()
{
   CopyBuffer(ema_fast_handle_5m, 0, 0, 3, ema_fast_5m);
   CopyBuffer(ema_slow_handle_5m, 0, 0, 3, ema_slow_5m);
   CopyBuffer(ema_200_handle_5m, 0, 0, 3, ema_200_5m);
   CopyBuffer(rsi_handle_5m, 0, 0, 3, rsi_5m);
   CopyBuffer(cci_handle_5m, 0, 0, 3, cci_5m);
   CopyBuffer(sma_50_handle_5m, 0, 0, 3, sma_50_5m);
   CopyBuffer(sma_200_handle_5m, 0, 0, 3, sma_200_5m);
   CopyBuffer(ewo_fast_handle_5m, 0, 0, 3, ewo_fast_5m);
   CopyBuffer(ewo_slow_handle_5m, 0, 0, 3, ewo_slow_5m);
   CopyBuffer(ema_fast_handle_15m, 0, 0, 3, ema_fast_15m);
   CopyBuffer(ema_slow_handle_15m, 0, 0, 3, ema_slow_15m);
   CopyBuffer(ema_fast_handle_1h, 0, 0, 3, ema_fast_1h);
   CopyBuffer(ema_slow_handle_1h, 0, 0, 3, ema_slow_1h);
   CopyBuffer(ema_fast_handle_4h, 0, 0, 3, ema_fast_4h);
   CopyBuffer(ema_slow_handle_4h, 0, 0, 3, ema_slow_4h);
   CopyBuffer(ema_fast_handle_1d, 0, 0, 3, ema_fast_1d);
   CopyBuffer(ema_slow_handle_1d, 0, 0, 3, ema_slow_1d);
}

// **Buy Conditions (All 55 Conditions Defined)**
bool CheckLongEntryCondition1() { if (!long_entry_condition_1_enable) return false; return (ema_fast_5m[0] > ema_slow_5m[0] && rsi_5m[0] < 30 && cci_5m[0] < -100); }
bool CheckLongEntryCondition2() { if (!long_entry_condition_2_enable) return false; double ewo = CalculateEWO(); return (rates_5m[0].close > sma_200_5m[0] && ewo > 0 && ema_fast_15m[0] > ema_slow_15m[0]); }
bool CheckLongEntryCondition3() { if (!long_entry_condition_3_enable) return false; CalculatePivotPoints(); return (rates_5m[0].close > sup1[0] && ema_200_5m[0] < rates_5m[0].close && rsi_5m[0] > 50); }
bool CheckLongEntryCondition4() { if (!long_entry_condition_4_enable) return false; return (ema_fast_5m[0] > ema_slow_5m[0] && sma_50_5m[0] > sma_200_5m[0] && rates_5m[0].close > sma_50_5m[0]); }
bool CheckLongEntryCondition5() { if (!long_entry_condition_5_enable) return false; return (rsi_5m[0] < 30 && cci_5m[0] < -100 && rates_5m[0].close > ema_200_5m[0]); }
bool CheckLongEntryCondition6() { if (!long_entry_condition_6_enable) return false; return (ema_fast_15m[0] > ema_slow_15m[0] && ema_fast_1h[0] > ema_slow_1h[0] && rates_5m[0].close > ema_fast_5m[0]); }
bool CheckLongEntryCondition7() { if (!long_entry_condition_7_enable) return false; return (rates_5m[0].close > sma_200_5m[0] && rsi_5m[0] > 50 && cci_5m[0] > 100); }
bool CheckLongEntryCondition8() { if (!long_entry_condition_8_enable) return false; return (ema_fast_5m[0] > ema_slow_5m[0] && rates_5m[0].close > ema_200_5m[0] && rsi_5m[0] < 40); }
bool CheckLongEntryCondition9() { if (!long_entry_condition_9_enable) return false; return (sma_50_5m[0] > sma_200_5m[0] && rates_5m[0].close > sma_50_5m[0] && cci_5m[0] < -50); }
bool CheckLongEntryCondition10() { if (!long_entry_condition_10_enable) return false; return (ema_fast_1h[0] > ema_slow_1h[0] && rates_5m[0].close > ema_fast_5m[0] && rsi_5m[0] > 60); }
bool CheckLongEntryCondition11() { if (!long_entry_condition_11_enable) return false; return (ema_fast_4h[0] > ema_slow_4h[0] && rates_5m[0].close > sma_200_5m[0] && cci_5m[0] > 50); }
bool CheckLongEntryCondition12() { if (!long_entry_condition_12_enable) return false; double ewo = CalculateEWO(); return (ewo > 1.0 && ema_fast_5m[0] > ema_slow_5m[0] && rates_5m[0].close > ema_200_5m[0]); }
bool CheckLongEntryCondition13() { if (!long_entry_condition_13_enable) return false; return (rates_5m[0].close > sma_50_5m[0] && ema_fast_15m[0] > ema_slow_15m[0] && rsi_5m[0] < 35); }
bool CheckLongEntryCondition14() { if (!long_entry_condition_14_enable) return false; CalculatePivotPoints(); return (rates_5m[0].close > pivot[0] && ema_fast_1h[0] > ema_slow_1h[0] && cci_5m[0] < -75); }
bool CheckLongEntryCondition15() { if (!long_entry_condition_15_enable) return false; return (ema_fast_5m[0] > ema_slow_5m[0] && rates_5m[0].close > sma_200_5m[0] && rsi_5m[0] > 55); }
bool CheckLongEntryCondition16() { if (!long_entry_condition_16_enable) return false; return (sma_50_5m[0] > sma_200_5m[0] && ema_fast_1d[0] > ema_slow_1d[0] && cci_5m[0] > 0); }
bool CheckLongEntryCondition17() { if (!long_entry_condition_17_enable) return false; return (ema_fast_5m[0] > ema_slow_5m[0] && rsi_5m[0] < 25 && rates_5m[0].close > ema_200_5m[0]); }
bool CheckLongEntryCondition18() { if (!long_entry_condition_18_enable) return false; double ewo = CalculateEWO(); return (ewo > 0.5 && ema_fast_15m[0] > ema_slow_15m[0] && rates_5m[0].close > sma_50_5m[0]); }
bool CheckLongEntryCondition19() { if (!long_entry_condition_19_enable) return false; return (ema_fast_1h[0] > ema_slow_1h[0] && cci_5m[0] < -150 && rates_5m[0].close > sma_200_5m[0]); }
bool CheckLongEntryCondition20() { if (!long_entry_condition_20_enable) return false; CalculatePivotPoints(); return (rates_5m[0].close > sup1[0] && ema_fast_4h[0] > ema_slow_4h[0] && rsi_5m[0] > 45); }
bool CheckLongEntryCondition21() { if (!long_entry_condition_21_enable) return false; return (ema_fast_5m[0] > ema_slow_5m[0] && sma_50_5m[0] > sma_200_5m[0] && cci_5m[0] > 75); }
bool CheckLongEntryCondition22() { if (!long_entry_condition_22_enable) return false; return (rates_5m[0].close > ema_200_5m[0] && ema_fast_15m[0] > ema_slow_15m[0] && rsi_5m[0] < 30); }
bool CheckLongEntryCondition23() { if (!long_entry_condition_23_enable) return false; double ewo = CalculateEWO(); return (ewo > 2.0 && ema_fast_1h[0] > ema_slow_1h[0] && rates_5m[0].close > sma_50_5m[0]); }
bool CheckLongEntryCondition24() { if (!long_entry_condition_24_enable) return false; return (ema_fast_5m[0] > ema_slow_5m[0] && cci_5m[0] < -50 && rates_5m[0].close > ema_200_5m[0]); }
bool CheckLongEntryCondition25() { if (!long_entry_condition_25_enable) return false; return (sma_50_5m[0] > sma_200_5m[0] && ema_fast_4h[0] > ema_slow_4h[0] && rsi_5m[0] > 60); }
bool CheckLongEntryCondition26() { if (!long_entry_condition_26_enable) return false; CalculatePivotPoints(); return (rates_5m[0].close > pivot[0] && ema_fast_1d[0] > ema_slow_1d[0] && cci_5m[0] > 25); }
bool CheckLongEntryCondition27() { if (!long_entry_condition_27_enable) return false; return (ema_fast_5m[0] > ema_slow_5m[0] && rsi_5m[0] < 20 && rates_5m[0].close > sma_50_5m[0]); }
bool CheckLongEntryCondition28() { if (!long_entry_condition_28_enable) return false; double ewo = CalculateEWO(); return (ewo > 1.5 && ema_fast_15m[0] > ema_slow_15m[0] && rates_5m[0].close > ema_200_5m[0]); }
bool CheckLongEntryCondition29() { if (!long_entry_condition_29_enable) return false; return (ema_fast_1h[0] > ema_slow_1h[0] && cci_5m[0] < -100 && sma_50_5m[0] > sma_200_5m[0]); }
bool CheckLongEntryCondition30() { if (!long_entry_condition_30_enable) return false; return (rates_5m[0].close > ema_200_5m[0] && ema_fast_4h[0] > ema_slow_4h[0] && rsi_5m[0] > 50); }
bool CheckLongEntryCondition31() { if (!long_entry_condition_31_enable) return false; return (ema_fast_5m[0] > ema_slow_5m[0] && sma_50_5m[0] > sma_200_5m[0] && cci_5m[0] > 150); }
bool CheckLongEntryCondition32() { if (!long_entry_condition_32_enable) return false; CalculatePivotPoints(); return (rates_5m[0].close > sup1[0] && ema_fast_15m[0] > ema_slow_15m[0] && rsi_5m[0] < 35); }
bool CheckLongEntryCondition33() { if (!long_entry_condition_33_enable) return false; double ewo = CalculateEWO(); return (ewo > 0.8 && ema_fast_1h[0] > ema_slow_1h[0] && rates_5m[0].close > sma_200_5m[0]); }
bool CheckLongEntryCondition34() { if (!long_entry_condition_34_enable) return false; return (ema_fast_5m[0] > ema_slow_5m[0] && cci_5m[0] < -25 && rates_5m[0].close > ema_200_5m[0]); }
bool CheckLongEntryCondition35() { if (!long_entry_condition_35_enable) return false; return (sma_50_5m[0] > sma_200_5m[0] && ema_fast_1d[0] > ema_slow_1d[0] && rsi_5m[0] > 65); }
bool CheckLongEntryCondition36() { if (!long_entry_condition_36_enable) return false; return (ema_fast_4h[0] > ema_slow_4h[0] && rates_5m[0].close > sma_50_5m[0] && cci_5m[0] > 100); }
bool CheckLongEntryCondition37() { if (!long_entry_condition_37_enable) return false; return (ema_fast_5m[0] > ema_slow_5m[0] && rsi_5m[0] < 15 && rates_5m[0].close > ema_200_5m[0]); }
bool CheckLongEntryCondition38() { if (!long_entry_condition_38_enable) return false; double ewo = CalculateEWO(); return (ewo > 2.5 && ema_fast_15m[0] > ema_slow_15m[0] && rates_5m[0].close > sma_200_5m[0]); }
bool CheckLongEntryCondition39() { if (!long_entry_condition_39_enable) return false; CalculatePivotPoints(); return (rates_5m[0].close > pivot[0] && ema_fast_1h[0] > ema_slow_1h[0] && rsi_5m[0] > 40); }
bool CheckLongEntryCondition40() { if (!long_entry_condition_40_enable) return false; return (ema_fast_5m[0] > ema_slow_5m[0] && cci_5m[0] < -200 && sma_50_5m[0] > sma_200_5m[0]); }
bool CheckLongEntryCondition41() { if (!long_entry_condition_41_enable) return false; return (rates_5m[0].close > ema_200_5m[0] && ema_fast_4h[0] > ema_slow_4h[0] && rsi_5m[0] > 55); }
bool CheckLongEntryCondition42() { if (!long_entry_condition_42_enable) return false; return (ema_fast_1d[0] > ema_slow_1d[0] && sma_50_5m[0] > sma_200_5m[0] && cci_5m[0] > 50); }
bool CheckLongEntryCondition43() { if (!long_entry_condition_43_enable) return false; double ewo = CalculateEWO(); return (ewo > 1.2 && ema_fast_5m[0] > ema_slow_5m[0] && rates_5m[0].close > sma_50_5m[0]); }
bool CheckLongEntryCondition44() { if (!long_entry_condition_44_enable) return false; CalculatePivotPoints(); return (rates_5m[0].close > sup1[0] && ema_fast_15m[0] > ema_slow_15m[0] && rsi_5m[0] < 25); }
bool CheckLongEntryCondition45() { if (!long_entry_condition_45_enable) return false; return (ema_fast_1h[0] > ema_slow_1h[0] && cci_5m[0] < -75 && rates_5m[0].close > ema_200_5m[0]); }
bool CheckLongEntryCondition46() { if (!long_entry_condition_46_enable) return false; return (ema_fast_5m[0] > ema_slow_5m[0] && sma_50_5m[0] > sma_200_5m[0] && rsi_5m[0] > 70); }
bool CheckLongEntryCondition47() { if (!long_entry_condition_47_enable) return false; return (rates_5m[0].close > sma_200_5m[0] && ema_fast_4h[0] > ema_slow_4h[0] && cci_5m[0] > 125); }
bool CheckLongEntryCondition48() { if (!long_entry_condition_48_enable) return false; double ewo = CalculateEWO(); return (ewo > 0.3 && ema_fast_1d[0] > ema_slow_1d[0] && rates_5m[0].close > sma_50_5m[0]); }
bool CheckLongEntryCondition49() { if (!long_entry_condition_49_enable) return false; return (ema_fast_5m[0] > ema_slow_5m[0] && rsi_5m[0] < 10 && rates_5m[0].close > ema_200_5m[0]); }
bool CheckLongEntryCondition50() { if (!long_entry_condition_50_enable) return false; CalculatePivotPoints(); return (rates_5m[0].close > pivot[0] && ema_fast_15m[0] > ema_slow_15m[0] && cci_5m[0] > 75); }
bool CheckLongEntryCondition51() { if (!long_entry_condition_51_enable) return false; return (ema_fast_1h[0] > ema_slow_1h[0] && sma_50_5m[0] > sma_200_5m[0] && rsi_5m[0] > 45); }
bool CheckLongEntryCondition52() { if (!long_entry_condition_52_enable) return false; return (rates_5m[0].close > ema_200_5m[0] && ema_fast_4h[0] > ema_slow_4h[0] && cci_5m[0] < -25); }
bool CheckLongEntryCondition53() { if (!long_entry_condition_53_enable) return false; double ewo = CalculateEWO(); return (ewo > 1.8 && ema_fast_5m[0] > ema_slow_5m[0] && rates_5m[0].close > sma_200_5m[0]); }
bool CheckLongEntryCondition54() { if (!long_entry_condition_54_enable) return false; return (ema_fast_1d[0] > ema_slow_1d[0] && sma_50_5m[0] > sma_200_5m[0] && rsi_5m[0] > 60); }
bool CheckLongEntryCondition55() { if (!long_entry_condition_55_enable) return false; CalculatePivotPoints(); return (rates_5m[0].close > sup1[0] && ema_fast_15m[0] > ema_slow_15m[0] && cci_5m[0] > 100); }

// **Short Conditions (All 10 Conditions Defined)**
bool CheckShortEntryCondition1() { if (!short_entry_condition_1_enable) return false; return (ema_fast_5m[0] < ema_slow_5m[0] && rsi_5m[0] > 70 && cci_5m[0] > 100); }
bool CheckShortEntryCondition2() { if (!short_entry_condition_2_enable) return false; double ewo = CalculateEWO(); return (rates_5m[0].close < sma_200_5m[0] && ewo < 0 && ema_fast_15m[0] < ema_slow_15m[0]); }
bool CheckShortEntryCondition3() { if (!short_entry_condition_3_enable) return false; CalculatePivotPoints(); return (rates_5m[0].close < res1[0] && ema_200_5m[0] > rates_5m[0].close && rsi_5m[0] < 50); }
bool CheckShortEntryCondition4() { if (!short_entry_condition_4_enable) return false; return (ema_fast_5m[0] < ema_slow_5m[0] && sma_50_5m[0] < sma_200_5m[0] && rates_5m[0].close < sma_50_5m[0]); }
bool CheckShortEntryCondition5() { if (!short_entry_condition_5_enable) return false; return (rsi_5m[0] > 70 && cci_5m[0] > 100 && rates_5m[0].close < ema_200_5m[0]); }
bool CheckShortEntryCondition6() { if (!short_entry_condition_6_enable) return false; return (ema_fast_15m[0] < ema_slow_15m[0] && ema_fast_1h[0] < ema_slow_1h[0] && rates_5m[0].close < ema_fast_5m[0]); }
bool CheckShortEntryCondition7() { if (!short_entry_condition_7_enable) return false; return (rates_5m[0].close < sma_200_5m[0] && rsi_5m[0] < 30 && cci_5m[0] < -100); }
bool CheckShortEntryCondition8() { if (!short_entry_condition_8_enable) return false; double ewo = CalculateEWO(); return (ewo < -1.0 && ema_fast_4h[0] < ema_slow_4h[0] && rates_5m[0].close < sma_50_5m[0]); }
bool CheckShortEntryCondition9() { if (!short_entry_condition_9_enable) return false; return (ema_fast_5m[0] < ema_slow_5m[0] && cci_5m[0] > 150 && rates_5m[0].close < ema_200_5m[0]); }
bool CheckShortEntryCondition10() { if (!short_entry_condition_10_enable) return false; CalculatePivotPoints(); return (rates_5m[0].close < res1[0] && ema_fast_1d[0] < ema_slow_1d[0] && rsi_5m[0] < 40); }

// **Trade Management**
void CheckSellConditions()
{
   for (int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if (PositionSelectByTicket(ticket))
      {
         double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
         double current_price = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 
                                SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                                SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double profit_ratio = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 
                               (current_price - open_price) / open_price : 
                               (open_price - current_price) / open_price;
         if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
         {
            if (profit_ratio >= profit_target || rsi_5m[0] > 70)
            {
               trade.PositionClose(ticket);
            }
         }
         else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
         {
            if (profit_ratio >= profit_target || rsi_5m[0] < 30)
            {
               trade.PositionClose(ticket);
            }
         }
      }
   }
}

void GrindingLogic()
{
   if (PositionsTotal() > 0)
   {
      ulong ticket = PositionGetTicket(0);
      if (PositionSelectByTicket(ticket))
      {
         double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
         double volume = PositionGetDouble(POSITION_VOLUME);
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double sl_price, tp_price;

         if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
         {
            double loss_ratio = (bid - open_price) / open_price;
            if (loss_ratio < -0.12)
            {
               double new_lot = volume + grinding_factor;
               sl_price = ask * (1 - stop_loss);
               tp_price = ask * (1 + profit_target);
               if (CheckMargin(new_lot, ask, ORDER_TYPE_BUY))
               {
                  trade.Buy(new_lot, NULL, ask, sl_price, tp_price);
               }
            }
         }
         else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
         {
            double loss_ratio = (open_price - ask) / open_price;
            if (loss_ratio < -0.12)
            {
               double new_lot = volume + grinding_factor;
               sl_price = bid * (1 + stop_loss);
               tp_price = bid * (1 - profit_target);
               if (CheckMargin(new_lot, bid, ORDER_TYPE_SELL))
               {
                  trade.Sell(new_lot, NULL, bid, sl_price, tp_price);
               }
            }
         }
      }
   }
}

void DeRiskingLogic()
{
   for (int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if (PositionSelectByTicket(ticket))
      {
         double profit = PositionGetDouble(POSITION_PROFIT);
         double volume = PositionGetDouble(POSITION_VOLUME);
         double loss_threshold = derisk_loss * volume;
         if (profit < loss_threshold)
         {
            trade.PositionClose(ticket);
         }
      }
   }
}

bool HoldTradeLogic()
{
   CalculatePivotPoints();
   if (PositionsTotal() > 0)
   {
      ulong ticket = PositionGetTicket(0);
      if (PositionSelectByTicket(ticket))
      {
         if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
         {
            return (rates_5m[0].close > pivot[0] && ema_fast_1h[0] > ema_slow_1h[0]);
         }
         else
         {
            return (rates_5m[0].close < pivot[0] && ema_fast_1h[0] < ema_slow_1h[0]);
         }
      }
   }
   return false;
}

// **Main Logic**
void OnTick()
{
   FetchMultiTimeframeData();
   UpdateIndicators();
   
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl_distance = stop_loss * ask; // Approximate SL distance in price units
   double lot_size = CalculateLotSize(ask, sl_distance);

   // Check long and short entries
   if (PositionsTotal() == 0)
   {
      // Long entries
      if (CheckLongEntryCondition1() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 1");
      else if (CheckLongEntryCondition2() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 2");
      else if (CheckLongEntryCondition3() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 3");
      else if (CheckLongEntryCondition4() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 4");
      else if (CheckLongEntryCondition5() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 5");
      else if (CheckLongEntryCondition6() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 6");
      else if (CheckLongEntryCondition7() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 7");
      else if (CheckLongEntryCondition8() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 8");
      else if (CheckLongEntryCondition9() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 9");
      else if (CheckLongEntryCondition10() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 10");
      else if (CheckLongEntryCondition11() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 11");
      else if (CheckLongEntryCondition12() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 12");
      else if (CheckLongEntryCondition13() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 13");
      else if (CheckLongEntryCondition14() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 14");
      else if (CheckLongEntryCondition15() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 15");
      else if (CheckLongEntryCondition16() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 16");
      else if (CheckLongEntryCondition17() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 17");
      else if (CheckLongEntryCondition18() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 18");
      else if (CheckLongEntryCondition19() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 19");
      else if (CheckLongEntryCondition20() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 20");
      else if (CheckLongEntryCondition21() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 21");
      else if (CheckLongEntryCondition22() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 22");
      else if (CheckLongEntryCondition23() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 23");
      else if (CheckLongEntryCondition24() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 24");
      else if (CheckLongEntryCondition25() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 25");
      else if (CheckLongEntryCondition26() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 26");
      else if (CheckLongEntryCondition27() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 27");
      else if (CheckLongEntryCondition28() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 28");
      else if (CheckLongEntryCondition29() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 29");
      else if (CheckLongEntryCondition30() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 30");
      else if (CheckLongEntryCondition31() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 31");
      else if (CheckLongEntryCondition32() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 32");
      else if (CheckLongEntryCondition33() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 33");
      else if (CheckLongEntryCondition34() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 34");
      else if (CheckLongEntryCondition35() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 35");
      else if (CheckLongEntryCondition36() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 36");
      else if (CheckLongEntryCondition37() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 37");
      else if (CheckLongEntryCondition38() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 38");
      else if (CheckLongEntryCondition39() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 39");
      else if (CheckLongEntryCondition40() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 40");
      else if (CheckLongEntryCondition41() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 41");
      else if (CheckLongEntryCondition42() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 42");
      else if (CheckLongEntryCondition43() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 43");
      else if (CheckLongEntryCondition44() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 44");
      else if (CheckLongEntryCondition45() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 45");
      else if (CheckLongEntryCondition46() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 46");
      else if (CheckLongEntryCondition47() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 47");
      else if (CheckLongEntryCondition48() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 48");
      else if (CheckLongEntryCondition49() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 49");
      else if (CheckLongEntryCondition50() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 50");
      else if (CheckLongEntryCondition51() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 51");
      else if (CheckLongEntryCondition52() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 52");
      else if (CheckLongEntryCondition53() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 53");
      else if (CheckLongEntryCondition54() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 54");
      else if (CheckLongEntryCondition55() && CheckMargin(lot_size, ask, ORDER_TYPE_BUY))
         trade.Buy(lot_size, NULL, ask, ask * (1 - stop_loss), ask * (1 + profit_target), "Long Entry 55");
      // Short entries
      else if (CheckShortEntryCondition1() && CheckMargin(lot_size, bid, ORDER_TYPE_SELL))
         trade.Sell(lot_size, NULL, bid, bid * (1 + stop_loss), bid * (1 - profit_target), "Short Entry 1");
      else if (CheckShortEntryCondition2() && CheckMargin(lot_size, bid, ORDER_TYPE_SELL))
         trade.Sell(lot_size, NULL, bid, bid * (1 + stop_loss), bid * (1 - profit_target), "Short Entry 2");
      else if (CheckShortEntryCondition3() && CheckMargin(lot_size, bid, ORDER_TYPE_SELL))
         trade.Sell(lot_size, NULL, bid, bid * (1 + stop_loss), bid * (1 - profit_target), "Short Entry 3");
      else if (CheckShortEntryCondition4() && CheckMargin(lot_size, bid, ORDER_TYPE_SELL))
         trade.Sell(lot_size, NULL, bid, bid * (1 + stop_loss), bid * (1 - profit_target), "Short Entry 4");
      else if (CheckShortEntryCondition5() && CheckMargin(lot_size, bid, ORDER_TYPE_SELL))
         trade.Sell(lot_size, NULL, bid, bid * (1 + stop_loss), bid * (1 - profit_target), "Short Entry 5");
      else if (CheckShortEntryCondition6() && CheckMargin(lot_size, bid, ORDER_TYPE_SELL))
         trade.Sell(lot_size, NULL, bid, bid * (1 + stop_loss), bid * (1 - profit_target), "Short Entry 6");
      else if (CheckShortEntryCondition7() && CheckMargin(lot_size, bid, ORDER_TYPE_SELL))
         trade.Sell(lot_size, NULL, bid, bid * (1 + stop_loss), bid * (1 - profit_target), "Short Entry 7");
      else if (CheckShortEntryCondition8() && CheckMargin(lot_size, bid, ORDER_TYPE_SELL))
         trade.Sell(lot_size, NULL, bid, bid * (1 + stop_loss), bid * (1 - profit_target), "Short Entry 8");
      else if (CheckShortEntryCondition9() && CheckMargin(lot_size, bid, ORDER_TYPE_SELL))
         trade.Sell(lot_size, NULL, bid, bid * (1 + stop_loss), bid * (1 - profit_target), "Short Entry 9");
      else if (CheckShortEntryCondition10() && CheckMargin(lot_size, bid, ORDER_TYPE_SELL))
         trade.Sell(lot_size, NULL, bid, bid * (1 + stop_loss), bid * (1 - profit_target), "Short Entry 10");
   }

   // Manage open trades
   if (HoldTradeLogic())
   {
      // Hold trade; do nothing
   }
   else
   {
      CheckSellConditions();
   }
   GrindingLogic();
   DeRiskingLogic();
}