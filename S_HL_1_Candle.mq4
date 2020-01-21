// последовательность типов свечей
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_color1  MediumVioletRed
extern double t=5;
int HLPeriod; 
int k,z,sr,sr2,cm, numex;
string simbols,str;
double Buf_2[],c[9],o[9],ct[9],ot[9],hmax, lmin,hl,co[9], cot[9];
int init() {
   GlobalVariablesDeleteAll("ex");
   SetIndexStyle(0, DRAW_ARROW, 3,3);
   SetIndexBuffer(0, Buf_2);
   HLPeriod=GlobalVariableGet("HLPeriod");
   cm=GlobalVariableGet("cm");
   for (k=0;k<HLPeriod;k++)
   {
   c[k] = GlobalVariableGet("c"+DoubleToStr(k,0));
   o[k] = GlobalVariableGet("o"+DoubleToStr(k,0));
   co[k] = GlobalVariableGet("co"+DoubleToStr(k,0));

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
            ct[z]=(Close [i+z]- Low[i+z])/hl;
            ot[z]=(Open  [i+z]- Low[i+z])/hl;
            cot[z]=(Close[i+z]- Open[i+z])/hl;

            } else continue;
         }
for (k=0;k<HLPeriod;k++)
         {
         if (t/100 > MathAbs(c[k]-ct[k]))  sr++;
         if (t/100 > MathAbs(o[k]-ot[k]))  sr++;
         if (t/100 > MathAbs(co[k]-cot[k]))  sr++;
         }
for (k=0;k<HLPeriod;k++)
         {
         if (t/100 > MathAbs(c[k]-ot[k]))  sr2++;
         if (t/100 > MathAbs(o[k]-ct[k]))  sr2++;
         if (t/100 > MathAbs(co[k]+cot[k]))sr2++;
         }
            /////////////////////////////////
if (sr==HLPeriod*3) 
      {  //if (i==115) for (k=0;k<HLPeriod;k++){ Alert(ht[k],"- ",h[k],"---- ",lt[k],"- ",l[k]);}
     // if (i==698) Alert(ht[z]," - ",lt[z]," --- ");
        str=str+Symbol()+"["+i+"] \n";
GlobalVariableSet("ex"+numex,i);numex++;
        Buf_2[i]=High[i]+50*Point();
      }
      sr=0;
            /////////////////////////////////
if (sr2==HLPeriod*3) 
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