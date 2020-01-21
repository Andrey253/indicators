#property indicator_chart_window
#property indicator_buffers 1
#property indicator_color1  DodgerBlue
//#include <stdlib.mqh>
extern int cm=10;  
extern int HLPeriod=4;
int z;
double h,l,c,o,hl,hmax,lmin,co;
double Buf_1[];
   int counted_bars; 
   string FileName;
int FileHandle; 
int init() {
   SetIndexStyle(0, DRAW_ARROW, 3,3);
   SetIndexBuffer(0, Buf_1);
   GlobalVariablesDeleteAll();
   GlobalVariableSet("HLPeriod",HLPeriod);     
   GlobalVariableSet("cm",cm);
   FileName=Symbol()+Period()+".txt"; 
   FileHandle=FileOpen(FileName,FILE_WRITE | FILE_CSV,",");
   FileWrite(FileHandle,",{");
   FileWrite(FileHandle,HLPeriod+",");
}
int start() {
      

for(z=0;z<HLPeriod;z++)
         {hl=High[cm+z]-Low[cm+z];
         if (hl!=0){
         
         c=(Close [cm+z]- Low[cm+z])/hl;
         o=(Open  [cm+z]- Low[cm+z])/hl;
         co=(Close  [cm+z]- Open[cm+z])/hl;
                  
         GlobalVariableSet("c"+DoubleToStr(z,0),c);
         GlobalVariableSet("o"+DoubleToStr(z,0),o);
         GlobalVariableSet("co"+DoubleToStr(z,0),co);

         if (z==(HLPeriod-1)) FileWrite(FileHandle,c,o,co);
         if (z!=(HLPeriod-1)) FileWrite(FileHandle,c,o,co+",");
                 }
         }

     FileWrite(FileHandle,"}");
   if(FileHandle>0) FileClose(FileHandle);  
   Buf_1[cm]=High[cm]+20*Point;
       
    //  Alert(simbol[isim],"[",i,"]  s=",s);Buf_1[i]=High[i]+20*Point;
   
   return(0);
}