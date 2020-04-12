//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2018, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_color1  clrLawnGreen
#property indicator_color2  clrRed
#property indicator_color3  clrYellow
int i_begin, i_end, name_line, i2;
double high2, low2, high1, low1;

double low_forecast[2000], high_forecast[1000];

double Buf_3[],Buf_2[],Buf_1[];


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int init()
  {
   SetIndexStyle(0, DRAW_ARROW, 3,3);
   SetIndexBuffer(0, Buf_1);
   SetIndexStyle(1, DRAW_ARROW, 3,3);
   SetIndexBuffer(1, Buf_2);
   SetIndexStyle(2, DRAW_SECTION, EMPTY,2,clrRed);
   SetIndexBuffer(2, Buf_3);

  }
int start()
  {

   int i, counted_bars=IndicatorCounted();
   i=505-counted_bars;//6000;//
   
   while(i>=0)
     {

            low_forecast [i] = Close[i+1] - (High[i+1] + Low[i+1])/2 ;
            //high_forecast[i] = (Low [i+1] - Low [i+2])+high_forecast[i+1]  ;
            low_forecast [i] = low_forecast [i] + low_forecast [i+1];
            Buf_2[i] = low_forecast [i]+ Close [i+1];
            //Buf_1[i] = high_forecast[i]+ High[i+1];
     
     
  
      if(TimeMinute(Time[i-1])==0 && TimeHour(Time[i-1])==0)
        {
         name_line++;
         
         high2   = high1;
         low2    = low1;

         i_end   =i;
         
         high1 = High[iHighest(NULL,0,MODE_HIGH,i_begin-i-1,i)];
         low1  = Low [iLowest (NULL,0,MODE_LOW ,i_begin-i-1,i)];
         
         if ((i-1440/_Period)<0) i2 = 0;
         else  i2 = i-1440/_Period;

         Line(IntegerToString(name_line), Time[i-1], high1+low1-low2,Time[i2], high1+low1-low2,clrLime);
         Line(IntegerToString(name_line)+"two", Time[i-1], high1+low1-high2,Time[i2], high1+low1-high2,clrRed);
         i_begin = i+1;

         //if(i< 200)             Alert("1 - " +Buf_1[i-1]+" 2 - " +Buf_2[i-1]);

         //Comment("high1+low1-low2 =" + (high1+low1-low2)
         //        +"\n high1+low1-high2 = "+(high1+low1-high2)
         //        +"\n MathFloor( i/(1440/_Period) ) = "+MathFloor( i/(1440/_Period) )
         //        );
        }


      i--;
     }


   return(0);
  }
//+------------------------------------------------------------------+
int deinit(){

for (int z = 0 ; z <10000; z ++){

ObjectDelete(IntegerToString(z));
ObjectDelete(IntegerToString(z)+"two");
}
return 0;
}
void Line(string name, datetime time1,double ext1,datetime time2,double ext2, color col)
  {
   ObjectCreate(name, OBJ_TREND, 0, time1, ext1, time2, ext2); 
   ObjectSet(name,OBJPROP_COLOR,col);
   ObjectSet(name,OBJPROP_RAY,false);
   ObjectSet(name,OBJPROP_WIDTH,2);
  }