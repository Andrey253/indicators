// Макди сравниваем приращение с двух свечей
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_color1  DodgerBlue
//#include <stdlib.mqh>
extern int cm=1;  
extern int HLPeriod=5, sign;
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
   FileWrite(FileHandle,HLPeriod+",");
   GlobalVariableSet("HLPeriod",HLPeriod);     
   GlobalVariableSet("cm",cm);
   
   l=iMACD(NULL,0,3,5,3,PRICE_CLOSE,MODE_MAIN,cm)-iMACD(NULL,0,3,5,3,PRICE_CLOSE,MODE_MAIN,cm+1);
   if (l >= 0) sign = 1;
   if (l <  0) sign =-1;
   FileWrite(FileHandle,sign+",");
   
    GlobalVariableSet("sign",sign);
   
for(z=0;z<HLPeriod;z++)
{
                  h=(iMACD(NULL,0,3,5,3,PRICE_CLOSE,MODE_MAIN,cm+1+z)-iMACD(NULL,0,3,5,3,PRICE_CLOSE,MODE_MAIN,cm+z+2))/l;

                  
         GlobalVariableSet("h"+DoubleToStr(z,0),h);


         if (z==(HLPeriod-1)) FileWrite(FileHandle,h);
         if (z!=(HLPeriod-1)) FileWrite(FileHandle,h+",");
                 }


     FileWrite(FileHandle,"}");
   if(FileHandle>0) FileClose(FileHandle);  
   
}
int start() {

   Buf_1[cm]=High[cm]+20*Point;
       
   return(0);
   
}