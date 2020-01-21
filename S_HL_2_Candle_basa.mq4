// последовательность типов свечей
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_color1  MediumVioletRed
extern double t=20;
int HLPeriod, count_position, count_extremums; 
int k,kk,z,sr,sr2,cm, numex;
string str;
double Buf_2[],h[9],l[9],ht[9],lt[9],hmax, lmin,hl;
double position[][17] = {{ 4,0.22093023,0.37209302,-1.94949495,-0.18181818,-0.73722628,-0.42335766,0.025,-0.48333333}
,{4,0.4957265,0.11111111,0.50462963,0.50925926,0.21658986,-0.29493088,0.19811321,1.24528302}};
string position_value[] = {" откат up и down","Если пик то переворот, в начале - продолжение"};
int searched_i[];// i
string searched_v[];// Значение найденного совпадения
int init() {
   GlobalVariablesDeleteAll("ex");
   int i;


   SetIndexStyle(0, DRAW_ARROW, 3,3);
   SetIndexBuffer(0, Buf_2);
str=str+"                                             HLPeriod = "+HLPeriod+" HL \n";
   count_position = ArrayRange(position,0);
   //Alert(count_position);
   for (kk=0;kk<count_position;kk++)
   {
      HLPeriod = position[kk][0];

      for (k=0;k<HLPeriod;k++)
         {
            h[k] = position[kk][k*2+1];
            l[k] = position[kk][k*2+2];

         }
   i=Bars-10;
while(i>0)
      {
//  Логика поиска
for(z=0;z<HLPeriod;z++)
         {
         hl=High[i+z]-Low[i+z];
         if (hl!=0)
            {
            ht[z]=(High [i+z]- High[i+z+1])/hl;
            lt[z]=(Low  [i+z]- Low [i+z+1])/hl;
          //  lt_turn[z]=(High [i+z]- High[i+z+1])/hl;
           // ht_turn[z]=(Low  [i+z]- Low [i+z+1])/hl;

            } else continue;
         }
for (k=0;k<HLPeriod;k++)
         {
         if (t/100 > MathAbs(h[k]-ht[k]))  sr++;
         if (t/100 > MathAbs(l[k]-lt[k]))  sr++;
         } //if (i==10)  Alert(sr);
for (k=0;k<HLPeriod;k++)
         {
         if (t/100 > MathAbs(h[k]+lt[k]))  sr2++;
         if (t/100 > MathAbs(l[k]+ht[k]))  sr2++;
         } 
//  Логика поиска
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
         ObjectSetText("name"+numex,position_value[kk], 10, "Verdana", clrBeige);
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
        ObjectSetText("name"+numex,position_value[kk]+" turn", 10, "Verdana", clrBeige);        
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