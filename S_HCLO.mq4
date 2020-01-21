#property indicator_chart_window
#property indicator_buffers 1
#property indicator_color1  MediumVioletRed
extern double t=30;
int     HLPeriod; 
int k,z,sr,sr2,cm,numex;
string simbols,str;
double Buf_2[],h[9],l[9],c[9],o[9],ht[9],lt[9],ct[9],ot[9],hmax, lmin,hl;
int init() {
   GlobalVariablesDeleteAll("ex");
   SetIndexStyle(0, DRAW_ARROW, 3,3);
   SetIndexBuffer(0, Buf_2);
   HLPeriod=GlobalVariableGet("HLPeriod");
   cm=GlobalVariableGet("cm");
   for (k=0;k<HLPeriod;k++)
   {
   h[k] = GlobalVariableGet("h"+DoubleToStr(k,0));
   l[k] = GlobalVariableGet("l"+DoubleToStr(k,0));
   c[k] = GlobalVariableGet("c"+DoubleToStr(k,0));
   o[k] = GlobalVariableGet("o"+DoubleToStr(k,0));

   }  

str="                                             HLPeriod = "+HLPeriod+" HL \n";
   }
int start() {
    
int i, counted_bars=IndicatorCounted();
    i=Bars-counted_bars-10;
     Buf_2[1]=High[1]+20*Point;
while(i>0)
      {

   hmax=High[iHighest(NULL,0,MODE_HIGH,HLPeriod,i)];
   lmin=Low [iLowest (NULL,0,MODE_LOW, HLPeriod,i)];
   hl=hmax-lmin;
   //if (i== 26) Alert(hmax + " " + lmin);
   if (hl!=0)
      {for(z=0;z<HLPeriod;z++)
         {
            ht[z]=(High [i+z]-lmin)/hl;
            lt[z]=(Low  [i+z]-lmin)/hl;
            ct[z]=(Close[i+z]-lmin)/hl;
            ot[z]=(Open [i+z]-lmin)/hl;

            } 
         }
for (k=0;k<HLPeriod;k++)
         {
         if (t/100 > MathAbs(h[k]-ht[k]))  sr++;
         if (t/100 > MathAbs(l[k]-lt[k]))  sr++;
         if (t/100 > MathAbs(c[k]-ct[k]))  sr++;
         if (t/100 > MathAbs(o[k]-ot[k]))  sr++;         
         } 
for (k=0;k<HLPeriod;k++)
         {
         if (t/100 > MathAbs(h[k]+lt[k]))  sr2++;
         if (t/100 > MathAbs(l[k]+ht[k]))  sr2++;
         if (t/100 > MathAbs(c[k]+ct[k]))  sr2++;
         if (t/100 > MathAbs(o[k]+ot[k]))  sr2++;         
         } //if (i==10)  Alert(sr);
         //////////////////////////////
if (sr==HLPeriod*4) 
      {  //if (i==115) for (k=0;k<HLPeriod;k++){ Alert(ht[k],"- ",h[k],"---- ",lt[k],"- ",l[k]);}
     // if (i==698) Alert(ht[z]," - ",lt[z]," --- ");
        str=str+Symbol()+"["+i+"] \n";
        GlobalVariableSet("ex"+numex,i);numex++;

        Buf_2[i]=High[i]+50*Point();
        //str = str + " " + lmin+" " +hmax+" ";
      }
      sr=0;
      /////////////////////////////////
if (sr2==HLPeriod*4) 
      {  //if (i==115) for (k=0;k<HLPeriod;k++){ Alert(ht[k],"- ",h[k],"---- ",lt[k],"- ",l[k]);}
     // if (i==698) Alert(ht[z]," - ",lt[z]," --- ");
        str=str+Symbol()+"["+i+"] turn \n";
        GlobalVariableSet("ex"+numex,i);numex++;

        Buf_2[i]=Low[i]-50*Point();
      }
      sr2=0;
      ///////////////////////////////
   i--;}
      Comment(str);
   return(0);
}