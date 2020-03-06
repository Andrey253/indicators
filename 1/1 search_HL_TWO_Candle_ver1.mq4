///// каждый раз сранивается пред свеча с текущей, шагаем по i
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_color1  MediumVioletRed
extern double t=30;
int     HLPeriod; 
int k,z,sr,sr2,cm,numex;
string simbols,str;
double Buf_2[],h,l,ht_turn[9],lt_turn[9],hmax, lmin,hl;
double h0t[9],l0t[9],h1t[9],l1t[9],h0[9],l0[9],h1[9],l1[9];
int init() {
   GlobalVariablesDeleteAll("ex");
   SetIndexStyle(0, DRAW_ARROW, 3,3);
   SetIndexBuffer(0, Buf_2);
   HLPeriod=GlobalVariableGet("HLPeriod");
   cm=GlobalVariableGet("cm");
   for (k=0;k<HLPeriod;k++)
   {
   h0[k] = GlobalVariableGet("h0"+DoubleToStr(k,0));
   l0[k] = GlobalVariableGet("l0"+DoubleToStr(k,0));
   h1[k] = GlobalVariableGet("h1"+DoubleToStr(k,0));
   l1[k] = GlobalVariableGet("l1"+DoubleToStr(k,0));

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
         h = High[iHighest(NULL,0,MODE_HIGH,1,i+z)];
         l = Low [iLowest (NULL,0,MODE_LOW ,1,i+z)];
         hl=h-l ;
         if (hl!=0)
            {
            h0t[z]=(High [i+z]- l)/hl;
            l0t[z]=(Low  [i+z]- l)/hl;
            h1t[z]=(High [i+z+1]- l)/hl;
            l1t[z]=(Low  [i+z+1]- l)/hl;
          //  lt_turn[z]=(High [i+z]- High[i+z+1])/hl;
           // ht_turn[z]=(Low  [i+z]- Low [i+z+1])/hl;

            } else continue;
         }
for (k=0;k<HLPeriod;k++)
         {
         if (t/100 > MathAbs(h0[k]-h0t[k]))  sr++;
         if (t/100 > MathAbs(l0[k]-l0t[k]))  sr++;
         if (t/100 > MathAbs(h1[k]-h1t[k]))  sr++;
         if (t/100 > MathAbs(l1[k]-l1t[k]))  sr++;
         } //if (i==10)  Alert(sr);
for (k=0;k<HLPeriod;k++)
         {
         if (t/100 > MathAbs(h0[k]+h0t[k]))  sr2++;
         if (t/100 > MathAbs(l0[k]+l0t[k]))  sr2++;
         if (t/100 > MathAbs(h1[k]+h1t[k]))  sr2++;
         if (t/100 > MathAbs(l1[k]+l1t[k]))  sr2++;
         } //if (i==10)  Alert(sr);
         //////////////////////////////
if (sr==HLPeriod*4) 
      {  //if (i==115) for (k=0;k<HLPeriod;k++){ Alert(ht[k],"- ",h[k],"---- ",lt[k],"- ",l[k]);}
     // if (i==698) Alert(ht[z]," - ",lt[z]," --- ");
        str=str+Symbol()+"["+i+"] \n";
        GlobalVariableSet("ex"+numex,i);numex++;

        Buf_2[i]=High[i]+50*Point();
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