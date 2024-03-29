//+------------------------------------------------------------------+
//|                                                          web.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//http://www.cmegroup.com/CmeWS/mvc/Margins/OUTRIGHT.csv?sortField=exchange&sortAsc=true&sector=FX&exchange=CME
//http://www.cmegroup.com/CmeWS/mvc/Margins/OUTRIGHT.csv?sortField=exchange&sortAsc=true&exchange=CME
//http://www.cmegroup.com/CmeWS/mvc/Margins/OUTRIGHT.csv?sortField=exchange&sortAsc=true
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict



void OnStart()
  {
   string cookie=NULL, headers, resultat, resultatik, symbol = "r", symbol_K = "r";
   char post[],result[], resul[];
   int res;
//--- для работы с сервером необходимо добавить URL "https://www.google.com/finance" 
//--- в список разрешенных URL (Главное меню->Сервис->Настройки, вкладка "Советники"):
   string google_url="http://www.cmegroup.com/CmeWS/mvc/Margins/OUTRIGHT.csv?sortField=exchange&sortAsc=true";
//--- обнуляем код последней ошибки
   ResetLastError(); 
//--- загрузка html-страницы с Google Finance
   int timeout=5000; //--- timeout менее 1000 (1 сек.) недостаточен при низкой скорости Интернета
   res=WebRequest("GET",google_url,cookie,NULL,timeout,post,0,result,headers);
//--- проверка ошибок
   if(res==-1)
     {
//      Alert("Ошибка в WebRequest. Код ошибки  =",GetLastError());
      Print("Ошибка в WebRequest. Код ошибки  =",GetLastError());
      //--- возможно, URL отсутствует в списке, выводим сообщение о необходимости его добавления
      MessageBox("Необходимо добавить адрес '"+google_url+"' в список разрешенных URL во вкладке 'Советники'","Ошибка",MB_ICONINFORMATION);
     GlobalVariableSet("webcme",0);
     }
   else
     {
      //--- успешная загрузка
//Alert("Файл успешно загружен, Размер файла =%d байт.",ArraySize(result));
      PrintFormat("Файл успешно загружен, Размер файла =%d байт.",ArraySize(result));
      //--- сохраняем данные в файл
      resultat = CharArrayToString(result);
      int lenght = StringLen(resultat);
      for(int x = 0; x < lenght; x++)
         {
         symbol = StringSetChar(symbol,0,StringGetChar(resultat,x));
         if(symbol == "," && symbol_K == "\"") symbol = ";";
         symbol_K = symbol;
         resultatik += symbol; 
         }
      FileCopy("cme.csv",0,"cme_copy.csv",0|FILE_REWRITE);
      FileDelete("cme.csv",0);
      int filehandle=FileOpen("cme.csv",FILE_WRITE|FILE_CSV);
      //--- проверка ошибки
      if(filehandle!=INVALID_HANDLE)
        {
         //--- сохраняем содержимое массива result[] в файл
         FileWriteString(filehandle,resultatik);
         //--- закрываем файл
         FileClose(filehandle);
        }
      else Print("Ошибка в FileOpen. Код ошибки =",GetLastError());
     GlobalVariableSet("webcme",2);
     }
   }

   
   
