///// каждый раз сранивается пред свеча с текущей, шагаем по i
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_color1  MediumVioletRed
extern double t=30;
int     HLPeriod; 
int k,z,sr,sr2,cm,numex;
string simbols,str;
double Buf_2[],h[9],l[9],ht[9],lt[9],ht_turn[9],lt_turn[9],hmax, lmin,hl;
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
         hl=High[i+z]-Low[i+z];
         if (hl!=0)
            {
            ht[z]=(Close [i+z]- Low[i+z])/hl;
            lt[z]=(Open  [i+z]- Low [i+z])/hl;
            lt_turn[z]=(High [i+z]- Close[i+z])/hl;
            ht_turn[z]=(High [i+z]- Open [i+z])/hl;

            } else continue;
         }
for (k=0;k<HLPeriod;k++)
         {
         if (t/100 > MathAbs(h[k]-ht[k]))  sr++;
         if (t/100 > MathAbs(l[k]-lt[k]))  sr++;
         } //if (i==10)  Alert(sr);
for (k=0;k<HLPeriod;k++)
         {
         if (t/100 > MathAbs(h[k]-lt_turn[k]))  sr2++;
         if (t/100 > MathAbs(l[k]-ht_turn[k]))  sr2++;
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