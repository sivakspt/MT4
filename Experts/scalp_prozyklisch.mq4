//+------------------------------------------------------------------+
//|                                            scalp_prozyklisch.mq4 |
//|                                                center of gravity |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "center of gravity"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict


#include "../Include/JensUtils.mqh";

extern string startTime = "08:15";
extern string endTime = "20:58";
extern int myMagic = 20170312;
extern double fixedTakeProfit = 5.0;
extern double trailInProfit = 00.0;
extern double initialStop = 10.0;
extern double riskInPercent = 2.0;
extern int breakoutPeriod = 10;
double extern buffer = 2.0;
extern double stopAufEinstand = 5.0;
extern double minVola = 40.0;

string screenString = "StatusWindow";
static datetime lastTradeTime = NULL;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(60);
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
      
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if (!isHandelszeit(startTime,endTime)) {
      return;
   }
   
   int openShortOrderTicket = 0;
   int openLongOrderTicket  = 0;
   int pendingShortOrderTicket = 0;
   int pendingLongOrderTicket  = 0;

   if (0 < OrdersTotal()) {
      for (int i=OrdersTotal();i>=0;i--) {
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if (OrderMagicNumber() != myMagic) continue;
         if (OrderSymbol() != Symbol()) continue;
         
         if (OrderType() == OP_BUY) {
            openLongOrderTicket = OrderTicket();
         } else if (OrderType() == OP_SELL) {
            openShortOrderTicket = OrderTicket();
         } else if (OrderType() == OP_BUYSTOP) {
            pendingLongOrderTicket = OrderTicket();
         } else if (OrderType() == OP_SELLSTOP) {
            pendingShortOrderTicket = OrderTicket();
         }
      }
   }
   
   bool dynamic = (getBuyTrigger() - getSellTrigger())>minVola;
   if (!dynamic) {
      closeAllPendingOrders(myMagic);
   }
   
   if (dynamic && 0 == openLongOrderTicket && 0 == pendingLongOrderTicket) {
      createStopBuy();
   }
   
   if (dynamic && 0 == openShortOrderTicket && 0 == pendingShortOrderTicket) {
      createStopSell();
   }
   
   if (dynamic && 0 != pendingLongOrderTicket) {
      trailBuyTrigger(pendingLongOrderTicket);
   }
   
   if (dynamic && 0 != pendingShortOrderTicket) {
      trailSellTrigger(pendingShortOrderTicket);
   }
   
   if (0 < trailInProfit) {
      trailInProfit(myMagic,trailInProfit);
   }
   
   if (0 < stopAufEinstand) {
      stopAufEinstand(myMagic,stopAufEinstand);
   }
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   if (!isHandelszeit(startTime,endTime)) {
      closeAllOpenOrders(myMagic);
      closeAllPendingOrders(myMagic);
   }
   
  }
//+------------------------------------------------------------------+


void createStopBuy() {
   double buyTrigger = getBuyTrigger();
   double orderLots = lotsByRiskFreeMargin(riskInPercent,initialStop);
   double stop = buyTrigger-initialStop;
   double tp = 0;
   if (fixedTakeProfit>0) {
      tp = buyTrigger+fixedTakeProfit;
   }
   PrintFormat("stop buy: lots=%.5f, trigger:%.5f, stop=%.5f,tp=%.5f", orderLots,buyTrigger,stop,tp);
   int ticket = OrderSend(NULL,OP_BUYSTOP,orderLots,buyTrigger, 3,stop,tp,"breakout",myMagic,0,clrGreen);
   if (-1 == ticket) {
      Print("sell last error: " + GetLastError());   
   } else {
      //Print("ticket:" + ticket);
   }
}

void createStopSell() {
   double sellTrigger = getSellTrigger();
   double orderLots = lotsByRiskFreeMargin(riskInPercent,initialStop);
   double stop = sellTrigger+initialStop;
   double tp = 0;
   if (fixedTakeProfit>0) {
      tp = sellTrigger-fixedTakeProfit;
   }
   PrintFormat("stop sell: lots=%.5f, trigger:%.5f, stop=%.5f,tp=%.5f", orderLots,sellTrigger,stop,tp);

   int ticket = OrderSend(NULL,OP_SELLSTOP,orderLots,sellTrigger, 3,stop,tp,"breakout",myMagic,0,clrRed);
   if (-1 == ticket) {
      Print("sell last error: " + GetLastError());   
   } else {
      //Print("ticket:" + ticket);
   }
}

void trailBuyTrigger(int ticketNumber) {
   OrderSelect(ticketNumber,SELECT_BY_TICKET,MODE_TRADES);
   double buyTrigger = getBuyTrigger() ;
   if (OrderOpenPrice() > buyTrigger) {
      double stop = buyTrigger-initialStop;
      double tp = 0;
      if (fixedTakeProfit>0) {
         tp = buyTrigger+fixedTakeProfit;
      }
      OrderModify(ticketNumber,getBuyTrigger(),stop, tp, 0,clrGreen);
   }
}

void trailSellTrigger(int ticketNumber) {
   OrderSelect(ticketNumber,SELECT_BY_TICKET,MODE_TRADES);
   double sellTrigger = getSellTrigger();
   if (OrderOpenPrice() < sellTrigger) {
      double stop = sellTrigger+initialStop;
      double tp = 0;
      if (fixedTakeProfit>0) {
         tp = sellTrigger-fixedTakeProfit;
      }
      OrderModify(ticketNumber,getSellTrigger(), stop,tp, 0,clrRed);
   }
}

double getBuyTrigger() {
   return High[iHighest(Symbol(),PERIOD_CURRENT,MODE_HIGH,breakoutPeriod,0)] + buffer;
}

double getSellTrigger() {
   return Low[iLowest(Symbol(),PERIOD_CURRENT,MODE_LOW,breakoutPeriod,0)] - buffer;
}