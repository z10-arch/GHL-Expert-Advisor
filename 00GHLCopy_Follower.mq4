//+------------------------------------------------------------------+
//|                                              00GHLCopy_Follower.mq4 |
//|                        Trade Copier/Monitor for 00GHLCopy EA      |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Trade Follower Script"
#property link      ""
#property version   "1.00"
#property strict
#property script_show_inputs

//--- Input Parameters
input string    Section1 = "=== Trade Copying Settings ===";
input bool       CopyTrades = true;           // Enable trade copying
input bool       CloseOnOriginalClose = true; // Close when original closes
input double     CopyLotMultiplier = 1.0;    // Lot size multiplier (1.0 = same lot)
input int        Slippage = 3;                // Max slippage
input int        MagicNumber = 54321;         // Magic number for copied trades

input string    Section2 = "=== Logging Settings ===";
input bool       EnableLogging = true;        // Enable detailed logging
input bool       LogToFile = true;            // Save logs to file
input string     LogFileName = "GHL_Follower.log"; // Log file name

input string    Section3 = "=== Filter Settings ===";
input string     FollowSymbol = "";            // Symbol to follow (empty = all)
input bool       FollowOnlyNewTrades = false;  // Only copy trades opened after script start

input string    Section4 = "=== Notifications ===";
input bool       EnableAlerts = true;          // Show popup alerts
input bool       EnableEmail = false;          // Send email notifications
input bool       EnablePush = false;           // Send push notifications

//--- Global Variables
datetime g_scriptStartTime;
int g_originalMagicNumber = 123456;  // Default magic number of original EA
string g_logFilePath;

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   g_scriptStartTime = TimeCurrent();
   g_logFilePath = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL4\\Files\\" + LogFileName;

   Log("========================================");
   Log("GHL Follower Script Started");
   Log("========================================");
   Log("Start Time: " + TimeToString(g_scriptStartTime, TIME_DATE|TIME_SECONDS));
   Log("Copy Trades: " + BooleanToString(CopyTrades));
   Log("Lot Multiplier: " + DoubleToString(CopyLotMultiplier, 2));
   Log("Magic Number: " + IntegerToString(MagicNumber));
   Log("========================================");

   if(CopyTrades)
   {
      // Check for existing trades from original EA
      ScanExistingTrades();

      // Monitor for new trades
      while(!IsStopped())
      {
         MonitorTrades();
         Sleep(1000);  // Check every second
      }
   }
   else
   {
      // Just log current state and exit
      LogCurrentState();
   }

   Log("GHL Follower Script Stopped");
   Log("========================================");
}

//+------------------------------------------------------------------+
//| Scan for existing trades from original EA                        |
//+------------------------------------------------------------------+
void ScanExistingTrades()
{
   Log("Scanning for existing trades from original EA...");

   int total = OrdersTotal();
   int found = 0;

   for(int i = 0; i < total; i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderMagicNumber() == g_originalMagicNumber)
         {
            found++;
            Log("Found existing trade: " + OrderTypeToString(OrderType()) +
                " " + OrderSymbol() + " Lot: " + DoubleToString(OrderLots(), 2) +
                " Price: " + DoubleToString(OrderOpenPrice(), Digits) +
                " SL: " + DoubleToString(OrderStopLoss(), Digits) +
                " TP: " + DoubleToString(OrderTakeProfit(), Digits));

            if(!FollowOnlyNewTrades)
            {
               // Copy existing trade
               CopyTrade(OrderTicket());
            }
         }
      }
   }

   Log("Total existing trades found: " + IntegerToString(found));
}

//+------------------------------------------------------------------+
//| Monitor for new trades from original EA                          |
//+------------------------------------------------------------------+
void MonitorTrades()
{
   static int lastOrderCount = 0;
   static int lastOrders[1000];
   static int lastOrderIndex = 0;

   int currentOrderCount = OrdersTotal();

   // Check for new orders
   if(currentOrderCount != lastOrderCount)
   {
      Log("Order count changed: " + IntegerToString(lastOrderCount) + " -> " + IntegerToString(currentOrderCount));

      for(int i = 0; i < currentOrderCount; i++)
      {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            int ticket = OrderTicket();
            bool isNew = true;

            // Check if this is a new order
            for(int j = 0; j < lastOrderIndex; j++)
            {
               if(lastOrders[j] == ticket)
               {
                  isNew = false;
                  break;
               }
            }

            if(isNew && OrderMagicNumber() == g_originalMagicNumber)
            {
               // New trade detected
               Log("NEW TRADE DETECTED: " + OrderTypeToString(OrderType()) +
                   " " + OrderSymbol() + " Lot: " + DoubleToString(OrderLots(), 2) +
                   " Price: " + DoubleToString(OrderOpenPrice(), Digits) +
                   " Ticket: " + IntegerToString(ticket));

               // Copy the trade
               if(CopyTrades)
               {
                  CopyTrade(ticket);
               }

               // Send notification
               SendNotification("New Trade: " + OrderSymbol() + " " + OrderTypeToString(OrderType()));

               // Add to tracking array
               if(lastOrderIndex < 1000)
               {
                  lastOrders[lastOrderIndex] = ticket;
                  lastOrderIndex++;
               }
            }
         }
      }

      lastOrderCount = currentOrderCount;
   }

   // Check for closed trades
   CheckClosedTrades(lastOrders, lastOrderIndex);
}

//+------------------------------------------------------------------+
//| Check for closed trades and close our copies                      |
//+------------------------------------------------------------------+
void CheckClosedTrades(int &orders[], int &orderIndex)
{
   for(int i = orderIndex - 1; i >= 0; i--)
   {
      int ticket = orders[i];
      bool stillOpen = false;

      // Check if original trade is still open
   for(int j = 0; j < OrdersTotal(); j++)
      {
         if(OrderSelect(j, SELECT_BY_POS, MODE_TRADES))
         {
            if(OrderTicket() == ticket && OrderMagicNumber() == g_originalMagicNumber)
            {
               stillOpen = true;
               break;
            }
         }
      }

      if(!stillOpen)
      {
         // Original trade closed
         Log("ORIGINAL TRADE CLOSED: Ticket " + IntegerToString(ticket));

         // Close our copy
         if(CloseOnOriginalClose)
         {
            CloseCopiedTrade(ticket);
         }

         // Remove from tracking array
         for(int k = i; k < orderIndex - 1; k++)
         {
            orders[k] = orders[k + 1];
         }
         orderIndex--;

         SendNotification("Trade Closed: Original Ticket " + IntegerToString(ticket));
      }
   }
}

//+------------------------------------------------------------------+
//| Copy a trade from original EA                                     |
//+------------------------------------------------------------------+
bool CopyTrade(int originalTicket)
{
   if(!OrderSelect(originalTicket, SELECT_BY_TICKET))
   {
      Log("Failed to select original trade: " + IntegerToString(originalTicket));
      return false;
   }

   // Check symbol filter
   if(FollowSymbol != "" && OrderSymbol() != FollowSymbol)
   {
      Log("Skipping trade - symbol filter: " + OrderSymbol());
      return false;
   }

   // Check if we already have a copy
   if(HasCopy(originalTicket))
   {
      Log("Copy already exists for ticket: " + IntegerToString(originalTicket));
      return false;
   }

   // Calculate lot size
   double originalLot = OrderLots();
   double copyLot = NormalizeDouble(originalLot * CopyLotMultiplier, 2);

   // Normalize lot size
   double minLot = MarketInfo(OrderSymbol(), MODE_MINLOT);
   double maxLot = MarketInfo(OrderSymbol(), MODE_MAXLOT);
   if(copyLot < minLot) copyLot = minLot;
   if(copyLot > maxLot) copyLot = maxLot;

   // Prepare order
   int orderType = OrderType();
   double price, sl, tp;
   string comment = "Copy of #" + IntegerToString(originalTicket);

   if(orderType == OP_BUY)
   {
      price = NormalizeDouble(MarketInfo(OrderSymbol(), MODE_ASK), (int)MarketInfo(OrderSymbol(), MODE_DIGITS));
      sl = OrderStopLoss();
      tp = OrderTakeProfit();
   }
   else if(orderType == OP_SELL)
   {
      price = NormalizeDouble(MarketInfo(OrderSymbol(), MODE_BID), (int)MarketInfo(OrderSymbol(), MODE_DIGITS));
      sl = OrderStopLoss();
      tp = OrderTakeProfit();
   }
   else
   {
      Log("Cannot copy order type: " + OrderTypeToString(orderType));
      return false;
   }

   // Send order
   int newTicket = OrderSend(OrderSymbol(), orderType, copyLot, price, Slippage, sl, tp, comment, MagicNumber, 0, clrNONE);

   if(newTicket < 0)
   {
      int error = GetLastError();
      Log("Failed to copy trade. Error: " + IntegerToString(error) + " - " + ErrorDescription(error));
      return false;
   }

   Log("TRADE COPIED SUCCESSFULLY: Original #" + IntegerToString(originalTicket) +
       " -> New #" + IntegerToString(newTicket) +
       " " + OrderSymbol() + " " + OrderTypeToString(orderType) +
       " Lot: " + DoubleToString(copyLot, 2));

   return true;
}

//+------------------------------------------------------------------+
//| Close a copied trade                                             |
//+------------------------------------------------------------------+
bool CloseCopiedTrade(int originalTicket)
{
   int total = OrdersTotal();

   for(int i = total - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderMagicNumber() == MagicNumber &&
            StringFind(OrderComment(), "#" + IntegerToString(originalTicket)) >= 0)
         {
            bool result;
            double price;

            if(OrderType() == OP_BUY)
            {
               price = MarketInfo(OrderSymbol(), MODE_BID);
               result = OrderClose(OrderTicket(), OrderLots(), price, Slippage, clrNONE);
            }
            else if(OrderType() == OP_SELL)
            {
               price = MarketInfo(OrderSymbol(), MODE_ASK);
               result = OrderClose(OrderTicket(), OrderLots(), price, Slippage, clrNONE);
            }

            if(result)
            {
               Log("CLOSED COPY: Ticket #" + IntegerToString(OrderTicket()) +
                   " (Original #" + IntegerToString(originalTicket) + ")");
               return true;
            }
            else
            {
               int error = GetLastError();
               Log("Failed to close copy. Error: " + IntegerToString(error) + " - " + ErrorDescription(error));
            }
         }
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check if we already have a copy of this trade                     |
//+------------------------------------------------------------------+
bool HasCopy(int originalTicket)
{
   int total = OrdersTotal();

   for(int i = 0; i < total; i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderMagicNumber() == MagicNumber &&
            StringFind(OrderComment(), "#" + IntegerToString(originalTicket)) >= 0)
         {
            return true;
         }
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Log current state                                                 |
//+------------------------------------------------------------------+
void LogCurrentState()
{
   Log("=== Current Trade State ===");
   Log("Total Orders: " + IntegerToString(OrdersTotal()));

   int total = OrdersTotal();
   for(int i = 0; i < total; i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         Log("Order " + IntegerToString(i) + ": " +
             OrderTypeToString(OrderType()) + " " +
             OrderSymbol() + " Lot: " + DoubleToString(OrderLots(), 2) +
             " Magic: " + IntegerToString(OrderMagicNumber()) +
             " Ticket: " + IntegerToString(OrderTicket()));
      }
   }
   Log("========================");
}

//+------------------------------------------------------------------+
//| Log message                                                       |
//+------------------------------------------------------------------+
void Log(string message)
{
   if(!EnableLogging) return;

   string timestamp = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
   string logMessage = "[" + timestamp + "] " + message;

   // Print to Experts log
   Print(logMessage);

   // Write to file
   if(LogToFile)
   {
      int handle = FileOpen(LogFileName, FILE_READ|FILE_WRITE|FILE_TXT);
      if(handle != INVALID_HANDLE)
      {
         FileSeek(handle, 0, SEEK_END);
         FileWriteString(handle, logMessage + "\r\n");
         FileClose(handle);
      }
   }
}

//+------------------------------------------------------------------+
//| Send notification                                                |
//+------------------------------------------------------------------+
void SendNotification(string message)
{
   if(EnableAlerts)
   {
      Alert("GHL Follower: " + message);
   }

   if(EnableEmail)
   {
      SendMail("GHL Follower Alert", message);
   }

   if(EnablePush)
   {
      SendNotification(message);
   }
}

//+------------------------------------------------------------------+
//| Convert order type to string                                      |
//+------------------------------------------------------------------+
string OrderTypeToString(int type)
{
   switch(type)
   {
      case OP_BUY:      return "BUY";
      case OP_SELL:     return "SELL";
      case OP_BUYLIMIT: return "BUY LIMIT";
      case OP_SELLLIMIT: return "SELL LIMIT";
      case OP_BUYSTOP:  return "BUY STOP";
      case OP_SELLSTOP: return "SELL STOP";
      default:          return "UNKNOWN";
   }
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
