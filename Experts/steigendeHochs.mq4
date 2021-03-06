//+------------------------------------------------------------------+
//|                                               steigendeHochs.mq4 |
//|                                                  Steigende Hochs |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Swinger"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Include/JensUtils.mqh";

extern string startTime = "08:00";
extern string endTime = "21:58";
extern int myMagic = 201700404;
extern double stopAufEinstandBei = 10.0;
extern double riskInPercent = 0.5;
extern double trailInProfit = 30.0;
extern double retracement = 0.2;
extern double projection = 20.0;
extern double numberOfSwings = 3;
extern double minSwing = 30.0;
extern double maxStop = 60.0;
extern double minRangeBetweenSwingExtremaInPercent = 0.3;

static datetime lastTradeTime = NULL;

static double swingLow[];
static double swingHigh[];
static double oldHighs[];
static double oldLows[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(60);
   ArrayResize(swingLow,numberOfSwings,0);
   ArrayResize(swingHigh,numberOfSwings,0);
   ArrayResize(oldLows,numberOfSwings,0);
   ArrayResize(oldHighs,numberOfSwings,0);
   ArrayInitialize(swingLow, -1);
   ArrayInitialize(swingHigh, -1);   
   ArrayInitialize(oldLows, -1);
   ArrayInitialize(oldHighs, -1);   
      
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
         closeAllPendingOrders(myMagic);
         closeAllOpenOrders(myMagic);
      return;
   }
   trailInProfit(myMagic,trailInProfit);
   stopAufEinstand(myMagic,stopAufEinstandBei);
   
   if (Time[0] == lastTradeTime && 
      2*numberOfSwings!=OrdersTotal() && 
      currentDirectionOfOpenPositions(myMagic)!=0) {
         return;
   }
   
   if (Time[0] != lastTradeTime) {
      for (int i=0;i<numberOfSwings;i++) {
         if (swingHigh[i]!=-1) swingHigh[i]++;
         if (swingLow[i]!=-1) swingLow[i]++;
      }
      
      lastTradeTime = Time[0];
   }   
   
   int barCounter = 0;
   int numberOfHighs = 0;
   int numberOfLows = 0;
   
   
   ArrayCopy(oldHighs,swingHigh,0,0,WHOLE_ARRAY);
   ArrayCopy(oldLows,swingLow,0,0,WHOLE_ARRAY);
   ArrayInitialize(swingLow,0);
   ArrayInitialize(swingHigh,0);
   
   do {
      double fractalUpper = iFractals(Symbol(),PERIOD_CURRENT,MODE_UPPER,barCounter);
      double fractalLower = iFractals(Symbol(),PERIOD_CURRENT,MODE_LOWER,barCounter);
    //  PrintFormat("upper=%.2f, lower=%.2f",fractalUpper, fractalLower);
      if (fractalLower > 0) {
         if (numberOfLows < numberOfSwings) {
            double currentLow = Low[barCounter];
            bool isLowFarEnough = true;
            
            if (numberOfLows > 0) {
               for (int j=0;j<numberOfLows;j++) {
                  double upperRange = (100+minRangeBetweenSwingExtremaInPercent)/100*swingLow[j];
                  double lowerRange = (100-minRangeBetweenSwingExtremaInPercent)/100*swingLow[j];
                  //PrintFormat("Comparing low at %.2f with low #%i (%.2f), required range: %.2f -> %.2f", currentLow,j,swingLow[j],lowerRange,upperRange);
                  if (currentLow > lowerRange && currentLow < upperRange) {
                        isLowFarEnough = false;
                        //PrintFormat("ignoring low at %.2f because it is too close to low #%i. It must not be between %.2f and %.2f",currentLow,j,lowerRange,upperRange);
                        break;
                  }
               }
            }
            if (isLowFarEnough) {
               swingLow[numberOfLows] =  currentLow;
               numberOfLows++;
            }
         }
      }
      if (fractalUpper > 0) {
         if (numberOfHighs < numberOfSwings) {
            
            double currentHigh = High[barCounter];
            bool isHighFarEnough = true;
            
            if (numberOfHighs > 0) {
               for (int j=0;j<numberOfHighs;j++) {
                  double upperRange = (100+minRangeBetweenSwingExtremaInPercent)/100*swingHigh[j];
                  double lowerRange = (100-minRangeBetweenSwingExtremaInPercent)/100*swingHigh[j];
                  if (currentHigh > lowerRange && currentHigh < upperRange) {
                        isHighFarEnough = false;
                        break;
                  }
               }
            }
            if (isHighFarEnough) {
               swingHigh[numberOfHighs] = currentHigh;
               numberOfHighs++;
            }
         }
      }
      barCounter++;
   } while (
      barCounter<=3 ||
      ((numberOfHighs<numberOfSwings || numberOfLows<numberOfSwings) && barCounter < 1000)
   );
   //PrintFormat("highs=%i, lows=%i",numberOfHighs,numberOfLows);
   if (numberOfHighs<numberOfSwings || numberOfLows<numberOfSwings) {
      Print("aborting: no range found...");
      return;
   }
   
   ArraySort(swingHigh);
   ArraySort(swingLow,WHOLE_ARRAY,0,MODE_DESCEND);
   
   //for (int i=0;i<numberOfSwings;i++) {
     // PrintFormat("low #%i:%.2f", i, swingLow[i]);
   //}

  
   for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) {continue;}
      if (OrderSymbol() != Symbol()) {continue;}
      bool thereIsAFractalForThisOrder = false;
      for (int j=0;j<numberOfSwings;j++) {
         
         if (OP_BUYSTOP == OrderType()) {
           // PrintFormat("Comparing orderOpenPrice for buystop %.2f with swingHigh %.2f",OrderOpenPrice(),swingHigh[j]);
            if (OrderOpenPrice() == swingHigh[j]) {
               thereIsAFractalForThisOrder = true;
               break;
            }
         } else if (OP_SELLSTOP == OrderType()) {
            //PrintFormat("Comparing orderOpenPrice for sellstop %.2f with swingLow %.2f",OrderOpenPrice(),swingLow[j]);
            if (OrderOpenPrice() == swingLow[j]) {
               thereIsAFractalForThisOrder = true;
               break;
            }
         }
      }
      if (!thereIsAFractalForThisOrder && (OrderType()==OP_BUYSTOP || OrderType()==OP_SELLSTOP)) { //OrderProfit() should be 0 for pending orders
        OrderDelete(OrderTicket(),clrWhite);
      }
   }
   
      
   //if (0!= ArrayCompare(oldHighs,swingHigh,0,0,WHOLE_ARRAY) ||
     //  0!= ArrayCompare(oldLows,swingLow,0,0,WHOLE_ARRAY)) {
      //closeAllPendingOrders(myMagic);
   //}
   
   for (int i=0;i<numberOfSwings;i++) {
      //PrintFormat("trying to create order for high #%i (%.2f)",i,swingHigh[i]);
      if (!orderExists(myMagic,1,swingHigh[i], 5.0)) {
         double amplitude = 0.0;
         for (int j=0;j<numberOfSwings;j++) {
            amplitude = MathAbs(swingHigh[i] - swingLow[j]);
            if (amplitude < minSwing) continue; // abbruch, wenn kein gutes low gefunden wurde
         }
         if (amplitude>0.0) {
            double stop = swingHigh[i]-(retracement*amplitude);
            if ((amplitude*retracement)>maxStop) stop=swingHigh[i]-maxStop;
            double tp = swingHigh[i]+(projection*amplitude);
            buyTrigger(swingHigh[i],stop,tp);
         }
      } 
    }
    for (int i=0;i<numberOfSwings;i++) {  
      if (!orderExists(myMagic,-1,swingLow[i], 5.0)) {        
         double amplitude = 0.0;
         for (int j=0;j<numberOfSwings;j++) {
            amplitude = MathAbs(swingHigh[j] - swingLow[i]);    
            if (amplitude < minSwing) continue; // abbruch, wenn kein gutes low gefunden wurde         
         }
         if (amplitude>0.0) {
            double stop = swingLow[i]+(retracement*amplitude);         
            if ((amplitude*retracement)>maxStop) stop=swingLow[i]+maxStop;
            double tp = swingLow[i]-(projection*amplitude);
            sellTrigger(swingLow[i],stop,tp);
         }
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
   //PrintFormat("buyTrigger: %.2f, Ask=%.2f",price,Ask);
   if (price > Ask) {
      double lots = lotsByRisk(retracement*(price-stop),riskInPercent/100,1);
      //PrintFormat("longlots=%.2f",lots);
      OrderSend(Symbol(),OP_BUYSTOP,lots,price,3, stop,tp,"swing up",myMagic,0,clrGreen);
   }   
}

void sellTrigger(double price, double stop, double tp) {
   if (price<Bid) {
     double lots = lotsByRisk(retracement*(stop-price),riskInPercent/100,1);
     OrderSend(Symbol(),OP_SELLSTOP,lots,price,3,stop,tp,"swing down",myMagic,0,clrRed);
   }
}