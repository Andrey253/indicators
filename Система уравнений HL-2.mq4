#property indicator_chart_window
#property indicator_buffers 8
#property indicator_color1  DodgerBlue
#property indicator_color2  White
#property indicator_color3  Red
#property indicator_color4  DodgerBlue
#property indicator_color5  White
#property indicator_color6  Red
#property indicator_color7  Gold
#property indicator_color8  Gold
int    i,counted_bars;
extern int cm=3,por=4;  
double x[2000][2000],y[10000],xx[1000],pr[1000],prl[1000],xxl[1000];
int k,z,m,n,p,a;
double f,fl,mn;
// Buffers for signals
double Buf_1[],Buf_4[];
double Buf_2[],Buf_5[];
double Buf_3[],Buf_6[],Buf_7[],Buf_8[],t;

int init() {
   SetIndexStyle(0, DRAW_ARROW, 3,3);
   SetIndexBuffer(0, Buf_1);
   SetIndexStyle(1, DRAW_ARROW, 3,3);
   SetIndexBuffer(1, Buf_2);
   SetIndexStyle(2, DRAW_ARROW, 3,3);
   SetIndexBuffer(2, Buf_3);
   SetIndexStyle(3,DRAW_ARROW, 3,3);
   SetIndexBuffer(3, Buf_4);
   SetIndexStyle(4,DRAW_LINE);
   SetIndexBuffer(4, Buf_5);
   SetIndexStyle(5,DRAW_LINE);
   SetIndexBuffer(5, Buf_6);
   SetIndexStyle(6, DRAW_ARROW, 3,3);
   SetIndexBuffer(6, Buf_7);
    SetIndexStyle(7,DRAW_ARROW, 3,3);
   SetIndexBuffer(7, Buf_8);
   SetIndexShift(3, 160);
   SetIndexShift(4, 160);
   SetIndexShift(5, 160);
   SetIndexShift(7, 160);
   return(0);
}
int start() {
counted_bars=IndicatorCounted();
      for (z=0;z<por;z++)
      { 
          y[z]=Close[cm+z-1]-(High [cm+z-1] + Low [cm+z-1])/2;
          for (k=0;k<por;k++)
             {
               x[z][k]=Close[cm+k+z]-(High [cm+k+z] + Low [cm+k+z])/2;

             }
      }  
    for (p=0;p<(por-1);p++)
      {
      for (n=p;n<(por-1);n++)
         {if (x[p][p]!=0) mn=x[n+1][p]/x[p][p];
          for (m=p;m<por;m++){x[n+1][m]=x[n+1][m]-x[p][m]*mn; }
              y[n+1]=y[n+1]-y[p]*mn;
         }
       }
        for (k=(por-1);k>=0;k--)
           { xx[k]=(y[k]-pr[k])/x[k][k];for (z=k;z<=(por-1);z++) pr[k-1]=pr[k-1]+x[k-1][z]*xx[z]; }
   /////////////////////////////////////
         for (z=0;z<por;z++)
      { 
          y[z]=Close[cm+z-1]-(High [cm+z-1] + Low [cm+z-1])/2;
          for (k=0;k<por;k++)
             {
               x[z][k]=Close[cm+k+z]-(High [cm+k+z] + Low [cm+k+z])/2;
               
             }
      }  
    for (p=0;p<(por-1);p++)
      {
      for (n=p;n<(por-1);n++)
         {if (x[p][p]!=0) mn=x[n+1][p]/x[p][p];
         for (m=p;m<por;m++){x[n+1][m]=x[n+1][m]-x[p][m]*mn; }
              y[n+1]=y[n+1]-y[p]*mn;
         }
       }
        for (k=(por-1);k>=0;k--)
           { xxl[k]=(y[k]-prl[k])/x[k][k];for (z=k;z<=(por-1);z++) prl[k-1]=prl[k-1]+x[k-1][z]*xxl[z]; }
   /////////////////////////////////   
   i=Bars-counted_bars-por-5;
   while(i>0)
     {
     f=0;
    for (a=0;a<por;a++)
         {  f =f
            +(Close[i+a]-(High [i+a] + Low [i+a])/2)*xx[a]; }
    Buf_2[cm]=High[cm]+200*Point;
    Buf_1[i-1]=f+Close[i];
    fl=0;
    for (a=0;a<por;a++)
         {  fl =fl
            +(Close[i+a]-(High [i+a] - Low [i+a])/2)*xxl[a]; }
    Buf_3[cm]=Low[cm]-200*Point;
    Buf_7[i-1]=fl+Close[i];

     i--;
   }


   return(0);
}