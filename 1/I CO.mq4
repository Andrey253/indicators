#property indicator_chart_window
#property indicator_buffers 1
#property indicator_color1  DodgerBlue
//#include <stdlib.mqh>
extern int cm=1;  
extern int HLPeriod=4;
int z;
double h,l,c,o,hl,co,hmax,lmin;
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

co=Close[cm]-Open[cm];

for(z=1;z<HLPeriod;z++)
         {
         if (co!=0){
                  c=(Close [cm+z]- Open[cm+z])/co;
         if (c <0){
         GlobalVariableSet("cdown"+DoubleToStr(z,0),0);
                  } else
                  GlobalVariableSet("cdown"+DoubleToStr(z,0),1);
         
                  
         GlobalVariableSet("c"+DoubleToStr(z,0),c);

         if (z==(HLPeriod-1)) FileWrite(FileHandle,h,l);
         if (z!=(HLPeriod-1)) FileWrite(FileHandle,h,l+",");
                 }
         }

     FileWrite(FileHandle,"}");
   if(FileHandle>0) FileClose(FileHandle);  
   Buf_1[cm]=High[cm]+20*Point;
       
    //  Alert(simbol[isim],"[",i,"]  s=",s);Buf_1[i]=High[i]+20*Point;
   
   return(0);
}