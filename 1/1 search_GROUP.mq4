///// каждый раз сранивается пред свеча с текущей, шагаем по i
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_color1  MediumVioletRed
extern double t=5;
int     HLPeriod; 
int k,z,sr,sr2,cm,numex;
string simbols,str;
double Buf_2[],h,l,ht_turn[20],lt_turn[20],hmax, lmin,hl;
double o[20],c[20],ot[20],ct[20];
int init() {
   GlobalVariablesDeleteAll("ex");
   SetIndexStyle(0, DRAW_ARROW, 3,3);
   SetIndexBuffer(0, Buf_2);
   HLPeriod=GlobalVariableGet("HLPeriod");
   cm=GlobalVariableGet("cm");
   for (k=0;k<HLPeriod;k++)
   {
   o[k] = GlobalVariableGet("o"+DoubleToStr(k,0));
   c[k] = GlobalVariableGet("c"+DoubleToStr(k,0));

   }  

str="                                             HLPeriod = "+HLPeriod+" HL \n";
   }
int start() {
    
int i, counted_bars=IndicatorCounted();
    i=Bars-counted_bars-10;
     Buf_2[cm]=High[cm]+20*Point;
while(i>0)
      {

for(z=0;z<HLPeriod;z++)
         {
         h = High[iHighest(NULL,0,MODE_HIGH,z+1,i)];
         l = Low [iLowest (NULL,0,MODE_LOW ,z+1,i)];
         hl=h-l ;
         if (hl!=0)
            {
            ot[z]=(Open [i+z]- l)/hl;
            ct[z]=(Close[i+0]- l)/hl;
;
          //  lt_turn[z]=(High [i+z]- High[i+z+1])/hl;
           // ht_turn[z]=(Low  [i+z]- Low [i+z+1])/hl;

            } else continue;
         }
for (k=0;k<HLPeriod;k++)
         {
         if (t/100 > MathAbs(o[k]-ot[k]))  sr++;
         if (t/100 > MathAbs(c[k]-ct[k]))  sr++;

         } //if (i==10)  Alert(sr);
for (k=0;k<HLPeriod;k++)
         {
         if (t/100 > MathAbs(o[k]+ot[k]))  sr2++;
         if (t/100 > MathAbs(c[k]+ct[k]))  sr2++;

         } //if (i==10)  Alert(sr);
         //////////////////////////////
if (sr==HLPeriod*2) 
      {  //if (i==115) for (k=0;k<HLPeriod;k++){ Alert(ht[k],"- ",h[k],"---- ",lt[k],"- ",l[k]);}
     // if (i==698) Alert(ht[z]," - ",lt[z]," --- ");
        str=str+Symbol()+"["+i+"] \n";
        GlobalVariableSet("ex"+numex,i);numex++;

        Buf_2[i]=High[i]+50*Point();
      }
      sr=0;
      /////////////////////////////////
if (sr2==HLPeriod*2) 
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