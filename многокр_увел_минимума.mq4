//если минимум последующей свечи растет, то считаем количество свечей в которых эта тенденция есть
//
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_color1  MediumVioletRed

extern int     HLPeriod = 8;
int count;

double Buf_2[],low,hi,last_max;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int init()
  {
   SetIndexStyle(0, DRAW_ARROW, 3,3);
   SetIndexBuffer(0, Buf_2);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start()
  {

   int i, counted_bars=IndicatorCounted();
   i=Bars-counted_bars-10;
   Buf_2[2]=High[2]+20*Point;
   while(i>0)
     {
      // Логика поиска
      if(count>12)
         count = 0;
      if(High[i] > hi)
        {
         hi = High[i];
         count = 0;
         last_max = High[i];
        }
      else
         if(last_max > High[i])
           {
            last_max = High[i];
            count++;
           }

      // Логика поиска
      if(count >= 8)
        {
         Buf_2[i]=High[i]+50*Point();
        }

      /////////////////////////////////
      i--;
     }

   return(0);
  }
//+------------------------------------------------------------------+
