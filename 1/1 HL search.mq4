#property indicator_chart_window
#property indicator_buffers 1
#property indicator_color1  MediumVioletRed
extern double t=50;
extern int     HLPeriod =  7; 
int k,z,sr,cm;
string simbols,str;
double Buf_2[],h[9],l[9],ht[9],lt[9],hmax, lmin,hl;
int init() {
   SetIndexStyle(0, DRAW_ARROW, 3,3);
   SetIndexBuffer(0, Buf_2);
  // HLPeriod=GlobalVariableGet("HLPeriod");
   cm=GlobalVariableGet("cm");
   for (k=0;k<HLPeriod;k++)
   {
   h[k] = GlobalVariableGet("h"+DoubleToStr(k,0))/Point();
   l[k] = GlobalVariableGet("l"+DoubleToStr(k,0))/Point();
   }  

// Alert(h[0]," -  ",l[0]," - ",h[1],"  - ",l[1]," - ",h[2]," - ",l[2]);
   }
int start() {
    str="                                             HLPeriod = "+HLPeriod+" HL \n";
int i, counted_bars=IndicatorCounted();
    i=Bars-counted_bars-10;
     Buf_2[cm]=High[cm]+20*Point;
while(i>0)
      {
   hmax=High[iHighest(NULL,0,MODE_HIGH,HLPeriod,i)];
   lmin=Low [iLowest (NULL,0,MODE_LOW, HLPeriod,i)];
   hl=hmax-lmin;
   if ((hl)!=0)
for(z=0;z<HLPeriod;z++)
         {
         ht[z]=(High [i+z]-lmin)/hl/Point();
         lt[z]=(Low  [i+z]-lmin)/hl/Point();//if (i==115) Alert(ht[z]," - ",lt[z]," --- ");
         }
for (k=0;k<HLPeriod;k++)
         {
         if (t*100 > MathAbs(h[k]-ht[k]))  sr++;
         if (t*100 > MathAbs(l[k]-lt[k]))  sr++;
         } //if (i==10)  Alert(sr);
if (sr==HLPeriod*2) 
      {  //if (i==115) for (k=0;k<HLPeriod;k++){ Alert(ht[k],"- ",h[k],"---- ",lt[k],"- ",l[k]);}
     // if (i==698) Alert(ht[z]," - ",lt[z]," --- ");
        str=str+Symbol()+"["+i+"] \n";
        Buf_2[i]=High[i]+50*Point();
      }
      sr=0;
   i--;}
      Comment(str);
   return(0);
}