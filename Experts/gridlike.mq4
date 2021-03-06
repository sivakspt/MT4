//+------------------------------------------------------------------+
//|                                                     gridlike.mq4 |
//|                                                         gridlike |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "gridlike"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Include/JensUtils.mqh";


extern string startTime = "08:00";
extern string endTime = "21:58";
extern double atrPeriod = 12;
extern double riskInPercent = 1.0;
extern double trailInProfitATRFactor = 0.4;
extern double stopAufEinstandBei = 15;
extern int expiry = 899;
extern double distanceATRFactor = 1.2;
extern double trendInitialStopATRFactor = 0.4;
extern double rangeInitialStopATRFactor = 0.4;
extern double trendTakeProfitATRFactor = 2.0;
extern double rangeTakeProfitATRFactor = 1.0;
extern int myMagic = 201700420;
extern double minAtrValue = 15.0;
static datetime lastTradeTime = NULL;
//extern bool prozyklisch = false;
extern int rsiPeriod = 12;

int lotDigits = -1;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(60);
   double lotstep = MarketInfo(Symbol(),MODE_LOTSTEP);
   if (lotstep == 1.0)        lotDigits = 0;
   if (lotstep == 0.1)        lotDigits = 1;
   if (lotstep == 0.01)       lotDigits = 2;
   if (lotstep == 0.001)      lotDigits = 3;
   if (lotstep == 0.0001)     lotDigits = 4;
   if (lotDigits == -1)       return(INIT_FAILED);   
   
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
//+-----------------^-------------------------------------------------+
void OnTick()
  {

    if (!isHandelszeit(startTime,endTime)) {
         closeAllPendingOrders(myMagic);
         closeAllOpenOrders(myMagic);
      return;
   }
   
   double atr=iATR(Symbol(),PERIOD_CURRENT,atrPeriod,0);
  
   trailInProfit(myMagic,trailInProfitATRFactor*atr);
   stopAufEinstand(myMagic,stopAufEinstandBei);

   if (Time[0] == lastTradeTime) {
      return;
   }
   
   RefreshRates();
   
   if (atr < minAtrValue) {
      atr=minAtrValue;
   }
   
   lastTradeTime = Time[0];
   
   bool prozyklisch = false;
   //trivial RSI Filter
   if (rsiPeriod>0) {
      double rsi = iRSI(Symbol(),PERIOD_CURRENT,rsiPeriod,PRICE_CLOSE,0);
      if (rsi < 30.0 || rsi > 70.0) prozyklisch = true;
   }
   
   if (OrdersTotal()==0) {
      if (prozyklisch) {
         double price =  Ask + distanceATRFactor * atr;
         double tp = price + atr*trendTakeProfitATRFactor;         
         double stop = price - atr*trendInitialStopATRFactor;
         PrintFormat("buytrigger price=%.5f, stop=%.5f,tp=%.5f. atr=%.2f",price,stop,tp,atr);
         buyTrigger(price, stop,tp);
      
         price = Bid  - distanceATRFactor * atr;
         tp = price - atr*trendTakeProfitATRFactor;
         stop = price + atr*trendInitialStopATRFactor;
         PrintFormat("sell trigger price=%.5f, stop=%.5f,tp=%.5f",price,stop,tp);
         sellTrigger(price, stop, tp);
      } else {  //antizyklisch
         double price = Ask + distanceATRFactor * atr;
         double tp = price - atr*rangeTakeProfitATRFactor;
         double stop = price + atr*rangeInitialStopATRFactor;
         PrintFormat("selllimit price=%.5f, stop=%.5f,tp=%.5f",price,stop,tp);
         sellLimitTrigger(price, stop,tp);     
      
         price = Bid  - (distanceATRFactor * atr);
         tp = price + atr*rangeTakeProfitATRFactor;
         stop = price - atr*rangeInitialStopATRFactor;
         PrintFormat("buylimit price=%.5f, stop=%.5f,tp=%.5f.atr=%.2f,Bid=%.2f",price,stop,tp,atr,Bid);
         buyLimitTrigger(price, stop, tp);
      }
   }
   
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   if (!isHandelszeit(startTime,endTime)) {
         closeAllPendingOrders(myMagic);
         closeAllOpenOrders(myMagic);
      return;
   }
  }
//+------------------------------------------------------------------+


void buyTrigger(double price, double stop, double tp) {
   if (price > Ask) {
      price = NormalizeDouble(price,SymbolInfoInteger(Symbol(),SYMBOL_DIGITS));
      double lots = lotsByRisk((price-stop),riskInPercent,lotDigits);
      //PrintFormat("buy: price=%.5f, lots=%.5f, stop=%.5f, tp=%.5f,Ask=%.5f",price,lots,stop,tp,Ask);
      OrderSend(Symbol(),OP_BUYSTOP,lots,price,3, stop,tp,"grid up",myMagic,TimeCurrent()+expiry,clrGreen);
   }   
}

void sellTrigger(double price, double stop, double tp) {
   if (price<Bid) {
     price = NormalizeDouble(price,5);
     double lots = lotsByRisk((stop-price),riskInPercent,lotDigits);
     //PrintFormat("sell: price=%.5f, lots=%.5f, stop=%.5f, tp=%.5f,Bid=%.5f",price,lots,stop,tp,Bid);
     OrderSend(Symbol(),OP_SELLSTOP,lots,price,3,stop,tp,"grid down",myMagic,TimeCurrent()+expiry,clrRed);
   }
}

void buyLimitTrigger(double price, double stop, double tp) {
   if (price < Ask) {
      price = NormalizeDouble(price,5);
      double lots = lotsByRisk((price-stop),riskInPercent,lotDigits);
      PrintFormat("buy: price=%.5f, lots=%.5f, stop=%.5f, tp=%.5f,Ask=%.5f",price,lots,stop,tp,Ask);
      OrderSend(Symbol(),OP_BUYLIMIT,lots,price,3, stop,tp,"grid up",myMagic,TimeCurrent()+expiry,clrGreen);
   }   
}

void sellLimitTrigger(double price, double stop, double tp) {
   if (price>Bid) {
     price = NormalizeDouble(price,5);
     double lots = lotsByRisk((stop-price),riskInPercent,lotDigits);
     PrintFormat("sell: price=%.5f, lots=%.5f, stop=%.5f, tp=%.5f,Bid=%.5f",price,lots,stop,tp,Bid);
     OrderSend(Symbol(),OP_SELLLIMIT,lots,price,3,stop,tp,"grid down",myMagic,TimeCurrent()+expiry,clrRed);
   }
}
