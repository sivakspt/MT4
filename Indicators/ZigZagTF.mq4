//+------------------------------------------------------------------+
//|                                                     ZigZagTF.mq4 |
//|                                         Copyright © 2008, Kharko |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2008, Kharko"
#property link      ""

#property indicator_chart_window
#property indicator_buffers 4
#property indicator_color1 Yellow
#property indicator_color2 Yellow
#property indicator_color3 Aqua
#property indicator_color4 Aqua
#property indicator_width1 1
#property indicator_width2 1

//---- indicator parameters
extern int 
         ExtDepth =2,      // временной промежуток
         CheckBar =2,      // количество бар для подтверждения экстремума
         TimeFrame=0,      // младший ТФ, с которого берутся данные для построения линии ЗЗ
         Price=0;          // используемая цена. 0 - Low/High, 1 - Open, 2 - Low, 3 - High, 4 - Close
extern color
         ZZcolor  = Yellow;// Цвет линии 
extern int 
         ZZwidth  =2;      // Толщина линии
extern bool 
         Levels   =false,  // Уровни появления/обновления луча 
         Record   =false;  // Включить/выключить запись разворотных точек в файл
extern color
         Lcolor   = Aqua,  // Цвет нижнего уровня
         Hcolor   = Aqua;  // Цвет верхнего уровня
extern bool 
         Fibo1     =false, // Включение/выключение Фибо-уровней на последнем луче 
         Fibo2     =false; // Включение/выключение Фибо-уровней на предпоследнем луче 
extern color
         FiboColor1= Aqua, // Цвет Фибо-уровней на последнем луче 
         FiboColor2= Yellow;// Цвет Фибо-уровней на предпоследнем луче 

//---- indicator buffers
bool
         Count=true;
double   
         LowLevel[],
         HighLevel[],
         LowBuffer[],
         HighBuffer[];
double 
         lBar_0,
         hBar_0;
datetime 
         tiBar_0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   if(TimeFrame>Period() || TimeFrame==0)
      TimeFrame=Period();
   if(TimeFrame!=1 && TimeFrame!=5 && TimeFrame!=15 && TimeFrame!=30 && TimeFrame!=60 && TimeFrame!=240 && TimeFrame!=1440 && TimeFrame!=10080 && TimeFrame!=43200)
      TimeFrame=Period();

   Comment("Copyright © 2008, Kharko");

//---- drawing settings
   SetIndexBuffer(0,LowBuffer);
   SetIndexBuffer(1,HighBuffer);
   SetIndexStyle(0,DRAW_ZIGZAG,STYLE_SOLID,ZZwidth,ZZcolor);
   SetIndexStyle(1,DRAW_ZIGZAG,STYLE_SOLID,ZZwidth,ZZcolor);
   SetIndexBuffer(2,LowLevel);
   SetIndexBuffer(3,HighLevel);
   SetIndexStyle(2,DRAW_SECTION,STYLE_DOT,EMPTY,Lcolor);
   SetIndexStyle(3,DRAW_SECTION,STYLE_DOT,EMPTY,Hcolor);
//---- indicator buffers mapping
   SetIndexEmptyValue(0,0.0);
   SetIndexEmptyValue(1,0.0);
   SetIndexEmptyValue(2,0.0);
   SetIndexEmptyValue(3,0.0);
   SetIndexLabel(0,"ZigZag_Low" );
   SetIndexLabel(1,"ZigZag_High" );
   SetIndexLabel(2,"Level_Low" );
   SetIndexLabel(3,"Level_High" );
//---- indicator short name
   IndicatorShortName("ZigZag("+ExtDepth+")");

   if(Fibo1)
   {
      ObjectCreate("Fibo1",OBJ_FIBO,0,0,0,0,0);
      ObjectSet("Fibo1",OBJPROP_LEVELSTYLE,STYLE_DOT);
      ObjectSet("Fibo1",OBJPROP_LEVELCOLOR,FiboColor1);

      ObjectSet("Fibo1",OBJPROP_FIBOLEVELS,17);
   }
   if(Fibo2)
   {
      ObjectCreate("Fibo2",OBJ_FIBO,0,0,0,0,0);
      ObjectSet("Fibo2",OBJPROP_LEVELSTYLE,STYLE_DOT);
      ObjectSet("Fibo2",OBJPROP_LEVELCOLOR,FiboColor2);

      ObjectSet("Fibo2",OBJPROP_FIBOLEVELS,17);
   }
//---- initialization done
   return(0);
  }
//+------------------------------------------------------------------+
int deinit() 
{
   Comment("");
   ObjectDelete("Fibo1");
   ObjectDelete("Fibo2");
   return(0);
}
//+------------------------------------------------------------------+
int start()
  {
   bool
      UpDown;
   int    
      counted_bars=IndicatorCounted(),
      TS_L,
      TS_H,
      shift,
      pos,
      lastpos,
      limit,
      curhighpos,
      curlowpos;
   double   
      lasthigh,
      lastlow,
      curhigh,
      curlow;
   datetime 
         timehigh=0,
         timelow=0;

   if(!IsConnected())return(1);

   if(MarketInfo(Symbol(),MODE_TRADEALLOWED) != 1)return(1);

// Проверка на обновление экстремумов на текущем баре
   if (lBar_0<=Low[0] && hBar_0>=High[0] && tiBar_0==Time[0]) 
      return(0);
   else
   {
      lBar_0=Low[0]; 
      hBar_0=High[0]; 
      tiBar_0=Time[0];
   }

// Используемая цена для построения ЗЗ
   switch(Price)
     {
      case 1 : TS_L=0;  TS_H=0;  break;
      case 2 : TS_L=1;  TS_H=1;  break;
      case 3 : TS_L=2;  TS_H=2;  break;
      case 4 : TS_L=3;  TS_H=3;  break;
      default :
         Price=0;
         TS_L=1;  TS_H=2;
     }
   
// Построение уровней появления/обновления луча
   limit=Bars-counted_bars+1;
   if(Levels)
   {
      for(shift=limit; shift>=0; shift--)
      {
         if(ExtDepth==0)
            break;
         if(Price==0)
         {
            LowLevel[shift]=iLow(NULL,0,iLowest(NULL,0,TS_L,ExtDepth,shift+1))-Point;
            HighLevel[shift]=iHigh(NULL,0,iHighest(NULL,0,TS_H,ExtDepth,shift+1))+Point;
         }
         else
         {
            LowLevel[shift]=Price_(0,iLowest(NULL,0,TS_L,ExtDepth,shift+1))-Point;
            HighLevel[shift]=Price_(0,iHighest(NULL,0,TS_H,ExtDepth,shift+1))+Point;
         }
      }
   }

 // обнуляем индикаторные буферы
   ArrayInitialize(LowBuffer,0.0);
   ArrayInitialize(HighBuffer,0.0);
   
// Построение линии ЗЗ. Расчет начинаем с последнего известного бара
   limit=iBars(NULL,TimeFrame)-ExtDepth*Period()/TimeFrame-1;

   for(shift=limit; shift>=0; shift--)
   {
      RefreshRates();
// Определяем положение и величину текущих экстремумов
      curlowpos=iLowest(NULL,TimeFrame,TS_L,(ExtDepth+CheckBar)*Period()/TimeFrame+1,shift);
      curhighpos=iHighest(NULL,TimeFrame,TS_H,(ExtDepth+CheckBar)*Period()/TimeFrame+1,shift);
      if(Price==0)
      {
         curlow=iLow(NULL,TimeFrame,curlowpos);
         curhigh=iHigh(NULL,TimeFrame,curhighpos);
      }
      else
      {
         curlow=Price_(TimeFrame,curlowpos);
         curhigh=Price_(TimeFrame,curhighpos);
      }
      
      if(CheckBar!=0 && iVolume(NULL,TimeFrame,shift-1)==0)          // если не все бары сформированы для подтверждения, то прерываем цикл
         break;
      
// Если положение и величина первых экстремумов неизвесны
      if(timelow==0 && timehigh==0)
      {
         if(curlowpos==shift+CheckBar*Period()/TimeFrame && curhighpos==shift+CheckBar*Period()/TimeFrame)
            continue;                                                // Экстремумы должны находится на разных барах
         pos=iBarShift(NULL,0,iTime(NULL,TimeFrame,curlowpos),false);// Cмещение бара на текущем графике для Low
         LowBuffer[pos]=curlow;                                      // новое значение Low
         timelow=iTime(NULL,TimeFrame,curlowpos);                    // время появления Low на младшем ТФ
         lastlow=curlow;                                             

         pos=iBarShift(NULL,0,iTime(NULL,TimeFrame,curhighpos),false);// Cмещение бара на текущем графике для High
         HighBuffer[pos]=curhigh;                                     // новое значение High
         timehigh=iTime(NULL,TimeFrame,curhighpos);                   // время появления High на младшем ТФ
         lasthigh=curhigh;

// Направление луча
         if(timelow<timehigh)
            UpDown=true;
         else
            UpDown=false;

         continue;
      }

// Последний луч направлен вверх
      if(UpDown) 
      {
// На текущем баре есть обновление верхнего луча
         if(curhighpos==shift+CheckBar*Period()/TimeFrame && lasthigh<curhigh)
         {
            pos=iBarShift(NULL,0,iTime(NULL,TimeFrame,curhighpos),false);// Cмещение бара на текущем графике для High
            HighBuffer[pos]=curhigh;                                     // новое значение High
            lastpos=iBarShift(NULL,0,timehigh,false);                    // последнее положение High
            if(lastpos!=pos)                                             // сравниваем последнее и текущее положение High
               HighBuffer[lastpos]=0.0;                                  // если не равны, то обнуляем старое значение
            timehigh=iTime(NULL,TimeFrame,curhighpos);                   // время появления High на младшем ТФ
            lasthigh=HighBuffer[pos];                                    // запоминаем новое положение High
            UpDown=true;                                                 // направление луча вверх
         }
// На текущем баре есть появление нижнего луча
         if(curlowpos==shift+CheckBar*Period()/TimeFrame)
         {
            pos=iBarShift(NULL,0,iTime(NULL,TimeFrame,curlowpos),false); // Cмещение бара на текущем графике для Low
            LowBuffer[pos]=curlow;                                       // новое значение Low
            timelow=iTime(NULL,TimeFrame,curlowpos);                     // время появления Low на младшем ТФ
            lastlow=LowBuffer[pos];                                      // запоминаем новое положение Low
            UpDown=false;                                                // направление луча вниз
         }
      }
// Последний луч направлен вниз
      else
      {
// На текущем баре есть обновление нижнего луча
         if(curlowpos==shift+CheckBar*Period()/TimeFrame && lastlow>curlow)
         {
            pos=iBarShift(NULL,0,iTime(NULL,TimeFrame,curlowpos),false); // Cмещение бара на текущем графике для Low
            LowBuffer[pos]=curlow;                                       // новое значение Low
            lastpos=iBarShift(NULL,0,timelow,false);                     // последнее положение Low
            if(lastpos!=pos)                                             // сравниваем последнее и текущее положение Low
               LowBuffer[lastpos]=0.0;                                   // если не равны, то обнуляем старое значение
            timelow=iTime(NULL,TimeFrame,curlowpos);                     // время появления Low на младшем ТФ
            lastlow=LowBuffer[pos];                                      // запоминаем новое положение Low
            UpDown=false;                                                // направление луча вниз
         }
// На текущем баре есть появление верхнего луча
         if(curhighpos==shift+CheckBar*Period()/TimeFrame)
         {
            pos=iBarShift(NULL,0,iTime(NULL,TimeFrame,curhighpos),false);// Cмещение бара на текущем графике для High
            HighBuffer[pos]=curhigh;                                     // новое значение High
            timehigh=iTime(NULL,TimeFrame,curhighpos);                   // время появления High на младшем ТФ
            lasthigh=HighBuffer[pos];                                    // запоминаем новое положение High
            UpDown=true;                                                 // направление луча вверх
         }
      }
   }
   
// Включение/выключение Фибо-уровней
   if(Fibo1 || Fibo2)
      Fibo_();

// Включить/выключить запись разворотных точек в файл
   if(Record && Count)
   {
      Records();
   }
      
return(0);
}
//+------------------------------------------------------------------+
double Price_(int TF,int pos) 
{
   switch(Price)
     {
      case 1 : return(iOpen(NULL,TF,pos));  break;
      case 2 : return(iLow(NULL,TF,pos));  break;
      case 3 : return(iHigh(NULL,TF,pos));  break;
      case 4 : return(iClose(NULL,TF,pos));  break;
     }
}
//+------------------------------------------------------------------+
int Records() 
{
// запись разворотных точек в файл
   int
         handle;
   string
         FileName,
         Pr,
         TF;

// Формируем имя файла
   switch(Price)
     {
      case 0  : Pr="HL"; break;
      case 1  : Pr="Op"; break;
      case 2  : Pr="L";  break;
      case 3  : Pr="H";  break;
      case 4  : Pr="Cl"; break;
     }
   switch(Period())
     {
      case 1    : TF=" M1 ("+ExtDepth+" "+CheckBar+" "+TimeFrame+" "+Pr+")"; break;
      case 5    : TF=" M5 ("+ExtDepth+" "+CheckBar+" "+TimeFrame+" "+Pr+")"; break;
      case 15   : TF=" M15 ("+ExtDepth+" "+CheckBar+" "+TimeFrame+" "+Pr+")"; break;
      case 30   : TF=" M30 ("+ExtDepth+" "+CheckBar+" "+TimeFrame+" "+Pr+")"; break;
      case 60   : TF=" H1 ("+ExtDepth+" "+CheckBar+" "+TimeFrame+" "+Pr+")"; break;
      case 240  : TF=" H4 ("+ExtDepth+" "+CheckBar+" "+TimeFrame+" "+Pr+")"; break;
      case 1440 : TF=" D1 ("+ExtDepth+" "+CheckBar+" "+TimeFrame+" "+Pr+")"; break;
      case 10080: TF=" W1 ("+ExtDepth+" "+CheckBar+" "+TimeFrame+" "+Pr+")"; break;
      case 43200: TF=" Mn ("+ExtDepth+" "+CheckBar+" "+TimeFrame+" "+Pr+")"; break;
     }

   FileName="ZZ "+Symbol()+TF+".csv";
   handle=FileOpen(FileName,FILE_CSV|FILE_WRITE,';');
   
   if(handle<1)
   {
      Print("File "+FileName+" can\'t open ",GetLastError());// Упс... неудача... повторим попытку на следующем тике
      return(0);
   }   
   
// поиск разворотных точек
   int Trend=0;
   for(int shift=Bars; shift>=0; shift--)
   {
      if(HighBuffer[shift]>0 && (Trend==0 || Trend==1))
      {
         FileWrite(handle,shift,"Up",HighBuffer[shift]);
         Trend=2;
         if(LowBuffer[shift]>0)
         {
            FileWrite(handle,shift,"Down",LowBuffer[shift]);
            Trend=1;
         }
         continue;
      }
      if(LowBuffer[shift]>0 && (Trend==0 || Trend==2))
      {
         FileWrite(handle,shift,"Down",LowBuffer[shift]);
         Trend=1;
         if(HighBuffer[shift]>0)
         {
            FileWrite(handle,shift,"Up",HighBuffer[shift]);
            Trend=2;
         }
      }
   }
   FileClose(handle);
//---
   Count=false; // Запись прошла успешно
   return(0);
}
//+------------------------------------------------------------------+
int Fibo_() 
{
// Находим 4 последних экстремума
   double
      p1,
      p2,
      p3,
      p4;
   datetime
      t1,
      t2,
      t3,
      t4;
      
   for(int i=0;i<Bars;i++)
   {
// 2 последних экстремума вниз
      if(LowBuffer[i]!=0)
      {
         if(p2==0)
         {
            p2=LowBuffer[i];
            t2=iTime(NULL,0,i);
         }
         else
         {
            p4=LowBuffer[i];
            t4=iTime(NULL,0,i);
         }
      }
         
// 2 последних экстремума вверх
      if(HighBuffer[i]!=0)
      {
         if(p1==0)
         {
            p1=HighBuffer[i];
            t1=iTime(NULL,0,i);
         }
         else
         {
            p3=HighBuffer[i];
            t3=iTime(NULL,0,i);
         }
      }
      if(p1!=0 && p2!=0 && p3!=0 && p4!=0) // Найдены все 4 точки - выходим из цикла
         break;
   }

// Подключение Фибо-уровней на последнем луче
   if(Fibo1)
   {
      if(t1>t2 || (t1==t2 && t3>t4))
      {
         ObjectSet("Fibo1",OBJPROP_TIME1,t1-Period()*60*2);
         ObjectSet("Fibo1",OBJPROP_PRICE1,p2);
         ObjectSet("Fibo1",OBJPROP_TIME2,t1);
         ObjectSet("Fibo1",OBJPROP_PRICE2,p1);
         fibo_patterns("Fibo1",p1, p2,"                    ");
      }
      else
      if(t1<t2 || (t1==t2 && t3<t4))
      {
         ObjectSet("Fibo1",OBJPROP_TIME1,t1);
         ObjectSet("Fibo1",OBJPROP_PRICE1,p1);
         ObjectSet("Fibo1",OBJPROP_TIME2,t1-Period()*60*2);
         ObjectSet("Fibo1",OBJPROP_PRICE2,p2);
         fibo_patterns("Fibo1",p2, p1,"                    ");
      }
   }

// Подключение Фибо-уровней на предпоследнем луче
   if(Fibo2)
   {
      if(t1>t2 || (t1==t2 && t3>t4))
      {
         ObjectSet("Fibo2",OBJPROP_TIME1,t3);
         ObjectSet("Fibo2",OBJPROP_PRICE1,p3);
         ObjectSet("Fibo2",OBJPROP_TIME2,t3+Period()*60*2);
         ObjectSet("Fibo2",OBJPROP_PRICE2,p2);
         fibo_patterns("Fibo2",p2,p3,"");
      }
      else
      if(t1<t2 || (t1==t2 && t3<t4))
      {
         ObjectSet("Fibo2",OBJPROP_TIME1,t4);
         ObjectSet("Fibo2",OBJPROP_PRICE1,p4);
         ObjectSet("Fibo2",OBJPROP_TIME2,t4+Period()*60*2);
         ObjectSet("Fibo2",OBJPROP_PRICE2,p1);
         fibo_patterns("Fibo2",p1,p4,"");
      }
   }
   return(0);
}
//--------------------------------------------------------
void fibo_patterns(string nameObj,double fiboPrice,double fiboPrice1,string str)
  {

// Функция построения Фибо уровней

   ObjectSet(nameObj,OBJPROP_FIRSTLEVEL,0);
   ObjectSetFiboDescription(nameObj, 0, "0 "+DoubleToStr(fiboPrice, Digits)+str); 
  
   ObjectSet(nameObj,OBJPROP_FIRSTLEVEL+1,0.236);
   ObjectSetFiboDescription(nameObj, 1, "23.6 "+DoubleToStr(fiboPrice1*0.236+fiboPrice*(1-0.236), Digits)+str); 

   ObjectSet(nameObj,OBJPROP_FIRSTLEVEL+2,0.382);
   ObjectSetFiboDescription(nameObj, 2, "38.2 "+DoubleToStr(fiboPrice1*0.382+fiboPrice*(1-0.382), Digits)+str); 
 
   ObjectSet(nameObj,OBJPROP_FIRSTLEVEL+3,0.5);
   ObjectSetFiboDescription(nameObj, 3, "50.0 "+DoubleToStr(fiboPrice1*0.5+fiboPrice*(1-0.5), Digits)+str); 

   ObjectSet(nameObj,OBJPROP_FIRSTLEVEL+4,0.618);
   ObjectSetFiboDescription(nameObj, 4, "61.8 "+DoubleToStr(fiboPrice1*0.618+fiboPrice*(1-0.618), Digits)+str); 

   ObjectSet(nameObj,OBJPROP_FIRSTLEVEL+5,0.707);
   ObjectSetFiboDescription(nameObj, 5, "70.7 "+DoubleToStr(fiboPrice1*0.707+fiboPrice*(1-0.707), Digits)+str); 

   ObjectSet(nameObj,OBJPROP_FIRSTLEVEL+6,0.786);
   ObjectSetFiboDescription(nameObj, 6, "78.6 "+DoubleToStr(fiboPrice1*0.786+fiboPrice*(1-0.786), Digits)+str); 
  
   ObjectSet(nameObj,OBJPROP_FIRSTLEVEL+7,0.886);
   ObjectSetFiboDescription(nameObj, 7, "88.6 "+DoubleToStr(fiboPrice1*0.886+fiboPrice*(1-0.886), Digits)+str); 

   ObjectSet(nameObj,OBJPROP_FIRSTLEVEL+8,1.0);
   ObjectSetFiboDescription(nameObj, 8, "100.0 "+DoubleToStr(fiboPrice1, Digits)+str); 
  
   ObjectSet(nameObj,OBJPROP_FIRSTLEVEL+9,1.128);
   ObjectSetFiboDescription(nameObj, 9, "112.8 "+DoubleToStr(fiboPrice1*1.128+fiboPrice*(1-1.128), Digits)+str); 
  
   ObjectSet(nameObj,OBJPROP_FIRSTLEVEL+10,1.272);
   ObjectSetFiboDescription(nameObj, 10, "127.2 "+DoubleToStr(fiboPrice1*1.272+fiboPrice*(1-1.272), Digits)+str); 

   ObjectSet(nameObj,OBJPROP_FIRSTLEVEL+11,1.414);
   ObjectSetFiboDescription(nameObj, 11, "141.4 "+DoubleToStr(fiboPrice1*1.414+fiboPrice*(1-1.414), Digits)+str); 
  
   ObjectSet(nameObj,OBJPROP_FIRSTLEVEL+12,1.618);
   ObjectSetFiboDescription(nameObj, 12, "161.8 "+DoubleToStr(fiboPrice1*1.618+fiboPrice*(1-1.618), Digits)+str); 
  
   ObjectSet(nameObj,OBJPROP_FIRSTLEVEL+13,2.0);
   ObjectSetFiboDescription(nameObj, 13, "200.0 "+DoubleToStr(fiboPrice1*2.0+fiboPrice*(1-2.0), Digits)+str); 

   ObjectSet(nameObj,OBJPROP_FIRSTLEVEL+14,2.414);
   ObjectSetFiboDescription(nameObj, 14, "241.4 "+DoubleToStr(fiboPrice1*2.414+fiboPrice*(1-2.414), Digits)+str); 

   ObjectSet(nameObj,OBJPROP_FIRSTLEVEL+15,2.618);
   ObjectSetFiboDescription(nameObj, 15, "261.8 "+DoubleToStr(fiboPrice1*2.618+fiboPrice*(1-2.618), Digits)+str); 

   ObjectSet(nameObj,OBJPROP_FIRSTLEVEL+16,4.0);
   ObjectSetFiboDescription(nameObj, 16, "400.0 "+DoubleToStr(fiboPrice1*4.0+fiboPrice*(1-4.0), Digits)+str);
//----
   return(0);
  }
//--------------------------------------------------------

