//+------------------------------------------------------------------+
//|                                            Bheurekso_pattern.mq4 |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Nikelodeon & Tor"
#property strict
#property version "2.0"

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 clrLime
#property indicator_color2 clrRed
//---- input parameters
input bool       lines=true;  // Построение линий
input int        step=500;    // Глубина просмотра истории
input bool       Dell=true;   // Каждый раз стирать и строить линии по новой
input bool       AlertEnbl = true; // Вкл/Выкл. всех оповещений
input bool       BullHaramiAlert = true;  // Бычий Харами
input bool       BullCrossAlert = true;   // Бычья Проникающая линия
input bool       BullEngulfAlert = true;  // Бычье Поглощение
input bool       BullPierceAlert = true;  // Бычий Просвет облаков
input bool       MorningStarAlert = true; // Бычья Утреняя Звезда
input bool       HammerAlert = true;      // Бычий Молот
input bool       BearHaramiAlert = true;  // Медвежий Харами
input bool       BearCrossAlert = true;   // Медвежья Проникающая линия
input bool       BearEngulfAlert = true;  // Медвежий Повешенный
input bool       Hammer2Alert = true;     // Медвежье Поглощение
input bool       DarkCloudAlert = true;   // Медвежьи Темные облака
input bool       EveningStarAlert = true; // Медвежья Вечерняя звезда
input bool       ShooterAlert = true;     // Медвежья Падающая звезда

input color clrLines = clrBlack;// Color Lines and Text
input color clrBuy = clrBlue;// Color BUY
input color clrSell = clrRed;// Color SELL

//----buffers
double ExtMapBuffer1[];
double ExtMapBuffer2[];
static datetime lastAlert = Time[0];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
   SetIndexStyle(0,DRAW_ARROW);
   SetIndexArrow(0,108);
   SetIndexBuffer(0,ExtMapBuffer1);
   SetIndexEmptyValue(0,0.0);
   SetIndexStyle(1,DRAW_ARROW);
   SetIndexArrow(1,108);
   SetIndexBuffer(1,ExtMapBuffer2);
   SetIndexEmptyValue(1,0.0);
//----
   ObjectsDeleteAll(0,OBJ_TEXT);
   ObjectsDeleteAll(0,OBJ_ARROW);
//ObjectsDeleteAll(0,OBJ_TREND);
   for(int i=1; i<50; i++)
     {
      ObjectDelete("-"+(string)i);
      ObjectDelete("+"+(string)i);
     }
   return(0);

  }
//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   ObjectsDeleteAll(0,OBJ_TEXT);
   ObjectsDeleteAll(0,OBJ_ARROW);
//ObjectsDeleteAll(0,OBJ_TREND);
   for(int i=1; i<50; i++)
     {
      ObjectDelete("-"+(string)i);
      ObjectDelete("+"+(string)i);
     }
//----
   return(0);
  }

//+------------------------------------------------------------------+
//SetArrow(t[shift1],l[shift1]-15*Point,241,LIME);
void SetArrow(int sh, datetime tm, double pr, int cod,color clr)
  {
   ObjectCreate("Arrow-"+(string)sh,OBJ_ARROW,0,tm,pr);
   ObjectSet("Arrow-"+(string)sh,OBJPROP_ARROWCODE,cod);
   ObjectSet("Arrow-"+(string)sh,OBJPROP_COLOR,clr);
  }
void SetArrow1(int sh, datetime tm, double pr, int cod,color clr)
  {
   ObjectCreate("Arrow+"+(string)sh,OBJ_ARROW,0,tm,pr);
   ObjectSet("Arrow+"+(string)sh,OBJPROP_ARROWCODE,cod);
   ObjectSet("Arrow+"+(string)sh,OBJPROP_COLOR,clr);
  }

//SetText(t[shift1],l[shift1]-28*Point,"Engulfing",LIME);
void SetText(int sh,datetime tm,double pr,string text,color clr)
  {
   ObjectCreate("x"+(string)sh,OBJ_TEXT,0,tm,pr);
   ObjectSetText("x"+(string)sh,text);
   ObjectSet("x"+(string)sh,OBJPROP_COLOR,clr);
  }
void SetText1(int sh,datetime tm,double pr,string text,color clr)
  {
   ObjectCreate("y"+(string)sh,OBJ_TEXT,0,tm,pr);
   ObjectSetText("y"+(string)sh,text);
   ObjectSet("y"+(string)sh,OBJPROP_COLOR,clr);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Setline(int sh,datetime tm,double pr,datetime tm1,double pr1, color clr)
  {
   ObjectCreate("-"+(string)sh,OBJ_TREND,0,tm,pr,tm1,pr1,clr);
   ObjectSet("-"+(string)sh,7,STYLE_SOLID);
   ObjectSet("-"+(string)sh,10,false);
   ObjectSet("-"+(string)sh,6,clr);
  }
void Setline1(int sh,datetime tm,double pr,datetime tm1,double pr1, color clr)
  {
   ObjectCreate("+"+(string)sh,OBJ_TREND,0,tm,pr,tm1,pr1,clr);
   ObjectSet("+"+(string)sh,7,STYLE_SOLID);
   ObjectSet("+"+(string)sh,10,false);
   ObjectSet("+"+(string)sh,6,clr);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   int    counted_bars=IndicatorCounted();
//----
   int myBars=0, StartBar=0;//, Kedip(false);
   int shift=0, shift1=0, shift2=0, shift3=0;
   bool BullEngulf=False, MorningStar=False, BullPierce=False, Hammer=False,Name=false,Arrow=false;
   bool BearEngulf=False, EveningStar=False, DarkCloud=False, Shooter=False,Name1=false,Arrow1=false;
   bool BullHarami=False, BearHarami=false, BullCross=false, BearCross=false,up=false,down=false;
   int limit=0,n=0,a=0,b=0,x=0,doji=false;
   double  l[1000],h[1000];
   ArrayInitialize(l,0);
   ArrayInitialize(h,0);

   int p3[100],x1[100];
   p3[1]=0;
   if(myBars!=Bars)
     {
      myBars=Bars;
     }
   limit=step;//Bars-counted_bars;
   for(shift=limit; shift>=0; shift--)
     {
      // Manjakan MT
      shift1=shift+1;
      shift2=shift+2;
      shift3=shift+3;

      //*** periksa pola bullish***
      //***************************
      //Определение рыночнои? тенденции
      //В НШ можно отфильтровать для прогноза будущее? на время
      if((iMA(NULL,0,5,0,MODE_EMA,PRICE_CLOSE,shift)>iMA(NULL,0,5,0,MODE_EMA,PRICE_CLOSE,shift1)) &&
         (iMA(NULL,0,5,0,MODE_EMA,PRICE_CLOSE,shift1)>iMA(NULL,0,5,0,MODE_EMA,PRICE_CLOSE,shift2)) &&
         (iMA(NULL,0,5,0,MODE_EMA,PRICE_CLOSE,shift2)>iMA(NULL,0,5,0,MODE_EMA,PRICE_CLOSE,shift3)))
         up=true;
      else
         up=false;
      if((iMA(NULL,0,5,0,MODE_EMA,PRICE_CLOSE,shift)<iMA(NULL,0,5,0,MODE_EMA,PRICE_CLOSE,shift1)) &&
         (iMA(NULL,0,5,0,MODE_EMA,PRICE_CLOSE,shift1)<iMA(NULL,0,5,0,MODE_EMA,PRICE_CLOSE,shift2)) &&
         (iMA(NULL,0,5,0,MODE_EMA,PRICE_CLOSE,shift2)<iMA(NULL,0,5,0,MODE_EMA,PRICE_CLOSE,shift3)))
         down=true;
      else
         down=false;

      //Определение периода
      if(5==Period())
        {
         a=15;
         b=5;
        }
      if(15==Period())
        {
         a=7;
         b=3;
        }
      if(60==Period())
        {
         a=25;
         b=15;
        }
      if(240==Period())
        {
         a=30;
         b=20;
        }
      if(1440==Period())
        {
         a=35;
         b=25;
        }

      //Выявления всех моделеи?
      //Харами Вверх
      if((down)&&(Open[shift2]>Close[shift2]) && (Open[shift1]>Close[shift2]) && (Close[shift1]<Open[shift2]) &&
         (Close[shift1]>Open[shift1]))
         BullHarami=true;
      else
         BullHarami=false;

      //Проникающие линии бычков

      if((Open[shift2]>Close[shift2]) && (Open[shift1]>Close[shift2])&& (Open[shift1]<Open[shift2])&& (Close[shift1]>Open[shift2]))
         BullCross=true;
      else
         BullCross=false;

      //--- Bullish Engulfing (2 bars)
      if((Close[shift2]<Open[shift2]) && (Open[shift1]<Close[shift2]) && //| l[shift1] < l[shift2]) &
         (Close[shift1]>Open[shift2]))
         BullEngulf=True;
      else
         BullEngulf=False;

      //--- Bullish Piercing (2 bars) cuma cari kalo ga ada BullEngulf
      if(!BullEngulf)
        {
         if((Close[shift2]<Open[shift2]) && (Close[shift1]>Open[shift1]) &&
            ((Open[shift1]<Close[shift2]) /*|| (Low[shift1]<Low[shift2])*/) &&
            (Close[shift1]>Close[shift2]+((Open[shift2]-Close[shift2])/2)))
            BullPierce=True;
         else
            BullPierce=False;
        }
      else
        {
         BullPierce=False;
        }

      // Morning Star (3 bars)
      if((Close[shift3]<Open[shift3]) && (Open[shift2]<Close[shift3]) && (Close[shift2]<Close[shift3]) &&
         ((Open[shift1]>Close[shift2]) && (Open[shift1]>Open[shift2])) && (Close[shift1]>=Close[shift3]))
         MorningStar=True;
      else
         MorningStar=False;

      // Hammer
      if((Open[shift1]-Low[shift1]>MathMax(High[shift1]-Close[shift1],Close[shift1]-Open[shift1])*3) &&
         (Close[shift1]-Low[shift1]>MathMax(High[shift1]-Close[shift1],Close[shift1]-Open[shift1])*3))
         Hammer=True;
      else
         Hammer=False;

      //*** periksa pola bearish***
      //***************************
      //Харами Вниз
      if((up)&&(Open[shift2]<Close[shift2]) && (Open[shift1]<Close[shift2]) && (Close[shift1]>Open[shift2]) &&
         (Close[shift1]<Open[shift1]))
         BearHarami=true;
      else
         BearHarami=false;

      //Проникающие линии медвежат

      if((Open[shift2]<Close[shift2]) && (Open[shift1]<Close[shift2])&&(Open[shift1]>Open[shift2])&& (Close[shift1]<Open[shift2]))
         BearCross=true;
      else
         BearCross=false;


      //--- Bearish Engulfing (2 bars)
      if((Close[shift2]>Open[shift2]) && (Close[shift1]<Open[shift1]) && (Open[shift1]>Close[shift2]) &&
         ((Close[shift1]<Open[shift2])))
         BearEngulf=True;
      else
         BearEngulf=False;

      //--- Bearish Dark Cloud (2 bars) cuma cari kalo ga ada BearEngulf
      if(!BearEngulf)
        {
         if((Close[shift2]>Open[shift2]) && ((Open[shift1]>Close[shift2]) /*|| (High[shift1]>High[shift2]*/) &&
            (Close[shift1]<Close[shift2]-((Close[shift2]-Open[shift2])/2)))
            DarkCloud=True;
         else
            DarkCloud=False;
        }
      else
        {
         DarkCloud=False;
        }

      // Evening Star (3 bars)
      if((Close[shift3]>Open[shift3]) && (Open[shift2]>Close[shift3]) && (Close[shift2]>Close[shift3]) &&
         ((Open[shift1]<Close[shift2]) && (Open[shift1]<Open[shift2])) && (Close[shift1]<Close[shift3]))
         EveningStar=True;
      else
         EveningStar=False;

      // Shooting Star
      if((up)&&(High[shift1]-Open[shift1]>MathMax(Close[shift1]-Low[shift1],Open[shift1]-Close[shift1])*3)&&
         (High[shift1]-Close[shift1]>MathMax(Close[shift1]-Low[shift1],Open[shift1]-Close[shift1])*3))
         Shooter=True;
      else
         Shooter=False;

      //подтверждение
      if((BullEngulf || BullPierce || MorningStar || BullHarami || BullCross) &&
         (Close[shift]>Close[shift1])&& Close[shift]>Open[shift1])
        {
         //       ExtMapBuffer1[shift] = Low[shift]-7*Point;
         Name=true;
         Arrow=true;
        }
      else
        {ExtMapBuffer1[shift] = 0.0; Name=false; Arrow=false; }

      if((BearEngulf || DarkCloud || EveningStar || Shooter || BearHarami || BearCross) &&
         (Close[shift]<Close[shift1])&& Close[shift]<Open[shift1])
        {
         //       ExtMapBuffer2[shift] = High[shift]+7*Point;
         Name1=true;
         Arrow1=true;
        }
      else
        {ExtMapBuffer2[shift] = 0.0; Name1=false; Arrow1=false;}

      //Подтверждение молота отдельно

      if(Hammer)
        {
         if((down))
           {
            Name=true;
            Arrow=true;
           }
         //                        ExtMapBuffer1[shift] = Low[shift]-7*Point;}
         else
           {
            Name=false;
            Arrow=false;
           }
         if((up))
           {
            Name1=true;
            Arrow1=true;
           }

         //                ExtMapBuffer2[shift] = High[shift]+7*Point;}
         else
           {
            Name1=false;
            Arrow1=false;
           }
        }



      // Вывод свечных моделеи? на экран
      // Модели быков
      if(BullHarami && BullHaramiAlert)
        {
         if(Name)
           {
            n++;
            l[n]=Low[shift1];
            Setline(n,Time[shift1],l[n],Time[shift],l[n],clrLines);
            Alerts(Time[shift], _Symbol+" Харами (Восходящий Тренд)");
            SetText(n,Time[shift1],Low[shift1]-a*Point,"Харами (Восходящий Тренд)",clrLines);
           }
         if(Arrow)
            SetArrow(n,Time[shift1],Low[shift1]-b*Point,241,clrBuy);
        }

      if(BullCross && BullCrossAlert)
        {
         if(Name)
           {
            n++;
            SetText(n,Time[shift1],Low[shift1]-a*Point,"Проникающая линия (Разворот тренда, Вход на покупку)",clrLines);
            Alerts(Time[shift], _Symbol+" Проникающая линия (Разворот тренда, Вход на покупку)");

            l[n]=Low[shift1];
            Setline(n,Time[shift1],l[n],Time[shift],l[n],clrLines);
           }

         if(Arrow)
            SetArrow(n,Time[shift1],Low[shift1]-b*Point,241,clrBuy);
        }


      if(BullEngulf && BullEngulfAlert)
        {
         if(Name)
           {
            n++;
            l[n]=Low[shift1];
            Setline(n,Time[shift1],l[n],Time[shift],l[n],clrLines);
            Alerts(Time[shift], _Symbol+" Поглощение (Резкое изменение курса, Вход на покупку)");
            SetText(n,Time[shift1],Low[shift1]-a*Point,"Поглощение (Резкое изменение курса, Вход на покупку)",clrLines);
           }
         if(Arrow)
            SetArrow(n,Time[shift1],Low[shift1]-b*Point,241,clrBuy);
        }
      if(BullPierce && BullPierceAlert)
        {
         if(Name)
           {
            n++;
            l[n]=Low[shift1];
            Setline(n,Time[shift1],l[n],Time[shift],l[n],clrLines);
            Alerts(Time[shift], _Symbol+" Просвет облаков (Разворот тренда на восходящий)");
            SetText(n,Time[shift1],Low[shift1]-a*Point,"Просвет облаков (Разворот тренда на восходящий)",clrLines);
           }
         if(Arrow)
            SetArrow(n,Time[shift1],Low[shift1]-b*Point,241,clrBuy);
        }


      if(MorningStar && MorningStarAlert)
        {
         if(Name)
           {
            n++;
            SetText(n,Time[shift2],Low[shift2]-a*Point,"Утреняя Звезда (Сильный сигнал нижнего разворота)",clrLines);
            Alerts(Time[shift], _Symbol+" Утреняя Звезда (Сильный сигнал нижнего разворота)");
            l[n]=Low[shift2];
            Setline(n,Time[shift2],l[n],Time[shift],l[n],clrLines);
           }

         if(Arrow)
            SetArrow(n,Time[shift2],Low[shift2]-b*Point,241,clrBuy);
        }


      if(Hammer && HammerAlert)
        {
         if(Name)
           {
            n++;
            SetText(n,Time[shift1],Low[shift1]-a*Point,"Молот (Возможен разворот тренда на восходящий)",clrLines);
            Alerts(Time[shift], _Symbol+" Молот (Возможен разворот тренда на восходящий)");
            l[n]=Low[shift1];
            Setline(n,Time[shift1],l[n],Time[shift],l[n],clrLines);
           }

         if(Arrow)
            SetArrow(n,Time[shift1],Low[shift1]-b*Point,241,clrBuy);
        }
      ///
      ////////////////////////////////////////////////////////////////////////////////////
      //

      //модели медведеи?
      if(BearHarami && BearHaramiAlert)
        {
         if(Name1)
           {
            x++;
            h[x]=High[shift1];
            Setline1(x,Time[shift1],h[x],Time[shift],h[x],clrLines);

            SetText1(x,Time[shift1],High[shift1]+(15+a)*Point,"Харами (Нисходящий Тренд)",clrLines);
            Alerts(Time[shift], _Symbol+" Харами (Нисходящий Тренд)");
           }
         if(Arrow1)
            SetArrow1(x,Time[shift1],High[shift1]+(10+b)*Point,242,clrSell);
        }

      if(BearCross && BearCrossAlert)
        {
         if(Name1)
           {
            x++;
            SetText1(x,Time[shift1],High[shift1]+(15+a)*Point,"Проникающая линия (Разворот тренда, Вход на продажу)",clrLines);
            Alerts(Time[shift], _Symbol+" Проникающая линия (Разворот тренда, Вход на продажу)");
            h[x]=High[shift1];
            Setline1(x,Time[shift1],h[x],Time[shift],h[x],clrLines);
           }

         if(Arrow1)
            SetArrow1(x,Time[shift1],High[shift1]+(10+b)*Point,242,clrSell);
        }


      if(Hammer && Hammer2Alert)
        {
         if(Name1)
           {
            x++;
            Alerts(Time[shift], _Symbol+" Повешенный? (Попытка изменить тренд, закрыть все длинные позиции)");
            SetText1(x,Time[shift1],High[shift1]+(15+a)*Point,"Повешенный? (Попытка изменить тренд, закрыть все длинные позиции)",clrLines);

            h[x]=High[shift1];
            Setline1(x,Time[shift1],h[x],Time[shift],h[x],clrLines);
           }
         if(Arrow1)
            SetArrow1(x,Time[shift1],High[shift1]+(10+b)*Point,242,clrSell);
        }


      if(BearEngulf && BearEngulfAlert)
        {
         if(Name1)
           {
            x++;
            h[x]=High[shift1];
            Setline1(x,Time[shift1],h[x],Time[shift],h[x],clrLines);
            Alerts(Time[shift], _Symbol+" Поглощение (Резкое изменение курса, Вход на продажу)");

            SetText1(x,Time[shift1],High[shift1]+(15+a)*Point,"Поглощение (Резкое изменение курса, Вход на продажу)",clrLines);
           }
         if(Arrow1)
            SetArrow1(x,Time[shift1],High[shift1]+(10+b)*Point,242,clrSell);
        }

      if(DarkCloud && DarkCloudAlert)
        {
         if(Name1)
           {
            x++;
            h[x]=High[shift1];
            Setline1(x,Time[shift1],h[x],Time[shift],h[x],clrLines);
            Alerts(Time[shift], _Symbol+" Темные облака (Разворот тренда на нисходящий)");

            SetText1(x,Time[shift1],High[shift1]+(15+a)*Point,"Темные облака (Разворот тренда на нисходящий)",clrLines);
           }
         if(Arrow1)
            SetArrow1(x,Time[shift1],High[shift1]+(10+b)*Point,242,clrSell);
        }


      if(EveningStar && EveningStarAlert)
        {
         if(Name1)
           {
            x++;
            h[x]=High[shift2];
            Setline1(x,Time[shift2],h[x],Time[shift],h[x],clrLines);

            Alerts(Time[shift], _Symbol+" Вечерняя звезда (Сильный сигнал верхнего разворота)");
            SetText1(x,Time[shift2],High[shift2]+(15+a)*Point,"Вечерняя звезда (Сильный сигнал верхнего разворота)",clrLines);
           }
         if(Arrow1)
            SetArrow1(x,Time[shift2],High[shift2]+(10+b)*Point,242,clrSell);
        }

      if(Shooter && ShooterAlert)
        {
         if(Name1)
           {
            x++;
            SetText1(x,Time[shift1],High[shift1]+(15+a)*Point,"Падающая звезда (Возможно окончание роста цен)",clrLines);
            Alerts(Time[shift], _Symbol+" Падающая звезда (Возможно окончание роста цен)");

            h[x]=High[shift1];
            Setline1(x,Time[shift1],h[x],Time[shift],h[x],clrLines);
           }

         if(Arrow1)
            SetArrow1(x,Time[shift1],High[shift1]+(10+b)*Point,242,clrSell);
        }

      //Рисование линии? поддержки и сопротивления
      if(lines)
        {
         ObjectMove("-"+(string)n, 1,Time[1],l[n]);
         ObjectMove("+"+(string)x, 1,Time[1],h[x]);
         for(int i=1; i<50; i++)
           {
            if(Close[shift]<l[i])
              {
               ObjectSet("-"+(string)i,6,DarkBlue);
               ObjectSet("-"+(string)i,7,STYLE_DASHDOT);
               ObjectSet("x"+(string)i,OBJPROP_COLOR,DarkBlue);
               ObjectSet("Arrow-"+(string)i,OBJPROP_COLOR,DarkBlue);
               if(Dell)
                 {
                  ObjectDelete("-"+(string)i);
                  ObjectDelete("x"+(string)i);
                  ObjectDelete("Arrow-"+(string)i);
                 }
              }

           }
         for(int q=1; q<50; q++)
           {

            if(Close[shift]>h[q])
              {
               ObjectSet("+"+(string)q,6,Black);
               ObjectSet("+"+(string)q,7,STYLE_DASHDOT);
               ObjectSet("y"+(string)q,OBJPROP_COLOR,Black);
               ObjectSet("Arrow+"+(string)q,OBJPROP_COLOR,Black);
               if(Dell)
                 {
                  ObjectDelete("+"+(string)q);
                  ObjectDelete("y"+(string)q);
                  ObjectDelete("Arrow+"+(string)q);
                 }
              }


           }

        }  // Tampilkan disaat ada konfirmasi.

      StartBar-=1;
     }


//----
   return(0);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Alerts(datetime tm, string txt="")
  {
   if(AlertEnbl && lastAlert<Time[0] && tm>lastAlert)
     {
      Alert(txt);
      lastAlert = Time[0];
     }

   return;
  }






//+------------------------------------------------------------------+
