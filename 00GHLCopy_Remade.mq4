//+------------------------------------------------------------------+
//|                                                   00GHLCopy_Remade.mq4 |
//|                                    Russ Horn GHL Strategy Recreation |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Recreated from Russ Horn GHL Strategy"
#property link      "http://www.forexstrategymaster.com"
#property version   "1.00"
#property strict

//--- Input Parameters
input string    Section1 = "=== Moving Average Settings ===";
input int       MA_Fast_Period = 3;
input int       MA_Fast_Method = MODE_SMA;
input int       MA_Fast_Shift = 0;

input int       MA_Medium_Period = 5;
input int       MA_Medium_Method = MODE_SMA;
input int       MA_Medium_Shift = 0;

input int       MA_Slow_Period = 15;
input int       MA_Slow_Method = MODE_SMA;
input int       MA_Slow_Shift = 0;

input int       MA_VerySlow_Period = 25;
input int       MA_VerySlow_Method = MODE_SMA;
input int       MA_VerySlow_Shift = 0;

input string    Section2 = "=== RSI Settings ===";
input int       RSI_Period = 14;
input int       RSI_Level_Buy = -55;
input int       RSI_Level_Sell = -45;

input string    Section3 = "=== Trade Management ===";
input double    LotSize = 0.1;
input int       StopLoss = 100;
input int       TakeProfit = 200;
input int       MagicNumber = 123456;
input int       MaxSlippage = 3;

input string    Section4 = "=== Filter Settings ===";
input bool      UseGHL_Filter = true;
input bool      UseQTI_Filter = true;
input bool      UseRSI_Filter = true;

//--- Global Variables
double g_point;
int g_digits;

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
   // Normalize point value for 5-digit brokers
   g_digits = (int)MarketInfo(Symbol(), MODE_DIGITS);
   if(g_digits == 3 || g_digits == 5)
      g_point = Point * 10;
   else
      g_point = Point;

   Print("GHL EA Initialized. Symbol: ", Symbol(), " Timeframe: ", Period());

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("GHL EA Deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                               |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check for open orders
   if(OrdersTotal() > 0)
   {
      // Manage existing positions
      ManagePositions();
      return;
   }

   // Check for new trade signals
   CheckEntrySignals();
}

//+------------------------------------------------------------------+
//| Check for entry signals                                            |
//+------------------------------------------------------------------+
void CheckEntrySignals()
{
   // Get indicator values
   double ma_fast = iMA(Symbol(), PERIOD_CURRENT, MA_Fast_Period, MA_Fast_Shift, MA_Fast_Method, PRICE_CLOSE, 1);
   double ma_medium = iMA(Symbol(), PERIOD_CURRENT, MA_Medium_Period, MA_Medium_Shift, MA_Medium_Method, PRICE_CLOSE, 1);
   double ma_slow = iMA(Symbol(), PERIOD_CURRENT, MA_Slow_Period, MA_Slow_Shift, MA_Slow_Method, PRICE_CLOSE, 1);
   double ma_veryslow = iMA(Symbol(), PERIOD_CURRENT, MA_VerySlow_Period, MA_VerySlow_Shift, MA_VerySlow_Method, PRICE_CLOSE, 1);

   double rsi = iRSI(Symbol(), PERIOD_CURRENT, RSI_Period, PRICE_CLOSE, 1);

   // Calculate GHL and QTI signals (simplified - you can replace with actual indicator calls)
   bool ghl_buy = GetGHLSignal(1);  // true = lime (buy), false = red (sell)
   bool ghl_sell = !ghl_buy;

   bool qti_buy = GetQTISignal(1);  // true = lime (buy), false = red (sell)
   bool qti_sell = !qti_buy;

   // BUY SIGNAL CHECK
   bool ma_buy = (ma_fast > ma_medium && ma_medium > ma_slow && ma_slow > ma_veryslow);
   bool rsi_buy = (rsi > RSI_Level_Buy);

   bool buy_signal = ma_buy;
   if(UseGHL_Filter) buy_signal = buy_signal && ghl_buy;
   if(UseQTI_Filter) buy_signal = buy_signal && qti_buy;
   if(UseRSI_Filter) buy_signal = buy_signal && rsi_buy;

   if(buy_signal)
   {
      Print("BUY Signal detected");
      OpenOrder(OP_BUY);
      return;
   }

   // SELL SIGNAL CHECK
   bool ma_sell = (ma_fast < ma_medium && ma_medium < ma_slow && ma_slow < ma_veryslow);
   bool rsi_sell = (rsi < RSI_Level_Sell);

   bool sell_signal = ma_sell;
   if(UseGHL_Filter) sell_signal = sell_signal && ghl_sell;
   if(UseQTI_Filter) sell_signal = sell_signal && qti_sell;
   if(UseRSI_Filter) sell_signal = sell_signal && rsi_sell;

   if(sell_signal)
   {
      Print("SELL Signal detected");
      OpenOrder(OP_SELL);
      return;
   }
}

//+------------------------------------------------------------------+
//| Open a new order                                                  |
//+------------------------------------------------------------------+
void OpenOrder(int order_type)
{
   double price, sl, tp;
   double lot = LotSize;

   // Normalize lot size
   lot = NormalizeDouble(lot, 2);
   double min_lot = MarketInfo(Symbol(), MODE_MINLOT);
   double max_lot = MarketInfo(Symbol(), MODE_MAXLOT);
   if(lot < min_lot) lot = min_lot;
   if(lot > max_lot) lot = max_lot;

   // Calculate price, SL, TP
   if(order_type == OP_BUY)
   {
      price = NormalizeDouble(Ask, g_digits);
      sl = NormalizeDouble(price - StopLoss * g_point, g_digits);
      tp = NormalizeDouble(price + TakeProfit * g_point, g_digits);
   }
   else
   {
      price = NormalizeDouble(Bid, g_digits);
      sl = NormalizeDouble(price + StopLoss * g_point, g_digits);
      tp = NormalizeDouble(price - TakeProfit * g_point, g_digits);
   }

   // Send order
   int ticket = OrderSend(Symbol(), order_type, lot, price, MaxSlippage, sl, tp, "GHL EA", MagicNumber, 0, clrNONE);

   if(ticket < 0)
   {
      int error = GetLastError();
      Print("Order failed. Error: ", error, " - ", ErrorDescription(error));
   }
   else
   {
      Print("Order opened successfully. Ticket: ", ticket);
   }
}

//+------------------------------------------------------------------+
//| Manage existing positions                                         |
//+------------------------------------------------------------------+
void ManagePositions()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            // Add any position management logic here
            // For example: trailing stop, break even, etc.
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Get GHL signal (placeholder - replace with actual indicator)     |
//+------------------------------------------------------------------+
bool GetGHLSignal(int shift)
{
   // This is a placeholder. You need to:
   // 1. Install the GHL indicator on your MT4
   // 2. Use iCustom() to read the indicator values
   // Example:
   // double ghl_value = iCustom(Symbol(), PERIOD_CURRENT, "GHL_Indicator_Name", 0, shift);
   // return (ghl_value > 0); // Adjust based on your indicator's output

   // For now, return true as placeholder
   return true;
}

//+------------------------------------------------------------------+
//| Get QTI signal (placeholder - replace with actual indicator)     |
//+------------------------------------------------------------------+
bool GetQTISignal(int shift)
{
   // This is a placeholder. You need to:
   // 1. Install the QTI indicator on your MT4
   // 2. Use iCustom() to read the indicator values
   // Example:
   // double qti_value = iCustom(Symbol(), PERIOD_CURRENT, "QTI_Indicator_Name", 0, shift);
   // return (qti_value > 0); // Adjust based on your indicator's output

   // For now, return true as placeholder
   return true;
}

//+------------------------------------------------------------------+
//| Get error description                                             |
//+------------------------------------------------------------------+
string ErrorDescription(int error)
{
   switch(error)
   {
      case 0:   return "No error";
      case 1:   return "No error (but result unknown)";
      case 2:   return "Common error";
      case 3:   return "Invalid trade parameters";
      case 4:   return "Trade server busy";
      case 5:   return "Old version of terminal";
      case 6:   return "No connection";
      case 7:   return "Not enough rights";
      case 8:   return "Too frequent requests";
      case 9:   return "Malfunctional operation";
      case 64:  return "Account disabled";
      case 65:  return "Invalid account";
      case 128: return "Trade timeout";
      case 129: return "Invalid price";
      case 130: return "Invalid stops";
      case 131: return "Invalid volume";
      case 132: return "Market closed";
      case 133: return "Trade disabled";
      case 134: return "Not enough money";
      case 135: return "Price changed";
      case 136: return "No prices";
      case 137: return "Broker busy";
      case 138: return "Requotes";
      case 139: return "Order locked";
      case 140: return "Long positions only allowed";
      case 141: return "Too many requests";
      case 145: return "Modification denied";
      case 146: return "Trade context busy";
      case 147: return "Expirations denied";
      case 148: return "Too many orders";
      case 149: return "Hedge prohibited";
      case 150: return "Prohibited by FIFO rule";
      default:  return "Unknown error";
   }
}
//+------------------------------------------------------------------+
