#property indicator_chart_window
#property indicator_buffers 1
#property indicator_color1  DodgerBlue
//#include <stdlib.mqh>
extern int cm=1;  
extern int HLPeriod=4;
int z;
double h,l,c,o,hl,hmax,lmin;
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
}
int start() {
GlobalVariableSet("HLPeriod",HLPeriod);     
GlobalVariableSet("cm",cm);      
   hmax=High[iHighest(NULL,0,MODE_HIGH,HLPeriod,cm)];
   lmin=Low [iLowest (NULL,0,MODE_LOW, HLPeriod,cm)];
   //GlobalVariableSet("hmax",hmax);
   //GlobalVariableSet("lmin",lmin);
   hl=hmax-lmin;
   if (hl!=0)
      {for(z=0;z<HLPeriod;z++)
         {
         h=(High [cm+z]-lmin)/hl;
         l=(Low  [cm+z]-lmin)/hl;
         c=(Close[cm+z]-lmin)/hl;
         o=(Open [cm+z]-lmin)/hl;
         GlobalVariableSet("h"+DoubleToStr(z,0),NormalizeDouble(h,4));
         GlobalVariableSet("l"+DoubleToStr(z,0),NormalizeDouble(l,4));
         GlobalVariableSet("c"+DoubleToStr(z,0),NormalizeDouble(c,4));
         GlobalVariableSet("o"+DoubleToStr(z,0),NormalizeDouble(o,4));
         FileWrite(FileHandle,h,l,c,o+",");
         }
      }
     FileWrite(FileHandle,"}");
   if(FileHandle>0) FileClose(FileHandle);  
   Buf_1[cm]=High[cm]+20*Point;
       
    //  Alert(simbol[isim],"[",i,"]  s=",s);Buf_1[i]=High[i]+20*Point;
   
   return(0);
}