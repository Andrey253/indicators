// Макди сравниваем приращение с двух свечей
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_color1  clrCornflowerBlue
#property indicator_color2  clrRed
#property indicator_color3  clrLawnGreen
extern double t=3;
int     HLPeriod; 
int k, z, sr, sr2, cm, numex, sign;
string simbols, str;
double Buf_2[],Buf_1[],Buf_3[],h[9],l[9],c[9],o[9],ht[9],lt[9],ct[9],ot[9],hmax, lmin,hl;
int init() {
   GlobalVariablesDeleteAll("ex");
   SetIndexStyle(0, DRAW_ARROW, 3,3);
   SetIndexBuffer(0, Buf_1);
   SetIndexStyle(1, DRAW_ARROW, 3,3);
   SetIndexBuffer(1, Buf_2);
   SetIndexStyle(2, DRAW_ARROW, 3,3);
   SetIndexBuffer(2, Buf_3);
   HLPeriod=GlobalVariableGet("HLPeriod");
   cm = GlobalVariableGet("cm");
   sign = GlobalVariableGet("sign");
   for (k=0;k<HLPeriod;k++)
   {
   h[k] = GlobalVariableGet("h"+DoubleToStr(k,0));
   }  

str="                                             HLPeriod = "+HLPeriod+" HL \n";
   }
int start() {
    
int i, counted_bars=IndicatorCounted();
    i=Bars-counted_bars-10;
     Buf_3[cm]=High[cm]+200*Point;

while(i>0)
      {
hl = iRVI(NULL,0,10,MODE_MAIN,i+0)-iRVI(NULL,0,10,MODE_MAIN,i+1);
for(z=0;z<HLPeriod;z++)
         {
            if (hl != 0)ht[z]=(iRVI(NULL,0,10,MODE_MAIN,i+1+z)-iRVI(NULL,0,10,MODE_MAIN,i+z+2))/hl;
         }
for (k=0;k<HLPeriod;k++)
         {

         if (t/1000 > MathAbs(h[k]-ht[k]))  sr++;
         } 

if (sr==HLPeriod && hl >= 0) 
      { 
     // if (i==698) Alert(ht[z]," - ",lt[z]," --- ");
        str=str+Symbol()+"["+i+"] \n";
        GlobalVariableSet("ex"+numex,i);numex++;

        Buf_1[i]=High[i]+100*Point();
      }

if (sr==HLPeriod && hl < 0) 
      { 

        str=str+Symbol()+"["+i+"] turn \n";
        GlobalVariableSet("ex"+numex,i);numex++;

        Buf_2[i]=Low[i]-100*Point();
      }
      sr=0;

   i--;}
      Comment(str);
   return(0);
}