// последовательность типов свечей
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_color1  MediumVioletRed
extern int HLPeriod = 4;
color Col[4] = {clrMaroon, clrIndigo, clrLawnGreen,clrYellow};

int name_line, comb_count;

double Buf_2[],high, low;
int init()
  {
   GlobalVariablesDeleteAll("ex");
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

   Buf_2[1]=High[1]+20*Point;

   while(i>0)
     {
      low = Low [iHighest(NULL,0,MODE_LOW, HLPeriod,i)];
      high= High[iLowest(NULL,0,MODE_HIGH, HLPeriod,i)];

      if(low < high)
        {
         comb_count++;
         name_line++;
         if(comb_count == 3 && Low[i] > Low[i+1] && Low[i+1] > Low[i+2])
           {
            Line(IntegerToString(name_line), Time[i], high,Time[i+HLPeriod-1], high,Col[i % 4]);
            Line(IntegerToString(name_line+"2"), Time[i], low,Time[i+HLPeriod-1], low,Col[i % 4]);
           }
        }
      else
        {
         comb_count = 0;
        }

      i--;
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   return(0);
  }
//+------------------------------------------------------------------+
int deinit()
  {

   for(int z = 0 ; z <100000; z ++)
     {

      ObjectDelete(IntegerToString(z));
      ObjectDelete(IntegerToString(z)+"two");
     }
   return 0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Line(string name, datetime time1,double ext1,datetime time2,double ext2, color col)
  {
   ObjectCreate(name, OBJ_TREND, 0, time1, ext1, time2, ext2);
   ObjectSet(name,OBJPROP_COLOR,col);
   ObjectSet(name,OBJPROP_RAY,false);
   ObjectSet(name,OBJPROP_WIDTH,2);
  }
//+------------------------------------------------------------------+
