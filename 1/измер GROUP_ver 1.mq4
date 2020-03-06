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
   GlobalVariableSet("HLPeriod",HLPeriod);     
GlobalVariableSet("cm",cm);      

for(z=0;z<HLPeriod;z++)
         {
         h = High[iHighest(NULL,0,MODE_HIGH,z+1,cm)];
         l = Low [iLowest (NULL,0,MODE_LOW ,z+1,cm)];
         hl=h-l ;

         if (hl!=0){
                           
                           o = (Open  [cm+z]-l)/hl;
                           c = (Close [cm+0]-l)/hl; 
                           
                           if (Open  [cm+z] < l) Alert(Open  [cm+z] +"  " + l + "   " + z);       
                  
         GlobalVariableSet("o"+DoubleToStr(z,0),o);
         GlobalVariableSet("c"+DoubleToStr(z,0),c);

         if (z==(HLPeriod-1)) FileWrite(FileHandle,h,l);
         if (z!=(HLPeriod-1)) FileWrite(FileHandle,h,l+",");
                 }
         }

     FileWrite(FileHandle,"}");
   if(FileHandle>0) FileClose(FileHandle);
}
int start() {
  
   Buf_1[cm]=High[cm]+20*Point;
       
    //  Alert(simbol[isim],"[",i,"]  s=",s);Buf_1[i]=High[i]+20*Point;
   
   return(0);
}