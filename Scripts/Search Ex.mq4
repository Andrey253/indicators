void OnStart()
  {
      int i;
      double b;
      i=GlobalVariableGet("begin");
      if (!GlobalVariableGet("ex"+DoubleToStr(i,0),b)) {GlobalVariableSet("begin",0); i=-1;}
      //Alert(i);
      GlobalVariableSet("begin",i+1);
     b=GlobalVariableGet("ex"+i);
      ChartNavigate(0,CHART_END,-b);
      
  }
