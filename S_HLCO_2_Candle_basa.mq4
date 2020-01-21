// последовательность типов свечей
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_color1  MediumVioletRed
extern double t=20;
int HLPeriod, count_position, count_extremums; 
int k,kk,z,sr,sr2,cm, numex;
string str;
double Buf_2[],h[9],l[9],c[9],o[9],ht[9],lt[9],ct[9],ot[9],hmax, lmin,hl;
double position[][17] = {{3,0.664,0.974,0.784,0.974,0.875,0.599,0.73,0.026,-0.318,-0.664,0.054,-0.136}
                        ,{3,-0.178,0.138,-0.031,-0.347,-0.713,0.203,-0.26,0.615,0.363,0.129,0.321,-0.511}
                        ,{3,0.912,0.534,0.318,0.463,0.625,-0.051,0.746,-0.105,-0.444,-0.349,-0.317,-0.278}
                        ,{3,-0.003,-0.292,-0.363,0.223,-0.91,-0.3,0.354,-1.257,-0.348,-0.802,-0.755,-0.161}
                        ,{3,-0.14,-0.255,-0.604,0.518,-0.642,0.902,0.593,0.817,0.912,0.534,0.318,0.463}
                        ,{4,-0.055,0.127,-0.339,0.474,0.424,0.091,0.46,-0.321,-0.502,-0.591,-0.569,-0.384,-0.734,-0.357,-0.52,-0.858}
                        ,{4,-0.348,-0.802,-0.755,-0.161,0.3,1.266,-0.4,1.248,-0.048,-0.308,0.654,-0.641,-0.024,-0.168,-0.83,0.615}
                        ,{4,0.832,0.28,0.63,0.177,-0.695,-0.447,0.396,-0.881,-1.047,-0.658,-0.754,-1.219,-0.256,-0.806,-0.825,-0.128}};
string position_value[] = {" 1 селл 50% доливка от минимум"," 2 Пробой через хай трех свечей, почти 100%",
" 3 пробой последней свечи в обе стороны"," 4 осторожно отбой хай, селл стоп+10 посл свечи", " 5 перехай и селл"," 6 селл стоп лоу 4х свечей более 200%",
" 7 селл стоп лоу 4ч свечей", " 8 100% от лоу вверх"};
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
            h[k] = position[kk][k*4+1];
            l[k] = position[kk][k*4+2];
            c[k] = position[kk][k*4+3];
            o[k] = position[kk][k*4+4];

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
            ct[z]=(Close [i+z]- Close[i+z+1])/hl;
            ot[z]=(Open  [i+z]- Open [i+z+1])/hl;

            } else continue;
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
         } 
//  Логика поиска
if (sr==HLPeriod*4) 
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
if (sr2==HLPeriod*4) 
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