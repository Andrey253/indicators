///// каждый раз сранивается предыдущая свеча с текущей, шагаем по i
// сравниваем H L
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_color1  MediumVioletRed
extern double t=2;
int     HLPeriod; 
int k,z,sr,sr2,cm,numex;
string simbols,str;
double Buf_2[],ht_turn[9],lt_turn[9],hmax, lmin,hl;
double h1[9],l1[9],h1t[9],l1t[9],h2[9],l2[9],h2t[9],l2t[9];
int init() {
   GlobalVariablesDeleteAll("ex");
   SetIndexStyle(0, DRAW_ARROW, 3,3);
   SetIndexBuffer(0, Buf_2);
   HLPeriod=GlobalVariableGet("HLPeriod");
   cm=GlobalVariableGet("cm");
   for (k=0;k<(HLPeriod-1);k++)
   {
   h1[k] = GlobalVariableGet("h1"+DoubleToStr(k,0));
   l1[k] = GlobalVariableGet("l1"+DoubleToStr(k,0));
   h2[k] = GlobalVariableGet("h2"+DoubleToStr(k,0));
   l2[k] = GlobalVariableGet("l2"+DoubleToStr(k,0));

   }  

str="                                             HLPeriod = "+HLPeriod+" HL \n";
   }
int start() {
    
int i, counted_bars=IndicatorCounted();
    i=Bars-counted_bars-10;
     Buf_2[cm]=High[cm]+20*Point;
while(i>0)
      {
// Логика поиска
   hmax=High[iHighest(NULL,0,MODE_HIGH,HLPeriod,i)];
   lmin=Low [iLowest (NULL,0,MODE_LOW, HLPeriod,i)];
   hl=hmax-lmin;
   //if (i== 26) Alert(hmax + " " + lmin);
   if (hl!=0)
for(z=0;z<(HLPeriod-1);z++)
         {
            h1t[z]=(High [i+z]- lmin)/hl;
            l1t[z]=(Low  [i+z]- lmin)/hl;
            h2t[z]=(High [i+z+1]- lmin)/hl;
            l2t[z]=(Low  [i+z+1]- lmin)/hl;

         }
for (k=0;k<HLPeriod;k++)
         {
         if (t/100 > MathAbs(h1[k]-h1t[k]))  sr++;
         if (t/100 > MathAbs(l1[k]-l1t[k]))  sr++;
         if (t/100 > MathAbs(h2[k]-h2t[k]))  sr++;
         if (t/100 > MathAbs(l2[k]-l2t[k]))  sr++;
         } //if (i==10)  Alert(sr);
for (k=0;k<HLPeriod;k++)
         {
         if (t/100 > MathAbs(h1[k]+l1t[k]))  sr2++;
         if (t/100 > MathAbs(l1[k]+h1t[k]))  sr2++;
         if (t/100 > MathAbs(h2[k]+l2t[k]))  sr2++;
         if (t/100 > MathAbs(l2[k]+h2t[k]))  sr2++;
         } 
// Логика поиска
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