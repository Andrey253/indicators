#property indicator_chart_window
#property indicator_buffers 1
#property indicator_color1  DodgerBlue
//#include <stdlib.mqh>
extern int cm=1;  
extern int HLPeriod=2;
int z;
double h,l,h1, l1, h0 ,l0,c,o,hl,hmax,lmin;
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

for(z=0;z<HLPeriod;z++)
         {
         h = High[iHighest(NULL,0,MODE_HIGH,1,cm+z)];
         l = Low [iLowest (NULL,0,MODE_LOW ,1,cm+z)];
         hl=h-l ;

         if (hl!=0){
                           h0 = (High[cm+z]-l)/hl;
                           l0 = (Low [cm+z]-l)/hl;        
                           h1 = (High[cm+1+z]-l)/hl;
                           l1 = (Low [cm+1+z]-l)/hl;
                  
         GlobalVariableSet("h0"+DoubleToStr(z,0),h0);
         GlobalVariableSet("l0"+DoubleToStr(z,0),l0);
         GlobalVariableSet("h1"+DoubleToStr(z,0),h1);
         GlobalVariableSet("l1"+DoubleToStr(z,0),l1);

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