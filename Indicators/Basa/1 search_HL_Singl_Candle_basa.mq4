// последовательность типов свечей
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_color1  MediumVioletRed
extern double t=20;
int HLPeriod, count_position, count_extremums; 
int k,kk,z,sr,sr2,cm, numex;
string str;
double Buf_2[],c[9],o[9],ct[9],ot[9],hmax, lmin,hl;
double position[][17] = {{ 5,0.40697674,0.18604651,0.48484848,0.28282828,0.03649635,0.58394161,0.125,0.95833333,0.96610169,0.58757062}};
string position_value[] = {" откат и продолжение движения"};
int searched_i[];// i
string searched_v[];// Значение найденного совпадения
int init() {
   GlobalVariablesDeleteAll("ex");
   int i;
   i=Bars-10;

   SetIndexStyle(0, DRAW_ARROW, 3,3);
   SetIndexBuffer(0, Buf_2);
str=str+"                                             HLPeriod = "+HLPeriod+" HL \n";
   count_position = ArrayRange(position,0);
   for (kk=0;kk<count_position;kk++)
   {
      HLPeriod = position[kk][0];

      for (k=0;k<HLPeriod;k++)
         {
            c[k] = position[kk][k*2+1];
            o[k] = position[kk][k*2+2];

         }

while(i>0)
      {

for(z=0;z<HLPeriod;z++)
         {
         hl=High[i+z]-Low[i+z];
         if (hl!=0)
            {
            ct[z]=(Close [i+z]- Low[i+z])/hl;
            ot[z]=(Open  [i+z]- Low[i+z])/hl;

            } else continue;
         }
for (k=0;k<HLPeriod;k++)
         {
         if (t/100 > MathAbs(c[k]-ct[k]))  sr++;
         if (t/100 > MathAbs(o[k]-ot[k]))  sr++;
         }
for (k=0;k<HLPeriod;k++)
         {
         if (t/100 > MathAbs(c[k]-ot[k]))  sr2++;
         if (t/100 > MathAbs(o[k]-ct[k]))  sr2++;
         }
            /////////////////////////////////
if (sr==HLPeriod*2) 
      {  //if (i==115) for (k=0;k<HLPeriod;k++){ Alert(ht[k],"- ",h[k],"---- ",lt[k],"- ",l[k]);}
     // if (i==698) Alert(ht[z]," - ",lt[z]," --- ");
        str=str+Symbol()+"["+i+"]"+position_value[kk]+" \n";
         GlobalVariableSet("ex"+numex,i);
         ArrayResize(searched_i,numex+1,10);
         ArrayResize(searched_v,numex+1,10);
         searched_i[numex] = i;
         searched_v[numex] = position_value[kk];
         ObjectCreate("name"+numex, OBJ_TEXT, 0, Time[i],High[i]+300*Point);
         ObjectSetText("name"+numex,position_value[kk], 10, "Verdana", clrLawnGreen);
         numex++;
         
        Buf_2[i]=High[i]+50*Point();
      }
      sr=0;
            /////////////////////////////////
if (sr2==HLPeriod*2) 
      {  //if (i==115) for (k=0;k<HLPeriod;k++){ Alert(ht[k],"- ",h[k],"---- ",lt[k],"- ",l[k]);}
     // if (i==698) Alert(ht[z]," - ",lt[z]," --- ");
        str=str+Symbol()+"["+i+"] turn "+position_value[kk]+"\n";
        GlobalVariableSet("ex"+numex,i);
        ArrayResize(searched_i,numex+1,10);
        ArrayResize(searched_v,numex+1,10);
        searched_i[numex] = i;
        searched_v[numex] = position_value[kk];
        ObjectCreate("name"+numex, OBJ_TEXT, 0, Time[i],High[i]-300*Point);
        ObjectSetText("name"+numex,position_value[kk]+" с переворотом", 10, "Verdana", clrLawnGreen);        
        numex++;

        Buf_2[i]=Low[i]-50*Point();
      }
      sr2=0;
      ///////////////////////////////
   i--;}
      Comment(str);
   }

}
int start() {
count_extremums = ArrayRange(searched_i,0);

   for (k=0;k<=count_extremums;k++)
      {
      Buf_2[searched_i[k]]=High[searched_i[k]]+50*Point();

      }


   return(0);
}
int deinit()
{
int obj_total=ObjectsTotal(),o;
   for(o=obj_total;o>=0;o--)
     {
     ObjectDelete("name"+o);
     }
     return(0);
}