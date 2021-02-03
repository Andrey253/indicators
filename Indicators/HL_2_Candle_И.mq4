// анализируем 2 свечи, каждую по макс и мин.
//Относительно общего для этих двух свечей мин и макс

#property indicator_chart_window
#property indicator_buffers 1
#property indicator_color1  DodgerBlue
//#include <stdlib.mqh>
extern int cm=50;  
extern int HLPeriod=2;
int z;
double h1,l1,h2,l2,c,o,hl,hmax,lmin;
double Buf_1[];
   int counted_bars; 
   string FileName;
int FileHandle; 
int init() {
   SetIndexStyle(0, DRAW_ARROW, 3,3);
   SetIndexBuffer(0, Buf_1);
   GlobalVariablesDeleteAll();
   FileName=Symbol()+Period()+".txt"; 
   FileHandle=FileOpen(FileName,FILE_WRITE | FILE_CSV,",");
   FileWrite(FileHandle,",{");
   FileWrite(FileHandle,HLPeriod+",");
}
int start() {
GlobalVariableSet("HLPeriod",HLPeriod);     
GlobalVariableSet("cm",cm);      

   hmax=High[iHighest(NULL,0,MODE_HIGH,HLPeriod,cm)];
   lmin=Low [iLowest (NULL,0,MODE_LOW, HLPeriod,cm)];
   hl=hmax-lmin;
   if (hl!=0)
for(z=0;z<(HLPeriod-1);z++)
         {
         h1=(High [cm+z]-lmin)/hl;
         l1=(Low  [cm+z]-lmin)/hl;
         h2=(High [cm+z+1]-lmin)/hl;
         l2=(Low  [cm+z+1]-lmin)/hl;
                  
         GlobalVariableSet("h1"+DoubleToStr(z,0),h1);
         GlobalVariableSet("l1"+DoubleToStr(z,0),l1);
         GlobalVariableSet("h2"+DoubleToStr(z,0),h2);
         GlobalVariableSet("l2"+DoubleToStr(z,0),l2);

         if (z==(HLPeriod-1)) FileWrite(FileHandle,h1,l1,h2,l2);
         if (z!=(HLPeriod-1)) FileWrite(FileHandle,h1,l1,h2,l2+",");
         }

     FileWrite(FileHandle,"}");
   if(FileHandle>0) FileClose(FileHandle);  
   Buf_1[cm]=High[cm]+20*Point;
       
    //  Alert(simbol[isim],"[",i,"]  s=",s);Buf_1[i]=High[i]+20*Point;
   
   return(0);
}