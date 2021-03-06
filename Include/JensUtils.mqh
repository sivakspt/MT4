//+------------------------------------------------------------------+
//|                                                  JensUtils.h.mqh |
//|                                                       mehr davon |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "mehr davon"
#property link      "https://www.mql5.com"
#property strict

double currentRisk(int myMagic) {
   double currentRisk = 0.0;
   for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderCloseTime()>0) continue;
     
      if (OrderType() == OP_BUY){
         currentRisk+=OrderLots() * (OrderOpenPrice() - OrderStopLoss());
      }
      if (OrderType() == OP_SELL) {
        currentRisk+=OrderLots() * (OrderStopLoss()- OrderOpenPrice());
      }
   }
   return currentRisk;
}

double securedProfit(int myMagic) {
   double securedProfit = 0.0;
   for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderCloseTime()>0) continue;
     
      if (OrderType() == OP_BUY){
         securedProfit+=OrderLots() * (OrderStopLoss() - OrderOpenPrice());
      }
      if (OrderType() == OP_SELL) {
        securedProfit+=OrderLots() * (OrderOpenPrice() - OrderStopLoss());
      }
   }
   return securedProfit; 
}

int atRiskPositions(int myMagic) {
   int atRiskPositions = 0;
   for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderCloseTime()>0) continue;
     
      if (OrderType() == OP_BUY &&
         OrderStopLoss()<OrderOpenPrice()){
         atRiskPositions++;
      }
      if (OrderType() == OP_SELL &&
         OrderStopLoss() > OrderOpenPrice()) {
         atRiskPositions++;
      }
   }
   return atRiskPositions;
}


double lots(double baseLots, double accountSize) {
   double lots = baseLots;
   double equityPercentage = AccountEquity()/AccountBalance();
   int equityTimes = MathFloor( (AccountEquity()/accountSize) * equityPercentage );  // how many time is present equity times BaseEquity
   if(equityTimes >= 1) {
         lots = baseLots*equityTimes;                 // total new open Lots
   }         
   if (lots > MarketInfo(Symbol(), MODE_MAXLOT)) {
      lots = MarketInfo(Symbol(), MODE_MAXLOT);
   }
   return lots;
}

double lotsByRisk(double stopDistance, double riskInPercentOfEquity, int lotDigits) {
   if (0==stopDistance) return 0.0;
   //PrintFormat("passed symbol_digits=%i, mode_points says: %i",lotDigits, MarketInfo(Symbol(),MODE_DIGITS));
   double equityAtRisk = (riskInPercentOfEquity/100) * AccountEquity();
   //PrintFormat("equity to risk: %.2f with stopDistance=%.2f",equityAtRisk,stopDistance);
   double lots = equityAtRisk / (stopDistance * MarketInfo(Symbol(),MODE_LOTSIZE));
   lots = NormalizeDouble(lots,lotDigits);
   
   if (lots > MarketInfo(Symbol(),MODE_MAXLOT)) {
      lots = MarketInfo(Symbol(),MODE_MAXLOT);
   }
   
   PrintFormat("money to risk: %.2f,stopDistance:%.2f, lotsize: %.2f, lots=%.2f",equityAtRisk,stopDistance,MarketInfo(Symbol(),MODE_LOTSIZE),lots);
   
   return lots;   
}

double lotsByRiskFreeMargin(double riskInPercent, double stopDistance) {
   double moneyToRisk = AccountFreeMargin()*riskInPercent/100;   
   double lots = (moneyToRisk / (stopDistance*MarketInfo(Symbol(),MODE_LOTSIZE)));
   if (lots>MarketInfo(Symbol(),MODE_MAXLOT)) return MarketInfo(Symbol(),MODE_MAXLOT);   
   lots = NormalizeDouble(lots,1);
   return lots;
}

void closeAllPendingOrders(int myMagic) {
 for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderType() == OP_BUYSTOP ||
         OrderType() == OP_SELLSTOP ||
         OrderType() == OP_SELLLIMIT ||
         OrderType() == OP_BUYLIMIT) {
         OrderDelete(OrderTicket(),clrWhite);
      }
   }
}

int countOpenPendingOrders(int myMagic) {
   int openPendingOrders = 0;
   for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderType() == OP_BUYSTOP ||
         OrderType() == OP_SELLSTOP ||
         OrderType() == OP_SELLLIMIT ||
         OrderType() == OP_BUYLIMIT) {
         openPendingOrders++;
      }
   }
   return openPendingOrders;
}

int countOpenPositions(int myMagic) {
   int openPositons = 0;
   for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderType() == OP_BUY ||
         OrderType() == OP_SELL) {
         openPositons++;
      }
   }
   return openPositons;
}

int countOpenPositions(int myMagic, int mode) {
   int openPositons = 0;
   for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderType() == mode) {
         openPositons++;
      }
   }
   return openPositons;
}


void closeAllOpenOrders(int myMagic) {
 RefreshRates();
 for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderType() == OP_BUY) {
         OrderClose(OrderTicket(),OrderLots(),Bid,2,clrWhite);
      }
      
      if (OrderType() == OP_SELL) {
         OrderClose(OrderTicket(),OrderLots(),Ask,2,clrWhite);
      }
   }
}

void closeLongPositions(int myMagic) {
 RefreshRates();
 for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderType() == OP_BUY) {
         OrderClose(OrderTicket(),OrderLots(),Bid,2,clrWhite);
      }
   }
}

void closeShortPositions(int myMagic) {
 RefreshRates();
 for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderType() == OP_SELL) {
         OrderClose(OrderTicket(),OrderLots(),Ask,2,clrWhite);
      }
   }
}

int currentDirectionOfOpenPositions(int myMagic) {
   int direction = 0;
   for (int i=OrdersTotal();i>=0;i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() != myMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderType() == OP_BUY) {
         direction = direction + 1;
      }
      
      if (OrderType() == OP_SELL) {
         direction = direction - 1;
      }
   }
   return direction;
}

bool isHandelszeit(string startTime, string endTime) {

   if (DayOfWeek()<1 || DayOfWeek()>5) {
      return false;
   }
   
   string startTimeString = StringFormat("%4i.%02i.%02i %s",TimeYear(TimeLocal()),TimeMonth(TimeLocal()), TimeDay(TimeLocal()), startTime);
   string endTimeString = StringFormat("%4i.%02i.%02i %s",TimeYear(TimeLocal()),TimeMonth(TimeLocal()), TimeDay(TimeLocal()), endTime);
         
   datetime startDt = StrToTime(startTimeString);
   datetime endDt = StrToTime(endTimeString);
   
   if (TimeLocal() >= startDt && TimeLocal()<=endDt) {
      return true;
   }
   return false;
}

bool isHandelszeit(int startHour, int startMinute, int endHour, int endMinute) {

   string startTimeString = StringFormat("%2i:%2i", startHour,startMinute);
   string endTimeString = StringFormat("%2i:%2i", endHour, endMinute);
         
   return isHandelszeit(startTimeString, endTimeString);
}

void trailInProfit(int myMagic, double distance) {
      if (0 == distance) return;
      RefreshRates();
      double stopForLong = Bid - distance;
      double stopForShort = Ask + distance;
     
      trail(myMagic,stopForShort,stopForLong,true);
}

void trailByATR(int myMagic, int period, ENUM_TIMEFRAMES timeframe, double factor) {
   if (factor <= 0) return;
   if (period <= 0) return;
   RefreshRates();
   double atr = iATR(Symbol(),timeframe,period,0);
   double stopForLong = Bid - (factor * atr);
   double stopForShort = Ask + (factor * atr);
   
   trail(myMagic,stopForShort,stopForLong,true);
}

void stopAufEinstand(int myMagic, double distance) {
   if (0==distance) return;
    double spread = NormalizeDouble(Ask - Bid, Digits);
      
      for (int i=OrdersTotal();i>=0;i--) {
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);         
         if (OrderMagicNumber() != myMagic) {continue;}
         if (OrderSymbol() != Symbol()) {continue;}
         
         //ein 0.5 EUR soll übrigbleiben.
         double buffer = 0.5 / (MarketInfo(Symbol(),MODE_LOTSIZE)*OrderLots());
         //PrintFormat("lotsize: %.5f, orderlots: %.2f, buffer: %.5f",MarketInfo(Symbol(),MODE_LOTSIZE),OrderLots(), buffer);
    
         if (OrderType()==OP_BUY) {
            if ((OrderOpenPrice() + distance) <= Bid) {
               double targetStop = NormalizeDouble(OrderOpenPrice() + spread+buffer,Digits );
               if (OrderStopLoss() < targetStop)  {
                  PrintFormat("Stop auf Einstand long: OrderOpenPrice=%.2f, spread = %.2f, Bid=%.2f, oldstop=%.2f, targetStop=%.2f",OrderOpenPrice(),spread, Bid, OrderStopLoss(),targetStop);
                  if (!OrderModify(OrderTicket(),0,targetStop,OrderTakeProfit(),0,clrGreen)) {
                          PrintFormat("last error stop auf einstand:%i; bid=%.5f, ask=%.5f, orderOpenPrice=%.5f, newStop=%.5f, oldStop=%.5f ",
                           GetLastError(), Bid, Ask, OrderOpenPrice(), (OrderOpenPrice() + spread),OrderStopLoss());
                  }
               }
            }
         }
         if (OrderType()==OP_SELL) {
            double targetStop = NormalizeDouble(OrderOpenPrice() - spread-buffer,Digits );
            if ((OrderOpenPrice() - distance) >= Ask && OrderStopLoss() > targetStop) {
               
               //PrintFormat("Stop auf Einstand short: OrderOpenPrice=%.2f, spread = %.2f, oldstop=%.2f, Ask=%.2f, targetstop=%.2f",OrderOpenPrice(),spread, OrderStopLoss(),Ask, targetStop);
               if (!OrderModify(OrderTicket(),0,targetStop,OrderTakeProfit(),0,clrGreen)) {
                     PrintFormat("last error stop auf einstand short:%i; bid=%.5f, ask=%.5f, orderOpenPrice=%.5f, newStop=%.5f, oldStop=%.5f  ",
                        GetLastError(), Bid, Ask, OrderOpenPrice(), (OrderOpenPrice() - spread),OrderStopLoss());                
               }
            }
         }
      }
}

void trailWithLastXCandle(int myMagic, int x) {

      if (0 == x) return;
      RefreshRates();
      double stopForLong = Low[iLowest(NULL,PERIOD_CURRENT,MODE_LOW,x,0)];
      double stopForShort = High[iHighest(NULL,PERIOD_CURRENT,MODE_HIGH,x,0)];
      trail(myMagic,stopForShort,stopForLong, false);
 
}

void trail(int myMagic, double stopForShort, double stopForLong, bool inProfit) {
     for (int i=OrdersTotal();i>=0;i--) {
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if (OrderMagicNumber() != myMagic) {continue;}
         if (OrderSymbol() != Symbol()) {continue;}
         if (OrderProfit() > 0) {
            if (OrderType() == OP_BUY && stopForLong > 0) {
               if (OrderStopLoss() < stopForLong) {
                 if (stopForLong > (OrderOpenPrice() + (Ask-Bid)) || !inProfit) {
                    if (!OrderModify(OrderTicket(),0,stopForLong,OrderTakeProfit(),0,clrGreen)) {
                     PrintFormat("last error trail long:%i ",GetLastError());                     
                    }
                 }
               }
               continue;
            } 
            if (OrderType() == OP_SELL && stopForShort > 0) {
               if (OrderStopLoss() > stopForShort) {
                  if (stopForShort < (OrderOpenPrice() - (Ask-Bid)) || !inProfit) {
                     if (!OrderModify(OrderTicket(),0,stopForShort,OrderTakeProfit(),0,clrRed)) {
                       PrintFormat("last error trail short:%i ",GetLastError());                      
                     }
                  }
               }
            }
         }
     }
}

void trailWithMA(int myMagic, double maValue) {

      if (0 == maValue) return;
      RefreshRates();
      trail(myMagic,maValue,maValue,false);
}

int openLongPosition(int myMagic, double lots, double price, double stopLoss, double takeProfit) {
   return openLongPosition(myMagic,lots,price,stopLoss,takeProfit,NULL);   
}

int openLongPosition(int myMagic, double lots, double price, double stopLoss, double takeProfit, string comment) {
   RefreshRates();
   
   double orderLots = NormalizeDouble(lots,1);
   double orderPrice = NormalizeDouble(price,Digits);
   double orderStop = NormalizeDouble(stopLoss,Digits);
   double orderProfit = NormalizeDouble(takeProfit,Digits);
   
   int ticket = OrderSend(NULL,OP_BUY,orderLots,orderPrice,3, orderStop,orderProfit,comment,myMagic,0,clrGreen);     
   if (-1 == ticket) {
      Print("buy last error: " + GetLastError());   
   } else {
     // Print("ticket:" + ticket);
   }
   
   return ticket;
}

int openShortPosition(int myMagic, double lots, double price, double stopLoss, double takeProfit) {
   return openShortPosition(myMagic,lots,price,stopLoss,takeProfit,NULL);
}

int openShortPosition(int myMagic, double lots, double price, double stopLoss, double takeProfit,string comment) {
   RefreshRates();
   
   double orderLots = NormalizeDouble(lots,1);
   double orderPrice = NormalizeDouble(price,Digits);
   double orderStop = NormalizeDouble(stopLoss,Digits);
   double orderProfit = NormalizeDouble(takeProfit,Digits);
   
   int ticket = OrderSend(NULL,OP_SELL,orderLots,orderPrice, 3,orderStop,orderProfit,comment,myMagic,0,clrRed);
   if (-1 == ticket) {
      Print("sell last error: " + GetLastError());   
   } else {
      //Print("ticket:" + ticket);
   }
   
   return ticket;
}

void timeout(int myMagic, datetime closeIfOpenedBefore) {
   for (int i=OrdersTotal();i>=0;i--) {
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if (OrderMagicNumber() != myMagic) {continue;}
         if (OrderSymbol() != Symbol()) {continue;}
         if (OrderOpenTime()< closeIfOpenedBefore) {
         
            if (OrderType() == OP_BUY) {
               OrderClose(OrderTicket(),OrderLots(),Bid,3,clrGreen);
               continue;
            } 
            if (OrderType() == OP_SELL) {
               OrderClose(OrderTicket(),OrderLots(),Ask,3,clrGreen);
               continue;
            }
         }        
     }
}


bool orderExists(int myMagic, int longOrShort, double price, double tolerance) {
   bool exists = false;
   
      for (int i=OrdersTotal();i>=0;i--) {
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if (OrderMagicNumber() != myMagic) {continue;}
         if (OrderSymbol() != Symbol()) {continue;}
         if (longOrShort==1) {
            if (OrderType() == OP_BUY || OrderType() == OP_BUYLIMIT || OrderType() == OP_BUYSTOP) {
               if ((price - tolerance) < OrderOpenPrice() &&
                OrderOpenPrice() < (price + tolerance)) {
                  exists = true;
                  break;
               }
            }
         }
         if (longOrShort==-1) {
            if (OrderType() == OP_SELL || OrderType() == OP_SELLLIMIT || OrderType() == OP_SELLSTOP) {
                if ((price - tolerance) < OrderOpenPrice() &&
                OrderOpenPrice() < (price + tolerance)) {
                  exists = true;
                  break;
               }
            }
         }
     }
     
     return exists;
}

datetime todayAt(string timeString) {
   datetime now = TimeLocal();
   return StrToTime(TimeYear(now)+"."+TimeMonth(now) + "."+TimeDay(now)+" "+timeString);   
}

datetime yesterdayAt(string timeString) {
   datetime now = TimeLocal();
   if (TimeDay(now-(60*60*24)) == 0) {
      int month = TimeMonth(now)-1;
      int day = 31;
      
      switch (month) {
         case 2: day=28;break;
         case 4:
         case 6:
         case 9:
         case 11: day=30;break;
         default: day=31;
      }
      
      return StrToTime(TimeYear(now)+"."+month + "."+day+" "+timeString);   
   } else {
      return StrToTime(TimeYear(now)+"."+TimeMonth(now) + "."+(TimeDay(now)-1)+" "+timeString);   
   }

}