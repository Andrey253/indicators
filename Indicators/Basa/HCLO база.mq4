#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1  MediumVioletRed
extern double t=30;
int     HLPeriod; 
int k,z,sr,sr2,cm,numex;
string simbols,str;
double Buf_2[],Buf_1[],h[9],l[9],c[9],o[9],ht[9],lt[9],ct[9],ot[9],hmax, lmin,hl;
double ht_rev[9],lt_rev[9],ct_rev[9],ot_rev[9];

double position[][4] = {{1,0,0.98189563,0.39084132},{1,0,0.07317073,0.95121951}};
string position_value[] = {" Вверх идем"," Отыгрываем 80%"};
int init() {
   GlobalVariablesDeleteAll("ex");
   SetIndexStyle(0, DRAW_ARROW, 3,3,clrBlue);
   SetIndexBuffer(0, Buf_1);

   SetIndexStyle(1, DRAW_ARROW, 3,3,clrRed);// переворот
   SetIndexBuffer(1, Buf_2);
   HLPeriod=GlobalVariableGet("HLPeriod");
   cm=GlobalVariableGet("cm");
   for (k=0;k<HLPeriod;k++)
   {
   h[k] = position[k][0];
   l[k] = position[k][1];
   c[k] = position[k][2];
   o[k] = position[k][3];

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
            
            ht_rev[z]=(High [i+z]-lmin)/hl;
            lt_rev[z]=(Low  [i+z]-lmin)/hl;
            ct_rev[z]=(hmax - Close [i+z])/hl;
            ot_rev[z]=(hmax - Open  [i+z])/hl;
            

            } 
         }
for (k=0;k<2;k++)
         {
for (z=0;z<HLPeriod;z++)
         {
         if (t/100 > MathAbs(h[k]-ht[z]))  sr++;
         if (t/100 > MathAbs(l[k]-lt[z]))  sr++;
         if (t/100 > MathAbs(c[k]-ct[z]))  sr++;
         if (t/100 > MathAbs(o[k]-ot[z]))  sr++;         
         } 
         //////////////////////////////
if (sr==HLPeriod*4) 
      { 
        str=str+Symbol()+"["+i+"] "+ position_value[k] +"\n";
        GlobalVariableSet("ex"+numex,i);numex++;

        Buf_1[i]=High[i]+150*Point();

      }
      sr=0;
      /////////////////////////////////         
  }       
         
         
for (k=0;k<2;k++)
         {
for (z=0;z<HLPeriod;z++)
         {
         if (t/100 > MathAbs(h[k]-ht_rev[z]))  sr2++;
         if (t/100 > MathAbs(l[k]-lt_rev[z]))  sr2++;
         if (t/100 > MathAbs(c[k]-ct_rev[z]))  sr2++;
         if (t/100 > MathAbs(o[k]-ot_rev[z]))  sr2++;         
         } //if (i==10)  Alert(sr);

if (sr2==HLPeriod*4) 
      {  
        str=str+Symbol()+"["+i+"] turn "+ position_value[0] +"\n";
        GlobalVariableSet("ex"+numex,i);numex++;

        Buf_2[i]=Low[i]-150*Point();
      }
      sr2=0;
      }
   i--;}
      Comment(str);
   return(0);
}