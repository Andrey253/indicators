///// каждый раз сранивается предыдущая свеча с текущей, шагаем по i
// сравниваем H L
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
   FileWrite(FileHandle,HLPeriod+",");
   GlobalVariableSet("HLPeriod",HLPeriod);     
   GlobalVariableSet("cm",cm);
}
int start() {
      

for(z=0;z<HLPeriod;z++)
         {hl=High[cm+z]-Low[cm+z];
         if (hl!=0){
                  h=NormalizeDouble((High [cm+z]- High[cm+z+1])/hl,3);
                  l=NormalizeDouble((Low  [cm+z]- Low [cm+z+1])/hl,3);
                  c=NormalizeDouble((Close [cm+z]- Close[cm+z+1])/hl,3);
                  o=NormalizeDouble((Open  [cm+z]- Open [cm+z+1])/hl,3);
                  
         GlobalVariableSet("h"+DoubleToStr(z,0),h);
         GlobalVariableSet("l"+DoubleToStr(z,0),l);
         GlobalVariableSet("c"+DoubleToStr(z,0),c);
         GlobalVariableSet("o"+DoubleToStr(z,0),o);

         if (z==(HLPeriod-1)) FileWrite(FileHandle,h,l,c,o);
         if (z!=(HLPeriod-1)) FileWrite(FileHandle,h,l,c,o+",");
                 }
         }

     FileWrite(FileHandle,"}");
   if(FileHandle>0) FileClose(FileHandle);  
   Buf_1[cm]=High[cm]+20*Point;
       
    //  Alert(simbol[isim],"[",i,"]  s=",s);Buf_1[i]=High[i]+20*Point;
   
   return(0);
}