///// каждый раз сранивается пред свеча с текущей, шагаем по i
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_color1  MediumVioletRed
extern double t=5;
int     HLPeriod;
int k,z,sr,sr2,cm,numex;
string simbols,str;
double Buf_2[],c[9],ct[9],ct_turn[9],lt_turn[9],hmax, lmin,co,hl, tail, body;
int init()
  {
   GlobalVariablesDeleteAll("ex");
   SetIndexStyle(0, DRAW_ARROW, 3,3);
   SetIndexBuffer(0, Buf_2);
   HLPeriod=GlobalVariableGet("HLPeriod");
   cm=GlobalVariableGet("cm");
   for(k=0; k<HLPeriod; k++)
     {
      c[k] = GlobalVariableGet("c"+DoubleToStr(k,0));
     }

   str="                                             HLPeriod = "+HLPeriod+" HL \n";
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start()
  {

   int i, counted_bars=IndicatorCounted();
   i=Bars-counted_bars-10;
   Buf_2[cm]=High[cm]+20*Point;
   while(i>0)
     {
      hl = High[i]-Low[i];
      co=Close[i]-Open[i] ;
      
      if(Close[i]>Open[i])
         {         
         tail = Open[i] - Low[i];
         body = Close[i] - Open[i];
         }
      else if (Close[i]-Open[i] != 0)
         {         
         tail = High[i] - Open[i];
         body = -Close[i] + Open[i];
         }


      if(tail/body > 3 && tail > 800*Point())
        {
         str=str+Symbol()+"["+i+"] \n";
         GlobalVariableSet("ex"+numex,i);
         numex++;

         Buf_2[i]=High[i]+50*Point();
        }
      i--;
     }
   Comment(str);
   return(0);
  }
//+------------------------------------------------------------------+
