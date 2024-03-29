//+------------------------------------------------------------------+
//|                                                    DkzNkzMkz.mq4 |
//|                                                          Author: |
//|                                             Contact Information: |
//+------------------------------------------------------------------+
// Добавитьв Сервис/Настройки/Советники - Разрешить WebRequest:  
//   http://www.cmegroup.com/CmeWS/mvc/Margins/OUTRIGHT.csv?sortField=exchange&sortAsc=true&exchange=CME&sector=FX
//+---------------------------------------------------------------------------------------------------------------
#property strict
#property script_show_inputs
// -- для подстановок в свойствах
enum timfrim
   {
   Per1=PERIOD_M1,  // 1 минута
   Per2=PERIOD_M5,  // 5 минут
   Per3=PERIOD_M15,  // 15 минут
   Per4=PERIOD_M30,  // 30 минут
   Per5=PERIOD_H1,  // 1 час
   Per6=PERIOD_H4,  // 4 часа
   Per7=PERIOD_D1,  // 1 день
   Per8=PERIOD_W1,  // 1 неделя
   Per9=PERIOD_MN1,  // 1 месяц
   };
#property indicator_chart_window
struct InfoStruct { string name; double percent; double NKZ; string bankTime; double bankPercent; double MKZc; double MKZp; string MKZ_DenN; string MKZ_DenK;};
struct flash {uint cbSize; uint hwnd; uint dwFlags; uint uCount; uint dwTimeout;} pfwi;
struct InfoStruFileNKZ {datetime dateHist; double NKZ; double MARGHA;};    // Структура для принятия данных из внешнего файла для НКЗ
struct InfoStruFileBU {datetime dateHist; double BU;};    // Структура для принятия данных из внешнего файла для Банковский уровень
struct InfoStruFileZL {datetime dateHist; double ZL;};    // Структура для принятия данных из внешнего файла для Летнего и зимнего времени
struct InfoStruFileNKZ_S {string Instr; datetime dateHist; double NKZ; double cena;};    // Структура для принятия данных из внешнего файла для НКЗ
struct InfoStruFileNKZ_New {string Instr; datetime dateHist; double NKZ;};    // Структура для принятия данных из внешнего файла для НКЗ
struct ZonkiStruct {string name; datetime time1; double price1; datetime time2; double price2;};

#import "user32.dll"
   void keybd_event(int bVk,int bScan,int dwFlags,int dwExtraInfo);
   int  GetParent(int hWnd);
   int  FlashWindowEx(flash &pfwi);
   int  RegisterWindowMessageA(uchar &lParam[]);
   int  SendMessageA(int hWnd, int Msg, int wParam, char &lParam[]);
#import

#define M1  OBJ_PERIOD_M1
#define M5  OBJ_PERIOD_M5
#define M15 OBJ_PERIOD_M15
#define M30 OBJ_PERIOD_M30
#define H1  OBJ_PERIOD_H1
#define H4  OBJ_PERIOD_H4
#define D1  OBJ_PERIOD_D1
#define W1  OBJ_PERIOD_W1
#define MN1 OBJ_PERIOD_MN1
#define ALL OBJ_ALL_PERIODS

#define MT4_MESSAGE "MetaTrader4_Internal_Message"
#define TA_SCRIPT_NAME "web"



//+------------------------------------------------------------------+
//| ПОЛЬЗОВАТЕЛЬСКИЕ НАСТРОЙКИ ИНДИКАТОРА                            |                                                          //
//+------------------------------------------------------------------+
   
// Список таймфреймов -> M1, M5, M5, M30, H1, H4, D1, W1, MN1, ALL - все
// Примеры:
// double DKZ_timeframe = ALL;       // Показывать на всех таймфреймах
// double DKZ_timeframe = M15;       // Показывать на таймфрейме M15
// double DKZ_timeframe = M1|M5|M15; // Показывать на таймфреймах M1 и M5 и M15

//////////////////////////////////////////////////////////////////////
// http://www.cmegroup.com/trading/fx/g10/euro-fx_performance_bonds.html#sortField=exchange&sortAsc=true&sector=FX&exchange=CME&pageNumber=1
// http://www.ecb.europa.eu/mopo/implement/omo/html/index.en.html
// http://www.global-rates.com/interest-rates/central-banks/central-banks.aspx
// https://www.theice.com/products/2935638
// http://tradeinwest.ru/marzhinalnye-trebovaniya/
// http://ru.investing.com/economic-calendar/interest-rate-decision-164
// http://profitschool.ru/index.php/avtomatizatsiya/indikatory/165-indikator-dkznkzmaker
                                      
InfoStruct Info[]      = {                  
// { Название инструмента, % ставка, НКЗ в пунктах, Время Б.уровня, % ставка для Б.уровня, МКЗ_Call, МКЗ_Put}   НКЗ = маржа / цена пункта;
                                              // % ставки -> http://www.global-rates.com/interest-rates/central-banks/central-banks.aspx
   { "EURUSD", 0.75, 2440, "10:30", 0.75, 1.09, 1.02, "2016.12.09 00:00", "2017.03.03 00:00"},   //5 0.00+0.5, 3350 / 6.25*2=12.5, http://www.cmegroup.com/trading/fx/g10/euro-fx_performance_bonds.html
   { "GBPUSD", 0.75, 5160, "10:30", 1.00, 1.28, 1.235, "2016.12.09 00:00", "2017.03.03 00:00"},   //5 0.25+0.5, 3600 6.25 http://www.cmegroup.com/trading/fx/g10/british-pound_performance_bonds.html
   { "USDJPY", 0.85, -0.0003600, "02:30", 0.85, 117.647, 110.497, "2016.12.09 00:00", "2017.03.03 00:00"},             //3 0.5+-0.1, 4500 12.5 http://www.cmegroup.com/trading/fx/g10/japanese-yen_performance_bonds.html#sortField=exchange&sortAsc=true&sector=FX&exchange=CME&clearingCode=J1
   { "USDCAD", 1.25, -0.01550, "15:30", 1.25, 1.36054, 1.27389, "2016.12.09 00:00", "2017.03.03 00:00"},             //5 0.5+0.5, 1750 10   http://www.cmegroup.com/trading/fx/g10/canadian-dollar_performance_bonds.html#sortField=exchange&sortAsc=true&sector=FX&exchange=CME&clearingCode=C1
   { "AUDUSD", 2.25, 1800, "00:30", 2.25, 0.77, 0.72, "2016.12.09 00:00", "2017.03.03 00:00"},                  //5 1.50+0.5, 2000 10   http://www.cmegroup.com/trading/fx/g10/australian-dollar_performance_bonds.html
   { "NZDUSD", 2.50, 1700, "22:30", 2.5, },                  //5 2.00+0.5, 1900 10   http://www.cmegroup.com/trading/fx/g10/new-zealand-dollar_performance_bonds.html
   { "USDCHF", 1.00, -0.02640, "10:30", 1.5, 1.11111, 0.98522, "2016.12.09 00:00", "2017.03.03 00:00"},            //5 0.5+-0.75, 3600 12.5   http://www.cmegroup.com/trading/fx/g10/

   { "EURGBP", 0, 2560, "10:30", 0.88259, 0.79688, },            //  3575 / 12.5 http://www.cmegroup.com/trading/fx/g10/

   { "XAUUSD", 0,    3750 },                  // 4000      http://www.cmegroup.com/trading/fx/g10/euro-fx_performance_bonds.html#sortField=exchange&sortAsc=true&exchange=CMX&sector=METALS&clearingCode=GC
   { "#NQ100", 0,    1800 },                  // 18000 25 0.25 http://www.cmegroup.com/trading/equity-index/us-index/nasdaq-100_performance_bonds.html
   { "#SP500", 0,    920  },                  // 23000 25 0.1  http://www.cmegroup.com/trading/equity-index/us-index/sandp-500_performance_bonds.html
   { "AUDCAD"},
   { "AUDJPY"},
   { "AUDNZD"},
   { "GBPCHF"},
   { "USDBRL"},
   { "GBPJPY"},
   { "EURAUD", 0,0, "10:30"},
   { "EURCAD", 0,0, "10:30"},
   { "EURNOK", 0,0, "10:30"},
   { "USDCHN"},
   { "CADJPY"},
   { "USDCZK"},
   { "USDHUF"},
   { "USDILS"},
   { "CZKEUR"},
   { "EURSEK", 0,0, "10:30"},
   { "USDMXN"},
   { "USDPLN"},
   { "HUFEUR"},
   { "EURCHF", 0,0, "10:30"},
   { "USDRUB"},
   { "EURJPY", 0,0, "10:30"},
   { "USDSEK"},
   { "CHFJPY"},
   { "NOKUSD"},
   { "PLNEUR"},
   { "GOLD"},
   { "BRENT"},
   { "CL"},
};

InfoStruFileNKZ InffO[150];            // НКЗ из файла
InfoStruFileBU InfBU[50];
InfoStruFileBU InfBU_USD[50];
InfoStruFileZL InfZL_USD[30];
InfoStruFileZL InfZL_EUR[30];
InfoStruFileZL InfZL_RUR[30];
InfoStruFileZL InfZL_ALF[30];
InfoStruFileZL InfZL_INS[30];
InfoStruFileNKZ_S NKZZ[900];
InfoStruFileNKZ_New NKZ_NEW[900];
ZonkiStruct Zonki[10];

// Переменные для считывания внешнего файла
int      Handle,                             // Файловый описатель
         UTC,                                // Отклонение от UTC
         Utc_Usd,                                // Отклонение USD
         Utc_Eur,                                // Отклонение EUR
         Utc_Rur,                                // Отклонение от RUR
         Utc_Alf,                                // Отклонение от ALF
         Utc_Ins;                                // Отклонение от Ins
string   File_Name_NKZ       = "nkz.csv",        // Имя файла
         File_Name_BU        = "bu.csv",        // Имя файла
         File_Name_UTC       = "utc.csv",        // Имя файла
         Instr,                              // Название инструмента из файла
         Instr_Symbol,                       // название инструмента на графике
         Str_DtTm,                           // Дата и время (строка)
         Str_Marjin,                         // Маржинальные условия (строка)
         Str_Cena_Min,                       // Цена минимальная (строка)
         Str_UTC,                       // Отклонение от UTC(GMT) (строка)
         Str_Procent;                       // Процентная ставка (строка)
datetime Dat_DtTm;                           // Дата и время (дата)
datetime dat_dtTm_new, dat_dtTm;
double   Marjin, Cena_Min, B_Procent;                   // Данные из файла
double   marja_new,cenna;
int InffoKeyy, InffoKeyNew, Key=0;
string  musor, konek[900];
input string i22 = "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@";// ГОРЯЧИИ КЛАВИШИ
extern int            HotKey1         = 49;                // Клавиша 1 для рисования ДКЗ по процентной ставке
extern int            HotKey2         = 50;                // Клавиша 2 для рисования дробных НКЗ
extern int            HotKey3         = 51;                // Клавиша 3 для рисования НКЗ
// Добавим для МКЗ
int      HotKey29        = 76;                // Клавиша L для рисования МКЗ
input int      HotKey30        = 192;         // Клавиша Ё для укорачивания зон
input int      HotKey31        = 87;                // Клавиша W рисование угла Ганна от предыдущего дня
int      HotKey32        = 0;                 // Клавиша A для рисования дробных НКЗ от будущей маржи(65)
int      HotKey33        = 0;                 // Клавиша S для рисования НКЗ от будущей маржи(83)
//int      HotKey34        = 73;              // Клавиша I рисование уровней открытия Америки
//int      HotKey35        = 75;              // Клавиша K рисование уровней открытия Америки
input int      HotKey36        = 81;          // Клавиша Q Построить кнопочную панель от зоны 

//Конец для МКЗ
input int      HotKey4         = 16;                // Клавиша Shift удаление зоны, указатель мыши должен быть наведен на зону
input int      HotKey5         = 82;                // Клавиша R выравнивание выделенной трендовой линии по горизонтали (повторное нажатие для выровненной линии снимает выделение)
input int      HotKey6         = 66;                // Клавиша B нарисовать банковский уровень
input int      HotKey7         = 53;                // Клавиша 5 рисование/удаление уровней средненевного хода цены, от мин. дня вверх на ATR и от макс. дня вниз на ATR. Уровни текущего дня корректируются автоматически
input int      HotKey8         = 54;                // Клавиша 6 рисование/удаление уровней Hi и Low дня.
input int      HotKey9         = 17;                // Клавиша Ctrl двойное нажатие включает режим рисования паттернов, одинарное выключает, Esc - отменяет нарисованное
extern int            HotKey10        = 52;                // Клавиша 4 рисование угла Ганна, указатель мыши должен быть под или над пиком
input int      HotKey11        = 55;                // Клавиша 7 установка уровня, для отслеживания коррекции, указатель мыши должен быть под или над пиком
//int      HotKey12        = 56;                // Клавиша 8 рисование уровней закрытия Америки
input int      HotKey13        = 9;                 // Клавиша Tab удлинить зону находящуюся под указателем мыши на кол. пикселей заданое в ZonaLengthPlus
input int      HotKey14        = 89;                // Клавиша Y замена Ctrl-Y для вкл./выкл. отображения разделителей периодов
input int      HotKey15        = 85;                // Клавиша U вкл./выкл. торговых уровней. Если вы выключили их и забыли, то через Utime секунд, они сами включатся (на всякий случай)
input int      HotKey16        = 32;                // Клавиша Пробел открыть окно графика с которого пришло сообщение во встроенное Alert окно (ZonaAlertMode = 1)
input int     HotKey17        = 48;                // Клавиша 0 смена цвета зоны под указателем мыши, список цветов в ListColorZone
input int      HotKey18        = 57;                // Клавиша 9 вкл./выкл. ZonaAlertSound (Оповещать звуковым сигналом появление сообщений)
int      HotKey19        = 220;               // Клавиша \ над "Enter" сделать скриншот графика в папку в виде даты
int      HotKey20        = 221;               // Клавиша ] над "Enter" сделать скриншот графика в отдельную папку заданную переменной ScreenDir

input int      HotKey21        = 79;                // Клавиша O вкл./выкл. описание объектов
int      HotKey22        = 84;                // Клавиша T -> Ctrl+T показать окно терминала (список сделок, ордеров)
int      HotKey23        = 0;                // Клавиша Z - увеличение масштаба(90)
int      HotKey24        = 0;                // Клавиша X - уменьшение масштаба(88)
int      HotKey25        = 68;                // Клавиша D - увеличение таймфрейма
int      HotKey26        = 69;                // Клавиша E - уменьшение таймфрейма
int      HotKey27        = 72;                // Клавиша H - установить старший рабочий таймфрейм
int      HotKey28        = 77;                // Клавиша M - установить младший рабочий таймфрейм

//--------------------------------------------------------------------

input int      sound           = 0;            // Звуковое оповещение при создании объектов 1 - включено, 0 - выключено
input   int   ZonaAlert       = 1;             // 1 - Показывать окно при заходе в зону, 0 - не показывать
extern int            ZonaAlertSound  = 0;        // 1 - Оповещать звуковым сигналом появление сообщений, 0 - не оповещать (работает когда включен ZonaAlert = 1)
input int      ZonaAlertMode   = 1;                 // 1 - Встроенное окно сообщений, 0 -  стандартное диалоговое окно 
int      ZonaAlertType   = 0;                 // 1 - Моментально уведомлять через рассылку событий (если терминал подвисает иногда, то ставим ZonaAlertType = 0; подвисать не будет)
int      ZonaAlertFlash  = 1;                 // 1 - Выделить кнопку терминала на панели задач, 2 - мигать кноп. терм. на панели задач (когда окно терминала не активно), 0 - ни чего не делать

int      ZonaLengthPlus  = 90;                // Количество пикселей для удлинения зоны под указателем мыши по горячей клавише HotKey13
input int     Utime           = 300;               // Время в сек., по истечении которого автоматически включать торговые уровни, если они были выключены по гор. клавише HotKey15
int      ScreenWidth     = 1700;              // Ширина скриншота
int      ScreenHeight    = 800;               // Высота скриншота
string   ScreenDir       = "_ТВ";             // Отдельная папка для скринов по клавише HotKey20 (_ТВ - интересные точки входа)

int      ListColorZone[] = {                  // Список цветов зон, для смены цвета зоны под указателем мыши по гор. клавише HotKey17
                           clrSandyBrown,
                           clrGold,
                           clrKhaki,
                           clrPlum,
                           clrRed,
                           clrCornflowerBlue,
                           clrDarkOrange,
                            C'182,225,252',
                            C'245,173,173',
                            clrDarkSeaGreen,
                            clrSilver,
                            clrWhite
                            
};

// Лёхины уровни (грааль)
input string i20 = "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@";       // УРОВНИ ПО НАТОРГОВКАМ
input bool       Alex_key           = false;          //вкл Лёхины уровни(двойной клик) и Зиг-Заг(двойной Ctrl)
input color      Alex_color_Hi      = C'191,100,215';       // - цвет на Мах
input color      Alex_color_Low     = C'43,213,115';         // - цвет на Мин
input int        Alex_width         = 2;              // - толщина линии
input bool       Alex_back          = false;          // - заливка зоны
int      Alex_length     = 100000;            // Длина (смещение по времени в секундах), если время уровня старше Alex_day
int      Alex_day        = 10;                // Кол. дней (когда протягивать уровень до текущего времени), если уровень старше то использовать Alex_length
int      Alex_timeframe  = ALL;               // Таймфрэймы на которых разрешить рисование уровней по двойному клику, см. выше примеры. M1|M5|M15; на таймфреймах M1 и M5 и M15
input int      Alex_click      = 2;                 //Кол-во кликов левой кнопкой мыши для рисования Лехиных уровней (граальных)
 
// ДКЗ зона
int      DKZ_color       = C'158,188,243';     // Цвет
int      DKZ_length      = 100000;            // Длина (смещение по времени в секундах)
int      DKZ_angle       = 0;//5000;          // Угол наклона линии (смещение по времени в секундах)
int      DKZ_timeframe   = OBJ_ALL_PERIODS;   // Таймфрэймы на которых отображать, см. выше примеры

// Добавим для МКЗ
int      MKZd_colorHi    = C'255,165,0';    // Цвет дробных зоны НКЗ от Hi
int      MKZd_colorLow   = C'30,144,255';    // Цвет дробных зоны НКЗ от Low
int      MKZ_timeframe   = OBJ_ALL_PERIODS;   // Таймфрэймы на которых отображать, см. выше примеры
int      MKZ_B_color         = clrBlack;           // Цвет линии
int      MKZ_B_width         = 1;                 // Толщина линии
int      MKZ_B_style         = 1;                 // Стиль линии
int      MKZ_B_back          = 1;                 // Рисовать линию на заднем плане - 1, на переднем - 0
int      MKZ_zona            = 1000;                 // Высота зоны
//Конец для МКЗ
input string i15 = "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@";                  // - РАСЧЕТ ЛОТА ОТ SL и Risk
input double      MaxRisk       = 3.5;	 // - максимальный риск в %   
input int      StopLoss      = 250;	 // - SL в пунктах   
input bool     st1            = false;      // - показывать строку цены минимального лота
input bool     st2            = false;      // - показывать строку SL от риска
input bool     st3            = false;      // - показывать строку цены за 1 пункт
input string i3 = "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@";                  // - НКЗ ЗОНА
input bool       NKZ_verch         = false;             // Следующая НКЗ от внешней границы
input color      NKZ_color       = C'255,201,157';	 // - цвет НКЗ 
input color      NKZd_colorHi_3    = C'240,216,151';    // - цвет дробных зоны 3/4 от Hi
input color      NKZd_colorLow_3   = C'240,216,151';    // - цвет дробных зоны 3/4 от Low
input color      NKZd_colorHi    = C'255,217,145';    // - цвет дробных зоны ДКЗ от Hi
input color      NKZd_colorLow   = C'255,217,145';    // - цвет дробных зоны ДКЗ от Low
input color      NKZd_colorHi_1    = C'223,211,145';    // - цвет дробных зоны 1/4 от Hi
input color      NKZd_colorLow_1   = C'223,211,145';    // - цвет дробных зоны 1/4 от Low
input int      NKZ_length      = 300000;            // * длина (смещение по времени в секундах)(300000)
input int      NKZ_angle       = 0;          // * угол наклона линии (смещение по времени в секундах)(5000)
int      NKZ_timeframe   = OBJ_ALL_PERIODS;   // Таймфрэймы на которых отображать, см. выше примеры
int      NKZ_mode        = 2;                 // 0 - рисовать наружу 5% и во внутрь 5%, 1 - рисовать зону 10% наружу, 2 - рисовать зону 10% во внутрь 

double   NKZd_list[]     = {0.25, 0.5}; // Список дробных зон, через запятую
int      NKZ_widthL      = 0;                 // Дополнительная линии, если значение = 0 то не рисовать
color      NKZ_colorL      = clrBlue;           // Цвет линии
int      NKZ_styleL      = 0;                 // Стиль линии

// Банковский уровень
int      B_auto          = 0;                 // Автоматически рисовать Б.уровни 1 - да, 0 - нет (учитывается список допустимых дней)
int      B_manual        = 1;                 // При ручном рисовании Б.уровня, учитывать ли список допустимых дней недели (список см. ниже) 1 - да, 0 - нет, рисовать уровень в любой день
int      B_days[]        = {3};         // Список допустимых дней для рисования Б.уровень (0-воскресенье, 1, 2, 3, 4, 5, 6-суббота) через запятую
int      B_length        = 432000;                 // Длина (смещение по времени в секундах), если 0 - то рисовать до конца текущего дня (432000 - Длина на 5 дней)
int      B_orderZ        = 1;                 // Колличество зон от Б.уровня 
extern color    B_colorZ        = clrOrange;         // Цвет зоны от Б.уровня
extern color    B_color         = clrOrange;           // Цвет линии
int      B_width         = 3;                 // Толщина линии
int      B_style         = 1;                 // Стиль линии
int      B_back          = 1;                 // Рисовать линию на заднем плане - 1, на переднем - 0
int      B_timeframe     = OBJ_ALL_PERIODS;   // Таймфрэймы на которых отображать, см. выше примеры
double   B_bankPercent   = 0;                // Банковский процент
input string i9 = "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@";       // АТР на экране
input int      ATR_hist        = 23;                // - количество дней для расчета ATR
input double   ATR_SL          = 0.3;               // - SL от АТР (30% = 0,3)
input int      X               = 10;                // - смещение вправо 
input int      Y               = 600;               // - смещение - вверх/ + вниз. 
input int      razm1           = 14;                // - размер шрифта обычный 
input int      razm2           = 14;                // - размер шрифта при ходе дня более АТР 
input bool     norm            = true;             // - привести АТР и Спред к 4 знаку 
input int      ATR_W1          = 0;                 // Пропускать последнюю неделю 1 - да, 0 - нет
input color      ATR_colorH      = clrRed;            // Цвет нижней линни идущей от хая вниз
input color      ATR_colorL      = clrGreen;          // Цвет верхней линни идущей от лоу вверх
input int      ATR_width       = 1;                 // Толщина линии
input int      ATR_style       = 1;                 // Стиль линии
int      ATR_back        = 1;                 // Рисовать линию на заднем плане - 1, на переднем - 0
int      ATR_timeframe   = OBJ_ALL_PERIODS;   // Таймфрэймы на которых отображать, см. выше примеры
double      ATR             = 0;
datetime      day             = 0;
double      ATR20             = 0;
int      hist             = 0;
int      lk                = 0;                 // Для проверки изменения маржи
datetime day_cme           = TimeCurrent();
int      chislo            = MathRand()%60+30;
input string i23 = "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@";       //HiLow
input int   HiLow_count     = 100;               // Количество дней для отображения
input color      HiLow_color     = clrSteelBlue;      // Цвет
input color      HiLow_colorF    = clrRed;            // Цвет пятницы
input int    HiLow_width     = 2;                 // Толщина линии
input int    HiLow_style     = 0;                 // Стиль линии
input int    HiLow_back      = 1;                 // Рисовать линию на заднем плане - 1, на переднем - 0
int      HiLow_timeframe = OBJ_ALL_PERIODS;   // Таймфрэймы на которых отображать, см. выше примеры

// Линия для рисования паттернов
input color      Zigzag_color    = SlateBlue;           // Линия рисования патерна Zig Zag
input int      Zigzag_width    = 2;                 // Толщина линии
input int      Zigzag_style    = 0;                 // Стиль линии
int      Zigzag_back     = 0;                 // Рисовать линию на заднем плане - 1, на переднем - 0

// Линия Ганна
input string i19 = "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@";       // ЛИНИЯ ГАННА
int      Gann_length     = 27000;            // Смещение второй точки в секундах (первая точка на пике)(100000)
double   Gann_Scale[]    = {2.0, 10, 20};      // Список углов через запятую ( / 10 для 4-х знака)
int      Gann_change     = 1;                 // Менять углы - 1, добавлять по очереди - 0
int      Gann_color      = clrBlue;           // Цвет
int      Gann_width      = 1;                 // Толщина линии
int      Gann_style      = 0;                 // Стиль линии
int      Gann_back       = 0;                 // Рисовать линию на заднем плане - 1, на переднем - 0
int      Gann_timeframe  = OBJ_ALL_PERIODS;   // Таймфрэймы на которых отображать, см. выше примеры
input int   Gann_k         = 1;                 // - поправочный коэф. на угол
// Уровень коррекции
input string i21 = "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@";// УРОВЕНЬ КОРРЕКЦИИ
int      Correct_length  = 7000;              // На сколько дальше протягивать линию от текущей цены (в секундах)
int      Correct_time    = 60 * 5;            // Колличество секунд между сигналами если цена то заходит, то выходит за уровень 50% коррекции
input color      Correct_color1  = C'190,190,190';    // Цвет наклонной линни 
input int      Correct_width1  = 1;                 // Толщина наклонной линии
input int      Correct_style1  = 2;                 // Стиль наклонной линии
int      Correct_back1   = 0;                 // Рисовать линию на заднем плане - 1, на переднем - 0
input color      Correct_color2  = clrRed;            // Цвет уровня 50%
input int      Correct_width2  = 2;                 // Толщина уровня 50%
input int      Correct_style2  = 0;                 // Стиль уровня 50%
int      Correct_back2   = 0;                 // Рисовать уровень на заднем плане - 1, на переднем - 0
input color      Correct_colorD  = clrBlue;           // Цвет дополнительных уровней
input int      Correct_widthD  = 1;                 // Толщина дополнительных уровней
input int      Correct_styleD  = 0;                 // Стиль дополнительных уровней
int      Correct_backD   = 0;                 // Рисовать уровень на заднем плане - 1, на переднем - 0
 double   Correct_listD[] = {50, 61.8, 76.5, 23.6, 38.2, 0, 100};    // Список дополнительных уровней в %, через запятую
string   Correct_FontN2  = "Arial";           // Название шрифта текста цены 50%
input int      Correct_FontS2  = 10;                // Размер шрифта текста цены 50%
input color    Correct_FontC2  = clrRed;            // Цвет текста цены 50%


input string i4 = "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@";       // УРОВНИ ОТКРЫТИЯ И ЗАКРЫТИЯ АМЕРИКИ
int      A_style1        = 0;                 // Стиль линии
int      A_back1         = 0;                 // Рисовать линию на заднем плане - 1, на переднем - 0
int      A_line2         = 0;                 // Рисовать наклонную линию - 1, не рисовать - 0
int      A_color2        = clrOrangeRed;      // Цвет линни (наклонная линия соединяющая закрытия сессий)
int      A_width2        = 2;                 // Толщина линии
int      A_style2        = 0;                 // Стиль линии
int      A_back2         = 0;                 // Рисовать линию на заднем плане - 1, на переднем - 0
int      A_timeframe     = OBJ_ALL_PERIODS;   // Таймфрэймы на которых отображать, см. выше примеры

//Уровни открытия америки
input string TerminalTime          = "GMT";      // * терминальное время по(RUR, USD, EUR, GMT, ALF, INS)
input int      delta          = 3;              // * разница от верхней строчки (+-1) 
input string Open_EUR          = "8:00";      // * время открытия Европы
input color    A_colorEO        = clrDarkTurquoise;            // * цвет линни Европы открытие
input string Close_EUR          = "16:29";      // * время закрытия Европы
input color    A_colorEZ        = clrDarkOliveGreen;            // * цвет линни Европы закрытие
input string Open_USD          = "9:30";      // * время открытия Америки
input color    A_colorAO        = clrDarkViolet;            // * цвет линни Америки открытие
input string Close_USD          = "15:59";      // * время закрытия Америки
input color    A_colorAZ        = clrRed;            // * цвет линни Америки закрытие
input int      AO_count         = 3;               // * количество дней для показа
input int      A_length2       = 18640;             // * длинна линии в секундах (86400)
input int      A_width1        = 3;                 // * толщина линии
int seeeV = 0;                                      // Ключ выбора для Америк 
int seeeA = 0;                                      // Ключ выбора для МКЗ от АТР  
int seeeOE = 0;                                      // Ключ текущего откр. Европы  
int seeeZE = 0;                                      // Ключ текущего закр. Европы  
int seeeOA = 0;                                      // Ключ текущего откр. Америки  
int seeeZA = 0;                                      // Ключ текущего закр. Америки  
int seeeKEY = 0;                                      // Ключ текущего дня  
datetime seeeOE_time = 0;                             // Время отк Европы
datetime seeeZE_time = 0;                             // Время зак Европы
datetime seeeOU_time = 0;                             // Время отк Америки
datetime seeeZU_time = 0;                             // Время зак Америки
double seeeOE_price = 0;                             // Цена отк Европы
double seeeZE_price = 0;                             // Цена зак Европы
double seeeOU_price = 0;                             // Цена отк Америки
double seeeZU_price = 0;                             // Цена зак Америки
 string i10 = "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@";       // УРОВНИ ОТКРЫТИЯ И ЗАКРЫТИЯ АМЕРИКИ ЗА ЗОНАМИ
 bool      strelochki        = false;                      // - стрелочки на истории
 string i11 = "-------------------------------------";       // Цена открытия и закрытия за 1/4
 bool      A_0_25_OE        = false;                 // - открытие Европы
 bool      A_0_25_ZE        = false;                 // - закрытие Европы
 bool      A_0_25_OU        = false;                 // - открытие Америки
 bool      A_0_25_ZU        = false;                 // - закрытие Америки
 string i12 = "-------------------------------------";       // Цена открытия и закрытия за ДКЗ
 bool      A_0_50_OE        = false;                 // - открытие Европы
 bool      A_0_50_ZE        = false;                 // - закрытие Европы
 bool      A_0_50_OU        = false;                 // - открытие Америки
 bool      A_0_50_ZU        = false;                 // - закрытие Америки
 string i16 = "-------------------------------------";       // Цена открытия и закрытия за ДКЗ
 bool      A_1_00_OE        = false;                 // - открытие Европы
 bool      A_1_00_ZE        = false;                 // - закрытие Европы
 bool      A_1_00_OU        = false;                 // - открытие Америки
 bool      A_1_00_ZU        = false;                 // - закрытие Америки
int      A_25_OE_key        = 0;                 // - ключ для однократной проверки
int      A_25_ZE_key        = 0;                 // - ключ для однократной проверки
int      A_25_OU_key        = 0;                 // - ключ для однократной проверки
int      A_25_ZU_key        = 0;                 // - ключ для однократной проверки
int      A_50_OE_key        = 0;                 // - ключ для однократной проверки
int      A_50_ZE_key        = 0;                 // - ключ для однократной проверки
int      A_50_OU_key        = 0;                 // - ключ для однократной проверки
int      A_50_ZU_key        = 0;                 // - ключ для однократной проверки
int      A_10_OE_key        = 0;                 // - ключ для однократной проверки
int      A_10_ZE_key        = 0;                 // - ключ для однократной проверки
int      A_10_OU_key        = 0;                 // - ключ для однократной проверки
int      A_10_ZU_key        = 0;                 // - ключ для однократной проверки

input string i18 = "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@";       //  ВСТРОЕННОЕ АРЛЕТ ОКНО
input int      AlertHeight     = 137;               // Высота окна
input int      AlertWidth      = 355;               // Ширина окна
input color      AlertBackClr    = C'230,230,230';    // Цвет фона окна
input color      AlertBorderClr  = clrBlack;          // Цвет рамки окна
int      AlertBorderSt   = 0;                 // Стиль рамки окна
int      AlertBorderWid  = 1;                 // Толщина рамки окна
int      AlertICount     = 6;                 // Количество строк сообщ. в окне
int      AlertStrLen     = 37;                // Максимальная длина строки (что бы не вылазила за рамки)
input int      AlertFontSize   = 10;                // Размер шрифта сообщений
input color      AlertFontClr    = clrGray;           // Цвет текста сообщений
string   AlertFont       = "Arial";           // Шрифт сообщений
input color      AlertFontClrNew = clrBlack;          // Цвет текста новых сообщений
string   AlertFontNew    = "Arial Black";     // Шрифт новых сообщений
input color      AlertFontClrOP  = clrBlue;           // Цвет текста при окрытии ордера
input color      AlertFontClrP   = clrGreen;          // Цвет текста при закрытии ордера с профитом
input color      AlertFontClrL   = clrRed;            // Цвет текста при закрытии ордера с убытком

// Звуковое оповещение
string   sound_Error     = "expert.wav";      // Звук при ошибке
string   sound_Zona      = "tick.wav";        // Звук при создании и удалении зоны
string   sound_Blevel    = "alert2.wav";      // Звук при создании банковского уровня
string   sound_Correct   = "wait.wav";        // Звук когда цена зашла за 50% коррекции или в зону
string   sound_Screen    = "news.wav ";       // Звук при создании скриншота
string   sound_Order     = "ok.wav";          // Звук при изменение списка открытых ордеров

// Линия для рисования изменения маржи
double      Marj_color    = clrBlue;               // Цвет
double      Marj_width    = 2;                 // Толщина линии
double      Marj_style    = 0;                 // Стиль линии
double      Marj_back     = 1;                 // Рисовать линию на заднем плане - 1, на переднем - 0

input string i5 = "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@";// НАСТРОЙКИ КНОПОК
input int      button_click      = 3;                 // * количество кликов мыши для кнопочной панели
input int button_widths = 60;                   // * ширина кнопок
input int button_heights = 20;                   // * высота кнопок
input int button_x_distances = 1;                   // * расстояние между кнопками по горизонтали
input int button_y_distances = 1;                   // * расстояние между кнопками по вертикали
input int button_fontsize = 10;                   // * размер шрифта
input color button_color = clrWhite;                   // * цвет шрифта
input bool button_bgcolor_key = false;                   // * использовать данный фон на все кнопки
input color button_bgcolor = clrSilver;                   // * цвет фона
input color button_bdcolor = clrBlack;                   // * цвет рамки
int seee = 0;                                      // * ключ выбора маржи 
datetime button_time = 0;                                      // Время вершинки для кнопок 
double button_price = 0;                                      // Цена вершинки для кнопок 
int button_HiLow = 0;                                      // Вершинка или впадина zonaUpdateInfo
double button_zonaUpdateInfo = 0;                                      // Зона
int button_zonaUpdate = 0;                                      // Зона
string button_name = "";                                      // Имя зоны
long button_lparam = 0;                                      // Х - координата или код клавиши клавиатуры
int bx,by;                                               // Для координат кнопок
long l = 0;                                           // Дата изменения файла

input string i6 = "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@";     // СРЕДНЯЯ ВОЛАТИЛЬНОСТЬ ПО МЕСЯЦАМ (МКЗ)
input string i7 = "-------------------------------------";     // ПАРАМЕТРЫ ДЛЯ РАСЧЕТОВ
input timfrim vol_period = Per9;                            //  - период для расчета   
input int vol_kol_period = 10;                                 //  - количество периодов для расчета среднего хода (10-12)
input int vol_kol_zon = 10;                                   //  - количество отображаемых зон
input string i8 = "-------------------------------------";     // НАСТРОЙКИ ЗОН
input color vol_col_H = clrOrange;                             //  - цвет верхней зоны
input color vol_col_L = clrDodgerBlue;                         //  - цвет нижней зоны
input color vol_col_net = clrRed;                              //  - цвет неотработанной зоны
input bool vol_zalivka = false;                                //  - заливка зоны 
input int vol_line_stil = 0;                                   //  - стиль границы
input int vol_line_tol = 2;                                    //  - толщина границы
input double vol_zone_visota = -500;                           //  - высота зоны в пунктах (500)
input string i17 = "-------------------------------------";     // ДОП. НАСТРОЙКИ ЗОН TEST
input timfrim vol_period_test = Per9;                            //  - период для расчета   
input double vol_zone_proc = 0.5;                              //  - процент для внутренней зоны от АТР
input double vol_zone_visota_test = -500;                           //  - высота зоны в пунктах (500)
input int vol_baza_styl = 1;                                   // - стиль линии Баланса
int vol_mkz_atr = 0;                                           //  - заливка зоны 
int vol_timeframe = OBJ_ALL_PERIODS;   // Таймфрэймы на которых отображать, см. выше примеры
int vol_key = 0;                             // Еще не считали сегодня (0)
int vol_atr = 0;                             // Значение волатильности
datetime vol_time = 0;                       // Дата нулевой свечи для проверки

int      EasyOpenOrder   = 0;                 // Для совместной работы с EasyOpenOrder советником 1 - вкл. 0 - выкл.
input string i1 = "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@";        //УСТАНОВИТЬ СТАРШИЙ РАБОЧИЙ ТАЙМФРЕЙМ
input int      H_time_frame    = 240;                // Таймфрэйм(в минутах) для клавиши HotKey27 (H)
input int      H_scale         = 1;                 // Маштаб графика(от 0 до 5) для клавиши HotKey27 (H)

input string i2 = "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@";        // УСТАНОВИТЬ МЛАДШИЙ РАБОЧИЙ ТАЙМФРЕЙМ
input int      M_time_frame    = 30;                 // Таймфрэйм(в минутах) для клавиши HotKey28 (M)
input int      M_scale         = 1;                 // Маштаб графика(от 0 до 5) для клавиши HotKey28 (M)
input string i13 = "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@";       // ТЕСТ
input string i14 = "-------------------------------------";       // Зона от АТР
input int      kol_ATR        = 23;                      // - количество дней для АТР
input color    col_ATR        = clrLightGreen;                      // - цвет зонки

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

int      MouseX, MouseY  = 0; 
int      InfoKey         = -1;   // Индекс текущего инструмента в массиве инструментов (валютные пары)
int      InffoKey        = -1;   // Индекс текущего инструмента в массиве инструментов (валютные пары)Для НКЗ
datetime BankTime        = NULL;
int      ModeZigzag      = 0;
int      Utimelocal      = 0;    // Счетчик секунд, для показа торговых уровней
struct   ListRectStruct { string name; datetime time; } ListRect[];

int      AtrFL           = 1;
int      HiLowFL         = 1;
int      CorrectFL       = 1;
int      RectFL          = 1;
int      EasyOpenOrder_c = 0;
int      key_updat_nkz     = 0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
{
   MathSrand(GetTickCount());
   chislo = MathRand()%60+30;
   GlobalVariableSet("webcme",0);
   ////////////////////////////////////////////////////
   GlobalVariableDel("DN_" + DoubleToString(ChartID(),0));
   ////////////////////////////////////////////////////
   if (AccountInfoInteger(ACCOUNT_LOGIN) == 78748)
   {
      for (int i = ArraySize(Info) - 1; i >= 0; i--) Info[i].name += "_e";

  B_colorZ     = C'128,191,255';   // Цвет зоны от Б.уровня
      
      HotKey1       = 49;             // Клавиша NaN для рисования ДКЗ по процентной ставке
      HotKey2       = 66;            // Клавиша B для рисования дробных НКЗ
      HotKey3       = 78;            // Клавиша N для рисования НКЗ
      HotKey10      = 52;             // Клавиша NaN рисование угла Ганна, указатель мыши должен быть под или над пиком
      HotKey23      = 70;            // Клавиша F - увеличение масштаба
      HotKey24      = 71;            // Клавиша G - уменьшение масштаба
      EasyOpenOrder = 0;             // Для совместной работы с EasyOpenOrder советником
      
   }
   ///////////////////////////////////////////////////////////////////////////////////////////////
   //IndicatorShortName("DkzNkzMaker");
   if (UninitializeReason() != REASON_CHARTCHANGE) // При смене таймфрэйма не выполняем
   {
      ChartSetInteger(0, CHART_EVENT_OBJECT_CREATE, 1);
      ChartSetInteger(0, CHART_EVENT_OBJECT_DELETE, 1);
      ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, 1);
      ChartSetInteger(0, CHART_SHOW_TRADE_LEVELS, true); 

      if (ObjectCreate(0, "MouseInfo", OBJ_LABEL, 0, 0, 0)) ObjectSetString(0, "MouseInfo", OBJPROP_TEXT, " ");
      ObjectSet("MouseInfo", OBJPROP_BACK, false);                    // Рисовать объект в фоне
      ObjectSet("MouseInfo", OBJPROP_SELECTED, false);                // Снять выделение с объекта
      ObjectSet("MouseInfo", OBJPROP_SELECTABLE, false);              // Запрет на редактирование
      ObjectSet("MouseInfo", OBJPROP_HIDDEN, true);                   // Скроем (true) или отобразим (false) имя графического объекта в списке объектов
      ObjectSetString(0,"MouseInfo", OBJPROP_FONT, "Arial");
      ObjectSet("MouseInfo", OBJPROP_FONTSIZE, 10);
      ObjectSet("MouseInfo", OBJPROP_COLOR, clrRed);

      InitRect("ALL_OBJECTS_RECT_CORRECT");
      GlobalVariableSet("DN_new_event", 0);
      GlobalVariableSet("DN_ZonaAlertSound", ZonaAlertSound);
      
      // Для сохранения значения Utimelocal при смене таймфрейма
      ObjectCreate(0, "Utimelocal", OBJ_TEXT, 0, 0, 0);
      ObjectSet("Utimelocal", OBJPROP_TIMEFRAMES , EMPTY);            
      ObjectSet("Utimelocal", OBJPROP_HIDDEN, true);
      AlertInfoInit();
   }
   
   // Восстанвим значение счетчика секунд
   Utimelocal = (int)ObjectGet("Utimelocal", OBJPROP_TIME1);
   // Получим дескриптор(window handle) окна терминала и заполним pfwi, для мигания
   if (IsDllsAllowed())
   {
      int hwnd = WindowHandle(_Symbol, _Period);
      int hwnd_Terminal = 0;
      while(!IsStopped())
      {
         hwnd = GetParent(hwnd);
         if(hwnd == 0) break;
         hwnd_Terminal = hwnd;
      }
      pfwi.cbSize = sizeof(flash);
      pfwi.hwnd = hwnd_Terminal;
   }   
   // Поиск нужного инструмента в списке инструментов и получения bankTime
   for (int i = ArraySize(Info) - 1; i >= 0; i--)
   {
      if (Info[i].name == StringSubstr(_Symbol,0,6)) 
      {
         BankTime = StringToTime(Info[i].bankTime);
         InfoKey = i;
         break;
      }
   }
   if (ObjectGetString(0, "MouseInfo", OBJPROP_TEXT) == "/\\/\\/\\")   ModeZigzag = 1;
   ZonaAlertSound = (int)GlobalVariableGet("DN_ZonaAlertSound");
   EventSetTimer(1);
   //if (_Symbol == "GBPUSD_e") { AlertInfoAdd(findChart("EURUSD_e"), "тест...", clrBlack); }
   ObjectCreate ("tabl"+ IntegerToString(1), OBJ_LABEL, 0, 0, 0); 
   ObjectSet( "tabl"+ IntegerToString(1), OBJPROP_XDISTANCE, 0+X );
   ObjectSet( "tabl"+ IntegerToString(1), OBJPROP_YDISTANCE, 80+Y );
   ObjectSet( "tabl"+ IntegerToString(1), OBJPROP_BACK,false); 
   ObjectSet ("tabl"+IntegerToString(1), OBJPROP_ANGLE, 0);
   ATR_na_monitor();
   ObjectCreate ("tabl"+ IntegerToString(2), OBJ_LABEL, 0, 0, 0); 
   ObjectSet( "tabl"+ IntegerToString(2), OBJPROP_XDISTANCE, 0+X );
   ObjectSet( "tabl"+ IntegerToString(2), OBJPROP_YDISTANCE, 100+Y );
   ObjectSet( "tabl"+ IntegerToString(2), OBJPROP_BACK,false); 
   ObjectSet ("tabl"+IntegerToString(2), OBJPROP_ANGLE, 0);
   ObjectSet( "tabl"+ IntegerToString(2), OBJPROP_COLOR, clrBlack);
   ObjectSet( "tabl"+ IntegerToString(2), OBJPROP_FONTSIZE, razm1);
   Spred();
   int ss = 100;
   if(st1 == true) ss += 20;  
   ObjectCreate ("tabl"+ IntegerToString(3), OBJ_LABEL, 0, 0, 0); 
   ObjectSet( "tabl"+ IntegerToString(3), OBJPROP_XDISTANCE, 0+X );
   ObjectSet( "tabl"+ IntegerToString(3), OBJPROP_YDISTANCE, ss+Y );
   ObjectSet( "tabl"+ IntegerToString(3), OBJPROP_BACK,false); 
   ObjectSet ("tabl"+IntegerToString(3), OBJPROP_ANGLE, 0);
   ObjectSet( "tabl"+ IntegerToString(3), OBJPROP_COLOR, clrBlack);
   ObjectSet( "tabl"+ IntegerToString(3), OBJPROP_FONTSIZE, razm1);
   if(st2 == true) ss += 20;  
   ObjectCreate ("tabl"+ IntegerToString(4), OBJ_LABEL, 0, 0, 0); 
   ObjectSet( "tabl"+ IntegerToString(4), OBJPROP_XDISTANCE, 0+X );
   ObjectSet( "tabl"+ IntegerToString(4), OBJPROP_YDISTANCE, ss+Y );
   ObjectSet( "tabl"+ IntegerToString(4), OBJPROP_BACK,false); 
   ObjectSet ("tabl"+IntegerToString(4), OBJPROP_ANGLE, 0);
   ObjectSet( "tabl"+ IntegerToString(4), OBJPROP_COLOR, clrBlack);
   ObjectSet( "tabl"+ IntegerToString(4), OBJPROP_FONTSIZE, razm1);
   if(st3 == true) ss += 20;  
   ObjectCreate ("tabl"+ IntegerToString(5), OBJ_LABEL, 0, 0, 0); 
   ObjectSet( "tabl"+ IntegerToString(5), OBJPROP_XDISTANCE, 0+X );
   ObjectSet( "tabl"+ IntegerToString(5), OBJPROP_YDISTANCE, ss+Y );
   ObjectSet( "tabl"+ IntegerToString(5), OBJPROP_BACK,false); 
   ObjectSet ("tabl"+IntegerToString(5), OBJPROP_ANGLE, 0);
   ObjectSet( "tabl"+ IntegerToString(5), OBJPROP_COLOR, clrBlack);
   ObjectSet( "tabl"+ IntegerToString(5), OBJPROP_FONTSIZE, razm1);
   InfoMarjin();
//   info_file();
//   if( l > 0 && TimeDayOfYear((datetime)l) < TimeDayOfYear(TimeCurrent())) webb();         //Год не сможет перескочить, как вариант удалить cme.csv
//   Update_U();
   Read_File_NKZ();
   Read_File_BU();
   Read_File_ZL();
   Gde_Zonki();
   Poisk();
Comment("DkzNkzMkz");
   }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectSet("Utimelocal", OBJPROP_TIME1, Utimelocal);

   if (reason == REASON_REMOVE) // Если удаляем индикатор
   {
      ChartSetInteger(0, CHART_SHOW_TRADE_LEVELS, true);
      ObjectDelete("MouseInfo");
      DeleteByPrefix("LR_");
      DeleteByPrefix("AlertInfo");
      DeleteByPrefix("Correct");
      DeleteByPrefix("Utimelocal");
   }
}
 
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
void start()
{
   if (BankTime && B_auto && ArraySize(B_days))
   {
      BankTime = datetime(TimeToString(TimeHour(BankTime)) + ":" + TimeToString(TimeMinute(BankTime)));
      if (TimeCurrent() >= BankTime)
      {
         int dW = TimeDayOfWeek(BankTime);
         int ok = 0;
         for (int i = ArraySize(B_days) - 1; i >= 0; i--)
            if (dW == B_days[i]) { ok = 1; break; }
         if (ok)
         {
            ok = iBarShift(NULL, PERIOD_M1, BankTime, true);
            if (ok != -1) DrawBank(BankTime, iOpen(NULL, PERIOD_M1, ok), Info[InfoKey].bankPercent);
         }
      }
   }
   if (AtrFL)     DrawATR();
   if (HiLowFL)   DrawHiLow();
   if (CorrectFL) DrawCorrect();
   if (RectFL)    AlertRect();
   ATR_na_monitor();
   Spred();
   InfoMarjin();
   if(vol_key) Vol_MKZ();
   if(seeeOE == 1 || seeeZE == 1 || seeeOA == 1 || seeeZA == 1) Op_Cl_E_A_Seg();    
   //Отложенный запуск
   if (TimeCurrent() - day_cme > chislo) 
   {
      chislo = MathRand()%100+250;
      day_cme = TimeCurrent();
      l = 0;
      info_file();
      if(l > 0 && TimeDayOfYear((datetime)l) != TimeDayOfYear(TimeCurrent()) && GlobalVariableGet("webcme") == 0) {GlobalVariableSet("webcme",1); webb();}         
   }
   if(GlobalVariableGet("webcme") == 2)
      {
      GlobalVariableSet("webcme",3);
//      info_file();
//      if(TimeDayOfYear((datetime)l) == TimeDayOfYear(TimeCurrent()))
//         {
         int key_Up = Update_U();
         Read_File_NKZ();
         Read_File_BU();
         Read_File_ZL();
         Poisk();
//Alert(key_Up);
         if(key_Up == 0) GlobalVariableSet("webcme",0); else GlobalVariableSet("webcme",2);
//         }
      }
   if(key_updat_nkz) Read_File_NKZ();
   }

//+------------------------------------------------------------------+
//| Обработчик события Timer                                         |
//+------------------------------------------------------------------+
void OnTimer()
{
   if (!ChartGetInteger(0, CHART_BRING_TO_TOP))
   {
      if (ObjectGet("AlertInfoRect", OBJPROP_TIMEFRAMES) == OBJ_ALL_PERIODS)
         AlertInfoHide();
   }
   else if ((GlobalVariableGet("DN_new_event") && ObjectGet("AlertInfoRect", OBJPROP_TIMEFRAMES) == EMPTY) || GlobalVariableGet("DN_new_event") == 2) 
      AlertInfoShow();
      
   if (Utimelocal && ((TimeLocal() - Utimelocal) > Utime))
   {
      Utimelocal = 0;
      ChartSetInteger(0, CHART_SHOW_TRADE_LEVELS, true);
      ChartRedraw();
   }
   
   if (ZonaAlert && ChartID() == ChartFirst() && AccountBalance())
   {
      static int Orders_Old[30], count_Old = -1;
      static int Orders_New[30], count_New;
      string mess;
   
      count_New = 0;
      for (int i = OrdersTotal() - 1; i >= 0; i--) 
         if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            if (OrderType() == OP_BUY || OrderType() == OP_SELL) 
               Orders_New[count_New++] = OrderTicket();
      if (count_Old != -1)
      {
         int i,j;
         for ( i = 0; i < count_Old; i++) 
         {
            for (j = 0; j < count_New; j++) 
               if (Orders_Old[i] == Orders_New[j]) break;
            if (j == count_New)
            {
               if (OrderSelect(Orders_Old[i], SELECT_BY_TICKET))
                  mess = "Закрылся ордер на графике: " + OrderSymbol();
               else
                  mess = "Закрлыся ордер: #" + IntegerToString(Orders_Old[i]);
               int clr = AlertFontClrL;
               if (OrderProfit() + OrderCommission() + OrderSwap() >= 0) clr = AlertFontClrP;
               if (ZonaAlertMode)
                  AlertInfoAdd(findChart(OrderSymbol()), mess, clr);
               else
                  Alert(mess);
               if (ZonaAlertSound) PlaySound(sound_Order);
            }
         }
         for ( i = 0; i < count_New; i++) 
         {
            for (j = 0; j < count_Old; j++) 
               if (Orders_New[i] == Orders_Old[j]) break;
            if (j == count_Old)
            {
               if (OrderSelect(Orders_New[i], SELECT_BY_TICKET))
                  mess = "Открылся ордер на графике: " + OrderSymbol();
               else
                  mess = "Открылся ордер: #" + IntegerToString(Orders_Old[i]);
               if (ZonaAlertMode)
                  AlertInfoAdd(findChart(OrderSymbol()), mess, AlertFontClrOP);
               else
                  Alert(mess);
               if (ZonaAlertSound) PlaySound(sound_Order);
            }
         }
      }
      ArrayCopy(Orders_Old, Orders_New);
      count_Old = count_New;
   }
   start();
}

//+------------------------------------------------------------------+
//| Есть ли ордер под указателем мыши                                |
//+------------------------------------------------------------------+
int isMouseOrder()
{            
   int x, y;
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if (OrderSymbol() == _Symbol)
         {
            ChartTimePriceToXY(0, 0, TimeCurrent(), OrderOpenPrice(), x, y);
            if (MathAbs(MouseY - y) < 10)
            {
               if (OrderType() == OP_BUY || OrderType() == OP_SELL) return 1; else return 2;
            }
         }
      }
   }
   return 0;            
}

//+------------------------------------------------------------------+
//| Обработка событий ChartEvent                                     |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,         // идентификатор события  
                  const long& lparam,   // параметр события типа long
                  const double& dparam, // параметр событ3ия типа double
                  const string& sparam  // параметр события типа string
                 )
{
   int sub_window;
   static datetime ZigzagTime  = 0;
   static double   ZigzagPrice = 0;
   static string   ZigzagName  = "";
   static int      ZigzagIndex = 0;
   static uint     double_ctrl;
   
   // Событие при переключение окон, когда окно развернуто на весь терминал
   if (id == 9) OnTimer();

   // Включение выключение звука
   if (id == CHARTEVENT_CUSTOM + 2) { ZonaAlertSound = (int)lparam; return; }
   
   // Показать/обновить встроенное Алерт окно
   if (id == CHARTEVENT_CUSTOM + 3) { AlertInfoShow(); return; }

   if (id == CHARTEVENT_OBJECT_CREATE) { InitRect(sparam); return; }
   if (id == CHARTEVENT_OBJECT_DELETE) { InitRect(); return; }
   if (id == CHARTEVENT_OBJECT_DRAG)                                       // При перенесении зоны НКЗ, она переместица только горизонтально
      {
      if(StringSubstr(sparam, 0, 3) == "NKZ")
         {
         int x;
         double pricH, pricL, Tim = -1;
         string name;
         string opis = ObjectGetString(0,sparam,OBJPROP_TEXT);
         for( x = 0; StringLen(opis) > x; x++)
            {
            if(StringSubstr(opis,x,1) == "[") break;
            }
         if(x != 0)
            {
            pricH = NormalizeDouble(StringToDouble(StringSubstr(opis,x+1,7)),_Digits);
            pricL = NormalizeDouble(StringToDouble(StringSubstr(opis,StringLen(opis)-8,7)),_Digits);
            ObjectSet(sparam,OBJPROP_PRICE1,pricH);
            ObjectSet(sparam,OBJPROP_PRICE2,pricL);
            ObjectSet(sparam,OBJPROP_SELECTED,false);
            for (int i = ObjectsTotal() - 1; i >= 0; i--)                                 // Найдем палку от зоны и скорректируем ее
               {
               if (ObjectType(name = ObjectName(i)) == OBJ_TREND)
                  {
                  if (StringSubstr(name,0, 24) == StringSubstr(sparam,0, 24))
                     {
                     if(StringSubstr(sparam,25, 1) == "H")
                        {
                        Tim = ObjectGet(sparam,OBJPROP_TIME1);
                        ObjectSet(name,OBJPROP_TIME2,Tim);
                        }
                     else if(StringSubstr(sparam,25, 1) == "L")
                        {
                        Tim = ObjectGet(sparam,OBJPROP_TIME1);
                        ObjectSet(name,OBJPROP_TIME2,Tim);
                        }
                     break;
                     }
                  }
               }
            }
         }
      InitRect(sparam); 
      return; 
      }
   if (id == CHARTEVENT_OBJECT_CHANGE)
   {
      InitRect(sparam);
      if (StringSubstr(sparam, 0, 5) == "Bank_") DrawBank(datetime(StringSubstr(sparam, 5, 0)), 0, Info[InfoKey].bankPercent);
      return;
   }
      
   if (id == CHARTEVENT_MOUSE_MOVE)
   {
      MouseY = (int)dparam;
      MouseX = (int)lparam;
      //EasyOpenOrder_c = 0;
      DrawMouseInfo();
      if (ModeZigzag && ZigzagPrice)
      {
         datetime time;
         double price;
         ChartXYToTimePrice(0, MouseX, MouseY + 1, sub_window, time, price);
         if (!sub_window && price)
         {
            ObjectSet(ZigzagName, OBJPROP_TIME2, time);
            ObjectSet(ZigzagName, OBJPROP_PRICE2, price);
         }
      }
      return;
   }
   
   if (id == CHARTEVENT_OBJECT_CLICK)
   {
      if (sparam == "AlertInfoRect") AlertInfoWinJump();
      if (sparam == "AlertInfoRectK") AlertInfoHide(1);
      if (sparam == "ATR")
      {
         ChartSetInteger(0, CHART_SHOW_TRADE_LEVELS, bool(ChartGetInteger(0, CHART_SHOW_TRADE_LEVELS) - 1));
         Utimelocal = (int)TimeLocal();
         if (sound) PlaySound(sound_Zona);
      }
      if (sparam == "НКЗ")
         {
         zonki("НКЗ","NKZN_","NKZn_","NKZb_",1.0);
         return;
         }
      if (sparam == "3/4")
         {
         zonki("3/4","NKZT_","NKZt_","",0.75);
         return;
         }
      if (sparam == "ДКЗ")
         {
         zonki("ДКЗ","NKZD_","NKZd_","NKZa_",0.5);
         return;
         }
      if (sparam == "1/4")
         {
         zonki("1/4","NKZC_","NKZc_","",0.25);
         return;
         }
      if (sparam == ">>>")
         {
         if(seee == 0 || seee == 2) 
            {
            seee = 1; 
            ObjectSetInteger(0,"Test",OBJPROP_BGCOLOR,button_bgcolor);
            }
         else seee = 0;
         if(seee == 1) 
            {
            ObjectSetInteger(0,">>>",OBJPROP_BGCOLOR,clrRed);
            ObjectSetInteger(0,"НКЗ",OBJPROP_BGCOLOR,NKZ_color);
            ObjectSetInteger(0,"3/4",OBJPROP_BGCOLOR,NKZd_colorLow_3);
            ObjectSetInteger(0,"ДКЗ",OBJPROP_BGCOLOR,NKZd_colorLow);
            ObjectSetInteger(0,"1/4",OBJPROP_BGCOLOR,NKZd_colorLow_1);
            } 
         else 
            {
            ObjectSetInteger(0,">>>",OBJPROP_BGCOLOR,button_bgcolor);
            }
         return;
         }
      if (sparam == "Х")
         {
         DeletePanel();
         seee=0;
         return;
         }
      if (sparam == "Отк.EUR")
         {
         if(!seeeV) open_close("Отк.EUR","EURO_",A_colorEO);
         else
            {
            if(!seeeOE) seeeOE = 1;
            Op_Cl_E_A("Отк.EUR","EURO_",A_colorEO);   
            }
         return;
         }
      if (sparam == "Зак.EUR")
         {
         if(!seeeV) open_close("Зак.EUR","EUR__",A_colorEZ);
         else
            {
            if(!seeeZE) seeeZE = 1;
            Op_Cl_E_A("Зак.EUR","EUR__",A_colorEZ);   
            }
         return;
         }
      if (sparam == "Отк.USD")
         {
         if(!seeeV) open_close("Отк.USD","USDO_",A_colorAO);
         else
            {
            if(!seeeOA) seeeOA = 1;
            Op_Cl_E_A("Отк.USD","USDO_",A_colorAO);   
            }
         return;
         }
      if (sparam == "Зак.USD")
         {
         if(!seeeV) open_close("Зак.USD","USD__",A_colorAZ);
         else
            {
            if(!seeeZA) seeeZA = 1;
            Op_Cl_E_A("Зак.USD","USD__",A_colorAZ);   
            }
         return;
         }
      if (sparam == "МКЗ")
         {
         if(seeeA)
            {
            if(DeleteByPrefix("ATR__") && DeleteByPrefix("ATRm_") && DeleteByPrefix("ATRB_"))
               {
               vol_mkz_atr = 0;
               if (sound) PlaySound(sound_Zona);
               return;
               }
            vol_mkz_atr = 1;
            vol_atr = 0;
            Vol_MKZ();
            }
         else
            {
            if(DeleteByPrefix("MKZ__"))
               {
               vol_atr = 0;
               vol_key = 0;
               if (sound) PlaySound(sound_Zona);
               return;
               }
            vol_atr = 0;
            Vol_MKZ();
            }
         return;
         }
      if (sparam == "V")
         {
         if(seeeV == 0) seeeV = 1; else seeeV = 0;
         if(seeeV == 1) ObjectSetInteger(0,"V",OBJPROP_BGCOLOR,clrRed); else ObjectSetInteger(0,"V",OBJPROP_BGCOLOR,button_bgcolor);
         return;
         }
      if (sparam == "<USD>")
         {
         DeleteByPrefix("Buy_");
         DeleteByPrefix("Sel_");
         A_25_OE_key = A_25_OU_key = A_25_ZE_key = A_25_ZU_key = 0;
         A_50_OE_key = A_50_OU_key = A_50_ZE_key = A_50_ZU_key = 0;
         A_10_OE_key = A_10_OU_key = A_10_ZE_key = A_10_ZU_key = 0;
         return;
         }
      if (sparam == "Test")
         {
         if(seee == 0 || seee == 1) 
            {
            seee = 2; 
            ObjectSetInteger(0,">>>",OBJPROP_BGCOLOR,button_bgcolor);
            }
         else seee = 0;
         if(seee == 2) 
            {
            ObjectSetInteger(0,"Test",OBJPROP_BGCOLOR,clrRed);
            ObjectSetInteger(0,"НКЗ",OBJPROP_BGCOLOR,col_ATR);
            ObjectSetInteger(0,"3/4",OBJPROP_BGCOLOR,button_bgcolor);
            ObjectSetInteger(0,"ДКЗ",OBJPROP_BGCOLOR,col_ATR);
            ObjectSetInteger(0,"1/4",OBJPROP_BGCOLOR,button_bgcolor);
            }
         else 
            {
            ObjectSetInteger(0,"Test",OBJPROP_BGCOLOR,button_bgcolor);
            ObjectSetInteger(0,"НКЗ",OBJPROP_BGCOLOR,NKZ_color);
            ObjectSetInteger(0,"3/4",OBJPROP_BGCOLOR,NKZd_colorLow_3);
            ObjectSetInteger(0,"ДКЗ",OBJPROP_BGCOLOR,NKZd_colorLow);
            ObjectSetInteger(0,"1/4",OBJPROP_BGCOLOR,NKZd_colorLow_1);
            }
         return;
         }
      if (sparam == "Web")
         {
         gann();
         return;
         }
      if (sparam == "ATRr")
         {
         if(seeeA == 0) seeeA = 1; else seeeA = 0;
         if(seeeA == 1) ObjectSetInteger(0,"ATRr",OBJPROP_BGCOLOR,clrRed); else ObjectSetInteger(0,"ATRr",OBJPROP_BGCOLOR,button_bgcolor);
         return;
         }
   return;
   }

   if (id == CHARTEVENT_CLICK)
   {
/*   if(lparam > ChartGetInteger(0,CHART_WIDTH_IN_PIXELS) && dparam > ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS) * 0.85)
      {
      Alert("Это я твоя панель!");
      return;
      }
*/
   if (ModeZigzag && Alex_key == true)
      {
         static string name; 
         ChartXYToTimePrice(0, MouseX, MouseY + 1, sub_window, ZigzagTime, ZigzagPrice);
         
         if (ObjectGet(ZigzagName, OBJPROP_TIME1) == ZigzagTime && ObjectGet(ZigzagName, OBJPROP_PRICE1) == ZigzagPrice)
         {
            // Рисусем стрелку
            if (ZigzagIndex > 1)
            {
               int  h1 = 50, h2 = 70, w = 20;
               ObjectDelete(ZigzagName);
               ZigzagIndex -= 2;
               ObjectSet(name + IntegerToString(ZigzagIndex), OBJPROP_SELECTED, false); // Снять выделение с объекта
               int x1, x2, x3, x4, x5, y1, y2, y3, y4, y5;
               double V, Vx, Vy, nx, ny;
               datetime t1 = (datetime)ObjectGet(name + IntegerToString(ZigzagIndex), OBJPROP_TIME1);
               datetime t2 = (datetime)ObjectGet(name + IntegerToString(ZigzagIndex), OBJPROP_TIME2);
               double p1 = ObjectGet(name + IntegerToString(ZigzagIndex), OBJPROP_PRICE1);
               double p2 = ObjectGet(name + IntegerToString(ZigzagIndex), OBJPROP_PRICE2);
               ChartTimePriceToXY(0, 0, t1, p1, x1, y1);
               ChartTimePriceToXY(0, 0, t2, p2, x2, y2);
               Vx = x2 - x1; 
               Vy = y2 - y1; 
               V  = MathSqrt(Vx * Vx + Vy * Vy); 
               Vx = Vx / V; 
               Vy = Vy / V;
               nx = Vy; 
               ny = -Vx; 
               x3 = (int)(x2 - h1 * Vx); 
               y3 = (int)(y2 - h1 * Vy); 
               x4 = (int)(x2 - h2 * Vx + w * nx); 
               y4 = (int)(y2 - h2 * Vy + w * ny); 
               x5 = (int)(x2 - h2 * Vx - w * nx); 
               y5 = (int)(y2 - h2 * Vy - w * ny); 

               // Преобразуем координаты обратно в цену и время, хотя это можно было и не делать, но тогда будет не точно, т.к. преобразователь глючит
               ChartXYToTimePrice(0, x1, y1, sub_window, t1, p1);
               ChartXYToTimePrice(0, x2, y2, sub_window, t2, p2);
               //ObjectSet(name + ZigzagIndex, OBJPROP_TIME1, t1);
               ObjectSet(name + IntegerToString(ZigzagIndex), OBJPROP_TIME2, t2);
               //ObjectSet(name + ZigzagIndex, OBJPROP_PRICE1, p1);
               ObjectSet(name + IntegerToString(ZigzagIndex), OBJPROP_PRICE2, p2);

               t1 = t2; p1 = p2;
               ChartXYToTimePrice(0, x4, y4, sub_window, t2, p2);
               
               ZigzagName = name + IntegerToString(++ZigzagIndex);
               ObjectCreate(ZigzagName, OBJ_TREND, 0, t1, p1, t2, p2);
               ObjectSet(ZigzagName, OBJPROP_COLOR, Zigzag_color);          // Цвет
               ObjectSet(ZigzagName, OBJPROP_WIDTH, Zigzag_width);          // Толщина
               ObjectSet(ZigzagName, OBJPROP_STYLE, Zigzag_style);          // Стиль
               ObjectSet(ZigzagName, OBJPROP_BACK, Zigzag_back);            // Рисовать объект в фоне
               ObjectSet(ZigzagName, OBJPROP_RAY, false);                 
               
               ChartXYToTimePrice(0, x5, y5, sub_window, t2, p2);
               ZigzagName = name + IntegerToString(++ZigzagIndex);
               ObjectCreate(ZigzagName, OBJ_TREND, 0, t1, p1, t2, p2);
               ObjectSet(ZigzagName, OBJPROP_COLOR, Zigzag_color);          // Цвет
               ObjectSet(ZigzagName, OBJPROP_WIDTH, Zigzag_width);          // Толщина
               ObjectSet(ZigzagName, OBJPROP_STYLE, Zigzag_style);          // Стиль
               ObjectSet(ZigzagName, OBJPROP_BACK, Zigzag_back);            // Рисовать объект в фоне
               ObjectSet(ZigzagName, OBJPROP_RAY, false);                 
               
               ChartXYToTimePrice(0, x3, y3, sub_window, t1, p1);
               
               ChartXYToTimePrice(0, x4, y4, sub_window, t2, p2);
               ZigzagName = name + IntegerToString(++ZigzagIndex);
               ObjectCreate(ZigzagName, OBJ_TREND, 0, t1, p1, t2, p2);
               ObjectSet(ZigzagName, OBJPROP_COLOR, Zigzag_color);          // Цвет
               ObjectSet(ZigzagName, OBJPROP_WIDTH, Zigzag_width);          // Толщина
               ObjectSet(ZigzagName, OBJPROP_STYLE, Zigzag_style);          // Стиль
               ObjectSet(ZigzagName, OBJPROP_BACK, Zigzag_back);            // Рисовать объект в фоне
               ObjectSet(ZigzagName, OBJPROP_RAY, false);                 

               ChartXYToTimePrice(0, x5, y5, sub_window, t2, p2);
               ZigzagName = name + IntegerToString(++ZigzagIndex);
               ObjectCreate(ZigzagName, OBJ_TREND, 0, t1, p1, t2, p2);
               ObjectSet(ZigzagName, OBJPROP_COLOR, Zigzag_color);          // Цвет
               ObjectSet(ZigzagName, OBJPROP_WIDTH, Zigzag_width);          // Толщина
               ObjectSet(ZigzagName, OBJPROP_STYLE, Zigzag_style);          // Стиль
               ObjectSet(ZigzagName, OBJPROP_BACK, Zigzag_back);            // Рисовать объект в фоне
               ObjectSet(ZigzagName, OBJPROP_RAY, false);                 
               ZigzagName = ""; 
               ZigzagPrice = ZigzagIndex = 0;
            }
            return;
         }
         if (!ZigzagIndex) name = "Zigzag_" + IntegerToString(GetTickCount()) + "_";
         ZigzagName = name + IntegerToString(ZigzagIndex++);
         ObjectCreate(ZigzagName, OBJ_TREND, 0, ZigzagTime, ZigzagPrice, ZigzagTime, ZigzagPrice);
         ObjectSet(ZigzagName, OBJPROP_COLOR, Zigzag_color);          // Цвет
         ObjectSet(ZigzagName, OBJPROP_WIDTH, Zigzag_width);          // Толщина
         ObjectSet(ZigzagName, OBJPROP_STYLE, Zigzag_style);          // Стиль
         ObjectSet(ZigzagName, OBJPROP_BACK, Zigzag_back);            // Рисовать объект в фоне
         ObjectSet(ZigzagName, OBJPROP_RAY, false);                   // Рисовать не луч
      }
      else
      {

      //        Вызовем кнопочную панель
      static uint t1, n1 = 1;
      if (GetTickCount() - t1 < 400) n1++; else n1 = 1;
      t1 = GetTickCount();
      if(n1 == button_click)
         {
         ChartXYToTimePrice(0, MouseX, MouseY, sub_window, button_time, button_price);
         SborDannix(); 
         return;     
         }
         // Граальные уровни. Ловим двойной клик
      if(Alex_key == true)
         {
      int periodX = 0;
      switch(_Period)
         {
            case PERIOD_M1  : periodX = OBJ_PERIOD_M1;  break;
            case PERIOD_M5  : periodX = OBJ_PERIOD_M5;  break;
            case PERIOD_M15 : periodX = OBJ_PERIOD_M15; break;
            case PERIOD_M30 : periodX = OBJ_PERIOD_M30; break;
            case PERIOD_H1  : periodX = OBJ_PERIOD_H1;  break;
            case PERIOD_H4  : periodX = OBJ_PERIOD_H4;  break;
            case PERIOD_D1  : periodX = OBJ_PERIOD_D1;  break;
            case PERIOD_W1  : periodX = OBJ_PERIOD_W1;  break;
            case PERIOD_MN1 : periodX = OBJ_PERIOD_MN1; break;
         }
         if (Alex_timeframe == 0 || (Alex_timeframe & periodX) > 0)
         {
            static uint t, n = 1;
            if (GetTickCount() - t < 400) n++; else n = 1;
            t = GetTickCount();
            if(n == button_click)
               {
               ChartXYToTimePrice(0, MouseX, MouseY + 1, sub_window, ZigzagTime, ZigzagPrice);
               
               }
            else if (n == Alex_click)
            {
               datetime time;
               double price;
               ChartXYToTimePrice(0, MouseX, MouseY + 1, sub_window, time, price);
               int shift = iBarShift(NULL, 0, time, false);
               Comment(shift);
               int shifts[3];
               shifts[0] = shift;
               shifts[1] = shift - 1;
               shifts[2] = shift + 1;
               color Alex_color = 0;            
               for (int i = 0; i < ArraySize(shifts); i++)
               {
                  shift = shifts[i];
                  double p1, p2, p3, p4, pr1 = 0, pr2 = 0;
                  p1 = iHigh(NULL, 0, shift);
                  p2 = iOpen(NULL, 0, shift);
                  p3 = iClose(NULL, 0, shift);
                  p4 = iLow(NULL, 0, shift);
                  if (p2 < p3) { double p = p2; p2 = p3; p3 = p; }
                  if (price >= p2 && price <= p1) { pr1 = p1; pr2 = p2; Alex_color = Alex_color_Hi;}
                  if (price <= p3 && price >= p4) { pr1 = p3; pr2 = p4; Alex_color = Alex_color_Low;}
                  if (pr1)
                  {
                     datetime time2;
                     if ((TimeCurrent() - time) / 86400 <= Alex_day) 
                        time2 = TimeCurrent();
                     else
                        time2 = correctWeekend(time, time + Alex_length);
                     string name = "Alex_" + IntegerToString(time) + "_" + DoubleToString(pr1);
                     ObjectCreate(name, OBJ_RECTANGLE, 0, Time[shift], pr1, time2, pr2);
                     ObjectSet(name, OBJPROP_COLOR, Alex_color);           // Цвет
                     ObjectSet(name, OBJPROP_TIMEFRAMES, Alex_timeframe);  // Таймфрейм для отображения
                     ObjectSet(name, OBJPROP_BACK, Alex_back);                  // Рисовать объект в фоне
                     ObjectSet(name, OBJPROP_WIDTH, Alex_width);           // Толщина линий
                     break;
                  }         
               }
            }
         }
      return;
      }
         }
   return;
   }
      
   if (id == CHARTEVENT_KEYDOWN)
   {
      //Comment("Код клавиши: " + lparam); PlaySound("stops.wav"); return;
      datetime time1;                  // Время вершинки
      double   price1;                 // Цена вершинки
      double   price2, price3, price4; // Цены для зоны
      int      HiLow = 1;                  // 1 - Hi, -1 - Low
      button_lparam = lparam;
      Comment("");
      ChartXYToTimePrice(0, MouseX, MouseY + 1, sub_window, time1, price1);
      button_time = time1;
      button_price = price1;
      if (lparam != HotKey9) double_ctrl = 0; // Обнулим время для определение двойного нажатия Ctrl, если нажали не Ctrl
      
      // Удлинение зоны
      if (lparam == HotKey13)
      {
         string name;
         name = ZoneUnderCursor(time1, price1);
         if (name != "")
         {
            int x2, y2;
            datetime time;
            double price;
            ChartTimePriceToXY(0, 0, (datetime)ObjectGet(name, OBJPROP_TIME2), ObjectGet(name, OBJPROP_PRICE2), x2, y2);
            if (ChartXYToTimePrice(0, x2 + ZonaLengthPlus, y2, sub_window, time, price))
            {
               ObjectSet(name, OBJPROP_TIME2, time);
               ObjectSet(StringSubstr(name, 0, 24) + "L50", OBJPROP_TIME2, time);
            }
            else
            {
               ChartXYToTimePrice(0, 10, 1, sub_window, time, price);
               ChartXYToTimePrice(0, 10 + ZonaLengthPlus, 1, sub_window, time1, price);
               ObjectSet(name, OBJPROP_TIME2, ObjectGet(name, OBJPROP_TIME2) + time1 - time);
               ObjectSet(StringSubstr(name, 0, 24) + "L50", OBJPROP_TIME2, ObjectGet(name, OBJPROP_TIME2) + time1 - time);
            }
            Gde_Zonki();
            ChartRedraw();
            return;
         }
      }
      // Укорочение зоны №№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№№
      if (lparam == HotKey30)                                                                                        // Нажали Клавишу Ё для укорачивания зон
      {
         string name;
         name = ZoneUnderCursor(time1, price1);
         if(StringSubstr(name,0,3) == "IT_") 
            {
            ObjectSetString(0,name,OBJPROP_NAME,"IS_" + StringSubstr(name,3,0));
            name = ZoneUnderCursor(time1, price1);
            }
         if (name != "")
         {
            int x2, y2;
            datetime time;
            double price;
            ChartTimePriceToXY(0, 0, ObjectGetTimeByValue(0,name, OBJPROP_TIME2), ObjectGet(name, OBJPROP_PRICE2), x2, y2);       // Получим Х2 и У2 прямоугольника
//            if (ChartXYToTimePrice(0, x2 - ZonaLengthPlus, y2, sub_window, time, price))                             // Если получилось исправить и преобразовать обратно в  цену и время то
            if (ChartXYToTimePrice(0, MouseX, 1, sub_window, time, price))                             // Если получилось исправить и преобразовать обратно в  цену и время то
            {
               ObjectSet(name, OBJPROP_TIME2, time);
               ObjectSet(StringSubstr(name, 0, 24) + "L50", OBJPROP_TIME2, time);
            }
            else
            {
               ChartXYToTimePrice(0, 10, 1, sub_window, time, price);
               ChartXYToTimePrice(0, 10 - ZonaLengthPlus, 1, sub_window, time1, price);
               ObjectSet(name, OBJPROP_TIME2, ObjectGet(name, OBJPROP_TIME2) + time1 - time);
               ObjectSet(StringSubstr(name, 0, 24) + "L50", OBJPROP_TIME2, ObjectGet(name, OBJPROP_TIME2) + time1 - time);
            }
            Gde_Zonki();
            ChartRedraw();
            return;
         }
      }
      
      // Рисование зигзага
      if (lparam == HotKey9 && Alex_key == true)
      {
         if (GetTickCount() - double_ctrl < 400) 
            ModeZigzag = 1;
         else
         {
            double_ctrl = GetTickCount();
            ModeZigzag = ZigzagIndex = 0;
            ZigzagPrice = 0;
            ObjectDelete(ZigzagName);
         }
      }
      DrawMouseInfo();
      
      // Нажали ESC
      if (lparam == 27)
      {
         if (ModeZigzag)
         {
            int k;
            if ((k = StringFind(ZigzagName, "_", 7)) != -1) DeleteByPrefix(StringSubstr(ZigzagName, 0, k));
            ZigzagIndex = 0;
         }
         if (ObjectGetDouble(0, "line_sl_bid", OBJPROP_PRICE1)) return; 
         AlertInfoHide(1); // Скрыть Алерт окно
         return;
      }

      // Нажали пробел
      if (lparam == HotKey16)
      {
         if (HotKey16 == 32 && IsDllsAllowed() && !EasyOpenOrder) keybd_event(27, 0, 0, 0);

         /// Для совместной работы с EasyOpenOrder ////////////////////////////////////////////////////////////////////
         if (EasyOpenOrder)
         {
            //EasyOpenOrder_c = 0;
            if (ObjectGetDouble(0, "line_sl_bid", OBJPROP_PRICE1)) return; 
         }
         ///////////////////////////////////////////////////////////////////////////////////////////////////////////////

         AlertInfoWinJump();
         return;
      }
      
      // Рисование зон, линии ганна, уровня коррекции
      if (lparam == HotKey1 || lparam == HotKey2 || lparam == HotKey3 || lparam == HotKey10 || lparam == HotKey11 || lparam == HotKey31 || lparam == HotKey32 || lparam == HotKey33 || lparam == HotKey36)
      {
         zone_name();
         string name = button_name;
         int zonaUpdate = button_zonaUpdate;
         double zonaUpdateInfo = button_zonaUpdateInfo;
         if (zonaUpdate && (lparam == HotKey1 || lparam == HotKey2 || lparam == HotKey3 || lparam == HotKey32 || lparam == HotKey33 || lparam == HotKey36))
         {
            zone_zone();
            price1 = button_price;
            time1 = button_time;
            zonaUpdate = button_zonaUpdate;
            zonaUpdateInfo = button_zonaUpdateInfo;
            HiLow = button_HiLow;
         }
           if (!zonaUpdate)
         {
            HiLow();
            price1 = button_price;
            time1 = button_time;
            HiLow = button_HiLow;
         }
         zone_re();
         if (zonaUpdate == 5) zonaUpdate = 0; 
         zonaUpdateInfo = button_zonaUpdateInfo;
         // Кнопочная панель от зоны
         if ((lparam == HotKey36 && !zonaUpdate) || zonaUpdate == 4)
         {
         StartPanel();
         }
         // ДКЗ по процентной ставке
         if ((lparam == HotKey1 && !zonaUpdate) || zonaUpdate == 1)
         {
            if (zonaUpdateInfo && !zonaUpdate)
            {
               DeleteByPrefix("DKZ__" + TimeToString(time1));
               if (sound) PlaySound(sound_Zona);
               return;
            }
            if (!zonaUpdateInfo) 
               {
               zonaUpdateInfo = Info[InfoKey].percent;
               }
            if (zonaUpdateInfo == 0)
            {
               Comment("Процентная ставка не задана!");
               if (sound) PlaySound(sound_Error);
               return;
            }
            double DKZ;
            if (Info[InfoKey].NKZ < 0) 
               DKZ = MathAbs(price1 - 1 / (1 / price1 + 1 / price1 * zonaUpdateInfo / 100 * HiLow));
            else
               DKZ = price1 * zonaUpdateInfo / 100;
            price2 = price1 - DKZ * HiLow;
            price4 = price2 + DKZ / 10 * HiLow;
            DrawZone("DKZ__", "Дкз - " + IntegerToString((int)(MathFloor(DKZ * MathPow(10, _Digits)))) + "п. (" + DoubleToString(zonaUpdateInfo, 2) + "%)", time1, price1, time1 + DKZ_angle, price2, price2, price4, DKZ_length, DKZ_color, DKZ_timeframe, zonaUpdateInfo);
            return;
         }

         // Дробные НКЗ +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
         if ((lparam == HotKey2 && !zonaUpdate) || (zonaUpdate == 2) || (lparam == HotKey32 && !zonaUpdate))
         {
            massiv(time1);// Выбор строчки из массива
            if (zonaUpdateInfo && !zonaUpdate)
            {
               for (int i = ArraySize(NKZd_list) - 1; i >=0; i--) DeleteByPrefix("NKZ" + IntegerToString(i) + "_" + TimeToString(time1));
               if (sound) PlaySound(sound_Zona);
               return;
            }
            if(lparam == HotKey32) InffoKey++;
            if (!zonaUpdateInfo)
            {
//               zonaUpdateInfo = Info[InfoKey].NKZ;             //@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//               if (Info[InfoKey].NKZ < 0) zonaUpdateInfo = MathAbs(MathFloor((price1 - 1 / (1 / price1 - Info[InfoKey].NKZ * HiLow)) / Point));  //@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
               zonaUpdateInfo = InffO[InffoKey].NKZ;             //@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
               if (InffO[InffoKey].NKZ < 0) zonaUpdateInfo = MathAbs(MathRound((price1 - 1 / (1 / price1 - InffO[InffoKey].NKZ * HiLow)) / Point));  //@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// Alert(price1," ",InffO[InfoKey].NKZ," ",HiLow," ",Point," ",zonaUpdateInfo); 
            }
            double NKZ = zonaUpdateInfo;
            if (NKZ == 0)
            {
               Comment("Недельная зона не задана!");
               if (sound) PlaySound(sound_Error);
               return;
            }

            for (int i = ArraySize(NKZd_list) - 1; i >=0; i--)
            {
               if (!NKZd_list[i]) continue;
               NKZ = zonaUpdateInfo * NKZd_list[i];
               price2 = price1 - NKZ * _Point * HiLow;
               if (NKZ_mode == 1)
               {
                  price3 = price2 - NKZ * _Point * 0.10 * HiLow;  // Вычисляем высоту зоны, 10% наружу
                  price4 = price2;                               // Вычисляем высоту зоны, 10% наружу
               }
               else if (NKZ_mode == 2)
               {
                  price3 = price2 + NKZ * _Point * 0.10 * HiLow;  // Вычисляем высоту зоны, 10% во внутрь
                  price4 = price2;                               // Вычисляем высоту зоны, 10% во внутрь
               }
               else
               {
                  price3 = price2 + NKZ * _Point * 0.05 * HiLow; // Вычисляем высоту зоны, по 5% в обе стороны
                  price4 = price2 - NKZ * _Point * 0.05 * HiLow; // Вычисляем высоту зоны, по 5% в обе стороны
               }
               if (zonaUpdate)
               {
                  name = "NKZ" + IntegerToString(i) + "_" + TimeToString(time1);
                  if (price1 > price2) name += "_H"; else name += "_L";
                  name += "_" + DoubleToString(zonaUpdateInfo);
                  if (ObjectFind(name) == -1) continue;
               }  
               int NKZd_color;
               string opisanie = "НКЗ ";
               if(i == 2){opisanie = "3/4 "; if (HiLow > 0) NKZd_color = NKZd_colorHi_3; else  NKZd_color = NKZd_colorLow_3;}
               else if(i == 1){opisanie = "ДКЗ "; if (HiLow > 0) NKZd_color = NKZd_colorHi; else  NKZd_color = NKZd_colorLow;}
               else if(i == 0){opisanie = "1/4 "; if (HiLow > 0) NKZd_color = NKZd_colorHi_1; else  NKZd_color = NKZd_colorLow_1;}
               DrawZone("NKZ" + IntegerToString(i) + "_", opisanie + (string)(NormalizeDouble(NKZd_list[i],2)) + " - " + IntegerToString((int)(NKZ)) + "п.", time1, price1, time1 + NKZ_angle, price2, price3, price4, (int)(NKZ_length * NKZd_list[i]), NKZd_color, NKZ_timeframe, zonaUpdateInfo);
            }
            return;
         }
      
         // НКЗ
         if (((lparam == HotKey3 && !zonaUpdate) || zonaUpdate == 3) || ((lparam == HotKey33 && !zonaUpdate) || zonaUpdate == 3))
         {
            massiv(time1);// Выбор строчки из массива
            if (zonaUpdateInfo && !zonaUpdate)
            {
               DeleteByPrefix("NKZ__" + TimeToString(time1));
               if (sound) PlaySound(sound_Zona);
               return;
            }
            if(lparam == HotKey33) InffoKey++;
            if (!zonaUpdateInfo)
            {
               zonaUpdateInfo = InffO[InffoKey].NKZ;                //@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
               if (InffO[InffoKey].NKZ < 0) zonaUpdateInfo = MathAbs(MathRound((price1 - 1 / (1 / price1 - InffO[InffoKey].NKZ * HiLow)) / Point)); //@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
            }
            double NKZ = zonaUpdateInfo;
            if (NKZ == 0)
            {
               Comment("Недельная зона не задана!");
               if (sound) PlaySound(sound_Error);
               return;
            }
            price2 = price1 - NKZ * _Point * HiLow;
            if (NKZ_mode == 1)
            {
               price3 = price2 - NKZ * _Point * 0.10 * HiLow;  // Вычисляем высоту зоны, 10% наружу
               price4 = price2;                               // Вычисляем высоту зоны, 10% наружу
            }
            else if (NKZ_mode == 2)
            {
               price3 = price2 + NKZ * _Point * 0.10 * HiLow;  // Вычисляем высоту зоны, 10% во внутрь
               price4 = price2;                               // Вычисляем высоту зоны, 10% во внутрь
            }
            else
            {
               price3 = price2 + NKZ * _Point * 0.05 * HiLow; // Вычисляем высоту зоны, по 5% в обе стороны
               price4 = price2 - NKZ * _Point * 0.05 * HiLow; // Вычисляем высоту зоны, по 5% в обе стороны
            }
            DrawZone("NKZ__", "НКЗ - " + IntegerToString((int)(NKZ)) + "п.", time1, price1, time1 + NKZ_angle, price2, price3, price4, NKZ_length, NKZ_color, NKZ_timeframe, zonaUpdateInfo);
            return;
         }
         // Линия Ганна
         if (lparam == HotKey10)
         {
            datetime time2 = correctWeekend(time1, time1 + Gann_length);
            static datetime timegann;
            static int i = 0;
            name = "Gann_" + TimeToString(time1);
            if (timegann != time1) i = 0;
            timegann = time1;
            if (i == ArraySize(Gann_Scale))
            {
               i = 0;
               ObjectDelete(name);
            }
            else
            {
               HiLow *= -1;
               if (!Gann_change) name += DoubleToString(Gann_Scale[i] * (double)HiLow);
               ObjectDelete(name);
               ObjectCreate(0, name, OBJ_GANNLINE, 0, time1, price1, time2, 0);
               ObjectSetDouble(0, name, OBJPROP_SCALE, Gann_Scale[i] * HiLow);
               ObjectSetText(name, "   " + DoubleToString(Gann_Scale[i] * (double)HiLow));
               ObjectSet(name, OBJPROP_TIMEFRAMES, Gann_timeframe); // Таймфрейм для отображения
               ObjectSet(name, OBJPROP_WIDTH, Gann_width);          // Толщина
               ObjectSet(name, OBJPROP_STYLE, Gann_style);          // Стиль
               ObjectSet(name, OBJPROP_COLOR, Gann_color);          // Цвет
               i++;
            }
            if (sound) PlaySound(sound_Zona);
            return;
         }
         // Линия Ганна по вчерашнему дню ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
         if (lparam == HotKey31)
         {
         gann();
            return;
         }
         
         // Уровень коррекции
         if (lparam == HotKey11) DrawCorrect(time1, price1, HiLow);
      }

      // МКЗ уровни @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
   if (lparam == HotKey29)
      {
      if(DeleteByPrefix("MKZ__"))
         {
         if (sound) PlaySound(sound_Zona);
         vol_atr = 0;
         vol_key = 0;
         return;
         }
      Vol_MKZ();
      ChartRedraw(); 
      return;
      }         
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

      // Банковский уровень 
      if (lparam == HotKey6)
      {
         if (BankTime)
         {
            MqlDateTime date;
            TimeToStruct(time1, date);
            datetime BankTimeManual = datetime(IntegerToString(date.year) + "." + IntegerToString(date.mon) + "." + IntegerToString(date.day) + " " + IntegerToString(TimeHour(BankTime)) + ":" + IntegerToString(TimeMinute(BankTime)));
            if (B_manual)
            {
               int dW = TimeDayOfWeek(BankTimeManual);
               int ok = 0;
               for (int i = ArraySize(B_days) - 1; i >= 0; i--)
                  if (dW == B_days[i]) { ok = 1; break; }
               if (!ok)
               {
                  Comment("В этот день недели запрещено в настройках строить банковский уровень! Установите параметр B_manual = 0;");
                  if (sound) PlaySound(sound_Error);
                  return;
               }
            }
            if (TimeCurrent() >= BankTimeManual)
            {
               int shift, tm[] = {1, 5, 15, 30, 0};
               for (int i = 0; i < ArraySize(tm); i++)
               {
                  shift = iBarShift(NULL, tm[i], BankTimeManual, true);
                  if (shift != -1)
                  {
                     if (ObjectFind("Bank_" + TimeToString(BankTimeManual)) != -1)
                     {
                        ObjectDelete("Bank_" + TimeToString(BankTimeManual));
                        DeleteByPrefix("BankZ_" + TimeToString(BankTimeManual));
                        if (sound) PlaySound(sound_Zona);
                        return;
                     }
                     else
                        massiv_bu(time1);// Выбор строчки из массива
//                        DrawBank(BankTimeManual, iOpen(NULL, tm[i], shift), Info[InfoKey].bankPercent);
                        DrawBank(BankTimeManual, iOpen(NULL, tm[i], shift), B_bankPercent);
                     if (sound) PlaySound(sound_Blevel);
                     break;
                  }
               }
            }
            else
            {
               Comment("Еще не время рисовать банковский уровень!");
               if (sound) PlaySound(sound_Error);
            }
         }
         return;
      }
      
      // Удаление объектов (разные циклы в место одного, что бы удалять в порядке приоритета)
      if (lparam == HotKey4)
      {
         /// Для совместной работы с EasyOpenOrder ////////////////////////////////////////////////////////////////////
         //if (EasyOpenOrder && ChartGetInteger(0, CHART_SHOW_TRADE_LEVELS) && isMouseOrder() && EasyOpenOrder_c++ < 1) return;        
         ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
         
         string name;
         int total = ObjectsTotal();
         
         // Удаление линии банковского уровня/Atr уровня/HiLow уровня
         for (int i = 0; i < total; i++)
         {
            if (  
                  ObjectType(name = ObjectName(i)) == OBJ_TREND 
                  && 
                  (
                     StringSubstr(name, 0, 5) == "Bank_" ||
                     StringSubstr(name, 0, 4) == "ATR_" ||
                     StringSubstr(name, 0, 6) == "HiLow_" ||
                     StringSubstr(name, 0, 7) == "Zigzag_" ||
                     StringSubstr(name, 0, 7) == "Correct"
                  )
               )
            {
               int x, x1, x2, x3, y, y1, y2, y3;
               ChartTimePriceToXY(0, 0, (datetime)ObjectGet(name, OBJPROP_TIME1), ObjectGet(name, OBJPROP_PRICE1), x1, y1);
               ChartTimePriceToXY(0, 0, (datetime)ObjectGet(name, OBJPROP_TIME2), ObjectGet(name, OBJPROP_PRICE2), x2, y2);
               ChartTimePriceToXY(0, 0, time1, price1, x3, y3);
               if (x1 > x2) { x = x1; x1 = x2; x2 = x; }
               if (y1 > y2) { y = y1; y1 = y2; y2 = y; }
               int p = 8;
               if (x3 >= x1 - p && x3 <= x2 + p && y3 >= y1 - p && y3 <= y2 + p)
               {
                  ChartTimePriceToXY(0, 0, (datetime)ObjectGet(name, OBJPROP_TIME1), ObjectGet(name, OBJPROP_PRICE1), x1, y1);
                  ChartTimePriceToXY(0, 0, (datetime)ObjectGet(name, OBJPROP_TIME2), ObjectGet(name, OBJPROP_PRICE2), x2, y2);
                  double d = 2 * MathAbs(x2 * (y1 - y3) + x1 * (y3 - y2) + x3 * (y2 - y1)) / 2 / MathSqrt(MathPow(x2 - x1, 2) + MathPow(y2 - y1, 2));    
                  if (d <= p)
                  {
                     ObjectDelete(name);
                     if (StringSubstr(name, 0, 7) == "Correct") DeleteByPrefix("Correct");
                     if (StringSubstr(name, 0, 7) == "Zigzag_")
                     {
                        int k;
                        if ((k = StringFind(name, "_", 7)) != -1) DeleteByPrefix(StringSubstr(name, 0, k));
                     }
                     if (StringSubstr(name, 0, 5) == "Bank_") DeleteByPrefix("BankZ_" + StringSubstr(name, 5, 24));
                     if (sound) PlaySound(sound_Zona);
                     return;
                  }
               }
            }
         }

         // Удаление зон Дкз, Нкз и зон банковского уровня, да блять и всех зон вообще
         name = ZoneUnderCursor(time1, price1);
         if (name != "")
         {
            if (StringSubstr(name, 0, 3) == "MKZ") return;
            // Удаление зон банковского уровня
            if (StringSubstr(name, 0, 6) == "BankZ_")
            {
               DeleteByPrefix(StringSubstr(name, 0, 24));
               if (sound) PlaySound(sound_Zona);
               return;
            }
            // Удаление остальных зон
            ObjectDelete(name);                              // Удал. зоны 
            ObjectDelete(StringSubstr(name, 0, 24));         // Удал. линии зоны если есть
            ObjectDelete(StringSubstr(name, 0, 24) + "L50"); // Удал. дополнительлную линии зоны если есть
            if (sound) PlaySound(sound_Zona);
            return;
         }
         Comment("Не найден объект для удаления!");
         if (sound) PlaySound(sound_Error);
         return;
       }

      // Выравнивание трендовой линии
      if (lparam == HotKey5)
      {
         string name;
         for (int i = ObjectsTotal() - 1; i >= 0; i--)
         {
            name = ObjectName(i);
            if (ObjectGetInteger(0, name, OBJPROP_SELECTED))
            {
               if (ObjectType(name) == OBJ_TREND)
               { 
                  if (ObjectGet(name, OBJPROP_PRICE1) == ObjectGet(name, OBJPROP_PRICE2)) 
                     ObjectSetInteger(0, name, OBJPROP_SELECTED, 0);
                  else
                     ObjectSet(name, OBJPROP_PRICE2, ObjectGet(name, OBJPROP_PRICE1));
               }
               if (ObjectType(name) == OBJ_RECTANGLE)
               { 
                     ObjectSetInteger(0, name, OBJPROP_SELECTED, 0);
               }
            }
         }
         return;
      }      
      
      // ATR уровни
      if (lparam == HotKey7)
      {
         DrawATR(time1);
         return;
      }

      // HiLow уровни
      if (lparam == HotKey8)
      {
         DrawHiLow(1);
         return;
      }         

      // Показать спрятать разделители периодов
      if (lparam == HotKey14)
      {
         ChartSetInteger(0, CHART_SHOW_PERIOD_SEP, bool(ChartGetInteger(0, CHART_SHOW_PERIOD_SEP) - 1));
         return;
      }
      
      // Показать спрятать торговые уровни
      if (lparam == HotKey15) 
      {
         ChartSetInteger(0, CHART_SHOW_TRADE_LEVELS, bool(ChartGetInteger(0, CHART_SHOW_TRADE_LEVELS) - 1));
         Utimelocal = (int)TimeLocal();
         if (sound) PlaySound(sound_Zona);
         return;
      }
      
      // Показать спрятать описание объектов
      if (lparam == HotKey21)
      {
         ChartSetInteger(0, CHART_SHOW_OBJECT_DESCR, bool(ChartGetInteger(0, CHART_SHOW_OBJECT_DESCR) - 1));
         return;
      }
      
      // Нажали T -> Ctrl+T
      if (lparam == HotKey22)
      { 
         keybd_event(17,0,0,0);
         keybd_event(84,0,0,0);
         keybd_event(84,0,2,0);
         keybd_event(17,0,2,0); 
         return; 
      }
      
      // Увеличиваем масштаб
      if (lparam == HotKey23) { ChangeScale(0); return; }                             
      
      // Уменьшаем масштаб
      if (lparam == HotKey24) { ChangeScale(1); return; }                             
      
      // Увеличиваем таймфрейм
      if (lparam == HotKey25) { ChangePeriod(0); return; }
      
      // Уменьшаем таймфрейм
      if (lparam == HotKey26) { ChangePeriod(1); return; }
      
      // Установить старший рабочий таймфрейм
      if (lparam == HotKey27)
      {
         ChartSetSymbolPeriod(0, NULL, H_time_frame);
         ChartRedraw();
         ChartSetInteger(0, CHART_SCALE, H_scale);
         ChartRedraw();
         ChartNavigate(0, CHART_END, 0);
         ChartRedraw();
         return;
      }
      
      // Установить младший рабочий таймфрейм
      if (lparam == HotKey28)
      {
         ChartSetSymbolPeriod(0, NULL, M_time_frame);
         ChartRedraw();
         ChartSetInteger(0, CHART_SCALE, M_scale);
         ChartRedraw();
         ChartNavigate(0, CHART_END, 0);
         ChartRedraw();
         return;
      }      
      
      // Смена цвета зоны
      if (lparam == HotKey17)
      {
         string name;
         name = ZoneUnderCursor(time1, price1);
         if (name != "")
         {
            int i, clr = (int)ObjectGet(name, OBJPROP_COLOR);
            for (i = 0; i < ArraySize(ListColorZone) - 1; i++) if (ListColorZone[i] == clr) break;
            if (++i >= ArraySize(ListColorZone)) i = 0;
            ObjectSet(name, OBJPROP_COLOR, ListColorZone[i]);
            ObjectSetInteger(0, name, OBJPROP_SELECTED, 0);
            //if (sound) PlaySound(sound_Zona);
            return;
         }
         Comment("Не найдена зона!");
         if (sound) PlaySound(sound_Error);
         return;
      }
      
      // Вкл./выкл. звуковых оповещений
      if (lparam == HotKey18)
      {
         if (ZonaAlertSound)
         {
            GlobalVariableSet("DN_ZonaAlertSound", 0);
            SendAllEvent(2, 0);
            AlertInfoAdd(0, "Звуковые оповещения отключены");
            if (sound) PlaySound(sound_Zona);
         }
         else
         {
            GlobalVariableSet("DN_ZonaAlertSound", 1);
            SendAllEvent(2, 1);
            AlertInfoAdd(0, "Звуковые оповещения включены");
            if (sound) PlaySound(sound_Zona);
         }
         return;
      }

      // Скриншот
      if (lparam == HotKey19)
      {
         MyScreenShot(0); 
         return;
      }

      // Скриншот в отдельную папку
      if (lparam == HotKey20)
      {
         MyScreenShot(1); 
         return;
      }
   }
}

//+------------------------------------------------------------------+
//| Скриншот                                                         |
//+------------------------------------------------------------------+
void MyScreenShot(int mode = 0)
{
   string name;
   MqlDateTime  dt_;
   TimeToStruct(TimeLocal(), dt_);
   string date = IntegerToString(dt_.year) + "." + IntegerToString(dt_.mon, 2, '0') + "." + IntegerToString(dt_.day, 2, '0');
   if (dt_.day_of_week == 6) date += " сб";
   if (dt_.day_of_week == 0) date += " вс";
   string time = IntegerToString(dt_.hour, 2, '0') + "." + IntegerToString(dt_.min, 2, '0') + "." + IntegerToString(dt_.sec, 2, '0');
   name = date + "/" + _Symbol + " " + date + " " + time + ".png";
   if (mode)
   {
      name = ScreenDir + "/" + _Symbol + " " + date + " " + time + ".png";
      date = ScreenDir;
   }
   StringReplace(name, "#", "");
   //FolderCreate(date);
   ChartScreenShot(0, name, ScreenWidth, ScreenHeight, ALIGN_LEFT);
   //CopyTextToClipboard(TerminalPath() + "/MQL4/Files/" + name);
   //MessageBox("Скриншот создан! Ссылка на изображение, в буфере обмена.");
   PlaySound(sound_Screen);
}

//+------------------------------------------------------------------+
//| Получение имени зоны под указателем мыши                         |
//+------------------------------------------------------------------+
string ZoneUnderCursor(datetime time, double price)
{
   string name, resultName = NULL;
   int a, x1, x2, y1, y2, periodX = 0, timeframe;
   double Area = 9223372036854775807.0;                                 //double Area = 0x7FFFFFFFFFFFFFFF;
   switch(_Period)
   {
      case PERIOD_M1  : periodX = OBJ_PERIOD_M1;  break;
      case PERIOD_M5  : periodX = OBJ_PERIOD_M5;  break;
      case PERIOD_M15 : periodX = OBJ_PERIOD_M15; break;
      case PERIOD_M30 : periodX = OBJ_PERIOD_M30; break;
      case PERIOD_H1  : periodX = OBJ_PERIOD_H1;  break;
      case PERIOD_H4  : periodX = OBJ_PERIOD_H4;  break;
      case PERIOD_D1  : periodX = OBJ_PERIOD_D1;  break;
      case PERIOD_W1  : periodX = OBJ_PERIOD_W1;  break;
      case PERIOD_MN1 : periodX = OBJ_PERIOD_MN1; break;
   }
   for (int i = ObjectsTotal() - 1; i >= 0; i--)
   {
      name = ObjectName(i);
      timeframe = (int)ObjectGet(name, OBJPROP_TIMEFRAMES);
      if (
            ObjectType(name) == OBJ_RECTANGLE
            && price <= ObjectGet(name, OBJPROP_PRICE1)
            && price >= ObjectGet(name, OBJPROP_PRICE2)
            && time >= ObjectGet(name, OBJPROP_TIME1)
            && time <= ObjectGet(name, OBJPROP_TIME2) 
            && (timeframe == 0 || (timeframe & periodX) > 0)
          )
      {   
         ChartTimePriceToXY(0, 0, (datetime)ObjectGet(name, OBJPROP_TIME1), ObjectGet(name, OBJPROP_PRICE1), x1, y1);
         ChartTimePriceToXY(0, 0, (datetime)ObjectGet(name, OBJPROP_TIME2), ObjectGet(name, OBJPROP_PRICE2), x2, y2);
         a = MathAbs((x1 - x2) * (y1 - y2));
         if (a < Area)
         {
            Area = a;
            resultName = name;
         }
      }
   }
   return resultName;
}

//+------------------------------------------------------------------+
//| Корректировка времени если есть выходные дни                     |
//+------------------------------------------------------------------+
datetime correctWeekend(datetime time1, datetime time2)
{
   datetime time = time1;
   int d3 = TimeDayOfYear(time2);
   for (int i = TimeDayOfYear(time1); i <= d3; i++)
   {
      if (TimeDayOfWeek(time) == 6 || TimeDayOfWeek(time) == 0) time2 += 86400 * 2; // Если попали на выходные, добавим еще два дня
      if (TimeDayOfWeek(time) == 6)
      {
         i++;
         time += 86400;
      }
      time += 86400;
   }
   return time2;
}

//+------------------------------------------------------------------+
//| Рисование текста около курсора мышки                             |
//+------------------------------------------------------------------+
void DrawMouseInfo()
{
   if (MouseY) ObjectSet("MouseInfo", OBJPROP_YDISTANCE, MouseY);
   if (MouseX) ObjectSet("MouseInfo", OBJPROP_XDISTANCE, MouseX + 19);
   
   if (ModeZigzag == 1) 
      ObjectSetString(0, "MouseInfo", OBJPROP_TEXT, "/\\/\\/\\");
   else
      ObjectSetString(0, "MouseInfo", OBJPROP_TEXT, " ");
}

//+------------------------------------------------------------------+
//| Удаление объектов по префиксу                                    |
//+------------------------------------------------------------------+
int DeleteByPrefix(string o_prefix)
{
   string name;
   int result = 0;
   for (int i = ObjectsTotal() - 1; i >= 0; i--)
   {
      name = ObjectName(i);
      if (StringFind(name, o_prefix, 0) == 0) 
      {
         ObjectDelete(name);   
         result = 1;
      }
   }
   return result;
}

//+------------------------------------------------------------------+
//| Рисование зоны                                                   |
//+------------------------------------------------------------------+
void DrawZone(string name, string descr, datetime time1, double price1, datetime time2, double price2, double price3, double price4, int length, int clr, int timeframe, double info)
{
   // Рисуем линию
   name += (string)time1;
   ObjectCreate(name, OBJ_TREND, 0, 0, 0, 0, 0);
   ObjectSet(name, OBJPROP_TIME1, time1);
   ObjectSet(name, OBJPROP_PRICE1, price1);
   if (!ObjectGet(name, OBJPROP_TIME2))                  // Если time2 не задан у объекта, тогда задаем, т.к. это новый объект (для редктирования угла наклона)
      ObjectSet(name, OBJPROP_TIME2, time2);
   else   
      time2 = (datetime)ObjectGet(name, OBJPROP_TIME2);            // Подкорректируем time2 взяв значение из линни (с отредактированным углом наклона) 
   ObjectSet(name, OBJPROP_PRICE2, price2);
   ObjectSet(name, OBJPROP_COLOR, clr);                  // Цвет
   ObjectSet(name, OBJPROP_TIMEFRAMES, timeframe);       // Таймфрейм для отображения
   ObjectSet(name, OBJPROP_BACK, true);                  // Рисовать объект в фоне
   ObjectSet(name, OBJPROP_SELECTED, false);             // Снять выделение с объекта
   ObjectSet(name, OBJPROP_RAY, false);                  // Рисовать не луч
   ObjectSet(name, OBJPROP_STYLE, 0);                    // Стиль
   ObjectSet(name, OBJPROP_WIDTH, 1);                    // Толщина
   
   // Рисуем зону
   if (price1 > price2) name += "_H"; else name += "_L";
   name += "_" + DoubleToStr(info, 0);
   if (price3 < price4) { price1 = price3; price3 = price4; price4 = price1; }
   bool cr = ObjectCreate(name, OBJ_RECTANGLE, 0, 0, 0, 0, 0);
   ObjectSet(name, OBJPROP_TIME1, time2);
   ObjectSet(name, OBJPROP_PRICE1, price3);
   if (!ObjectGet(name, OBJPROP_TIME2)) 
      ObjectSet(name, OBJPROP_TIME2, correctWeekend(time2, time2 + length)); // Если time2 не задан у объекта, тогда задаем, т.к. это новый объект (иначе у зоны отредктирована длина)
   ObjectSet(name, OBJPROP_PRICE2, price4);
   
   descr += " [" + DoubleToStr(price3, _Digits) + " - " + DoubleToStr(price4, _Digits) + "]";
   ObjectSetText(name, descr);                           // Описание
   if (cr) ObjectSet(name, OBJPROP_COLOR, clr);          // Цвет
   ObjectSet(name, OBJPROP_TIMEFRAMES, timeframe);       // Таймфрейм для отображения
   ObjectSet(name, OBJPROP_SELECTED, false);             // Снять выделение с объекта
   ObjectSet(name, OBJPROP_BACK, true);                  // Рисовать объект в фоне
   
   // Дополнительная линия
   if (NKZ_widthL && StringSubstr(name, 0, 3) == "NKZ")
   {
      double time3 = ObjectGet(name, OBJPROP_TIME2);
      name = StringSubstr(name, 0, 24) + "L50";
      ObjectCreate(name, OBJ_TREND, 0, 0, 0, 0, 0);
      ObjectSet(name, OBJPROP_TIME1, time2);
      ObjectSet(name, OBJPROP_PRICE1, price2);
      ObjectSet(name, OBJPROP_TIME2, time3);
      ObjectSet(name, OBJPROP_PRICE2, price2);
      ObjectSet(name, OBJPROP_TIMEFRAMES, timeframe);       // Таймфрейм для отображения
      ObjectSet(name, OBJPROP_BACK, true);                  // Рисовать объект в фоне
      ObjectSet(name, OBJPROP_SELECTED, false);             // Снять выделение с объекта
      ObjectSet(name, OBJPROP_RAY, false);                  // Рисовать не луч
      ObjectSet(name, OBJPROP_COLOR, NKZ_colorL);           // Цвет
      ObjectSet(name, OBJPROP_STYLE, NKZ_styleL);           // Стиль
      ObjectSet(name, OBJPROP_WIDTH, NKZ_widthL);           // Толщина
      StringReplace(name, "L50", "");
   }   
   //string prefix = StringSubstr(name, 1, 3);
   //if (sound && (prefix == "KZ_" || prefix == "KZ1")) PlaySound(sound_Zona);
   if (sound) PlaySound(sound_Zona);
   InitRect();
   Gde_Zonki();
}

//+------------------------------------------------------------------+
//| Рисование банковского уровня                                     |
//+------------------------------------------------------------------+
void DrawBank(datetime time1, double price1, double percent)
{
   // Рисуем линию
   int newBank = 0;
   string descr = "Банк", name = "Bank_" + TimeToString(time1);          // Название Bank_ не менять, используется в обработчике событий
   datetime time2 = time1 +  B_length;
   if (!B_length)
   {
      MqlDateTime date;
      TimeToStruct(time1, date);
      time2 = datetime(IntegerToString(date.year) + "." + IntegerToString(date.mon) + "." + IntegerToString(date.day) + " 23:59");
   }
   time2 = correctWeekend(time1, time2);
   if (ObjectFind(name) == -1) 
   {
      if (sound) PlaySound(sound_Blevel);
      newBank = 1;
   }
   else
   {
      string pr = ObjectGetString(0, name, OBJPROP_TEXT);
      StringReplace(pr, descr, "");
      StringReplace(pr, ", ", ".");
      percent = double(pr);
   }
   
   ObjectCreate(name, OBJ_TREND, 0, 0, 0, 0, 0);
   ObjectSet(name, OBJPROP_TIME1, time1);
   if (!price1) price1 = ObjectGet(name, OBJPROP_PRICE1); // Если price1 не задан, вызов пришел после редактирования описания Б.уровня. Возьмем цену из линии
   ObjectSet(name, OBJPROP_PRICE1, price1);
   if (!ObjectGet(name, OBJPROP_TIME2))                   // Если time2 не задан у объекта, тогда задаем, т.к. это новый объект
      ObjectSet(name, OBJPROP_TIME2, time2);
   else   
      time2 = (datetime)ObjectGet(name, OBJPROP_TIME2);             // Подкорректируем time2 взяв значение из Б.уровня (с отредактированной длинной)
   ObjectSet(name, OBJPROP_PRICE2, price1);
   ObjectSetText(name, descr + " " + DoubleToString(percent, 2) + "%");
   ObjectSet(name, OBJPROP_TIMEFRAMES, B_timeframe);      // Таймфрейм для отображения
   ObjectSet(name, OBJPROP_COLOR, B_color);               // Цвет
   ObjectSet(name, OBJPROP_WIDTH, B_width);               // Толщина
   ObjectSet(name, OBJPROP_STYLE, B_style);               // Стиль   
   ObjectSet(name, OBJPROP_BACK, B_back);                 // Рисовать объект в фоне
   //ObjectSet(name, OBJPROP_SELECTED, false);            // Снять выделение с объекта
   ObjectSet(name, OBJPROP_RAY, false);                   // Рисовать не луч


   // Нарисуем зоны
   double priceZ1, priceZ2, heightZ;
   int k;
   heightZ = price1 * percent / 100 / 10;
   for (int i = 1; i <= B_orderZ * 2; i++)
   {
      k = i;
      name = "BankZ_" + (string)time1 + " " + (string)i;
      if (i > B_orderZ) k = -(i - B_orderZ);
      priceZ1 = price1 + price1 * percent * k / 100;
      priceZ2 = price1 + price1 * percent * k *2/ 100;
//      priceZ2 = priceZ1 - heightZ * k / MathAbs(k);
      if (priceZ1 < priceZ2) { double price = priceZ1; priceZ1 = priceZ2; priceZ2 = price; }
      descr = DoubleToString((percent * 2 * k), 2) + "%";
      if (newBank) ObjectCreate(name, OBJ_RECTANGLE, 0, 0, 0, 0, 0);
      ObjectSet(name, OBJPROP_TIME1, time1);
      ObjectSet(name, OBJPROP_PRICE1, priceZ1);
      ObjectSet(name, OBJPROP_TIME2, time2);
      ObjectSet(name, OBJPROP_PRICE2, priceZ2);
      ObjectSetText(name, descr);                         // Описание
      ObjectSet(name, OBJPROP_COLOR, B_colorZ);           // Цвет
   ObjectSet(name, OBJPROP_WIDTH, B_width);               // Толщина
      ObjectSet(name, OBJPROP_TIMEFRAMES, B_timeframe);   // Таймфрейм для отображения
      ObjectSet(name, OBJPROP_SELECTED, false);           // Снять выделение с объекта
      ObjectSet(name, OBJPROP_BACK, false);                // Рисовать объект в фоне
   }
   InitRect();
 }
 
//+------------------------------------------------------------------+
//| Рисование ATR уровнеей                                           |
//+------------------------------------------------------------------+
void DrawATR(datetime time1 = 0)
{
   static int ATRr = 0, dayd = 0, summs = 0;
   int update = 0;

   // Рассчет ATR
   if (dayd != TimeDay(TimeCurrent()) || !ATRr) // Что бы не пересчитывать каждый раз
   {
      int finish;
      dayd = TimeDay(TimeCurrent());
      if (ATR_W1) finish = iBarShift(NULL, PERIOD_D1, iTime(NULL, PERIOD_W1, 0), false) + 1;
      else finish = 1;
      for (int i = ATR_hist - 1 + finish; i >= finish; i--)
         summs += (int)((iHigh(NULL, PERIOD_D1, i) - iLow(NULL, PERIOD_D1, i)) / _Point);
      ATRr = summs / ATR_hist;
   }
   if (!time1)
   {
      time1 = TimeCurrent();
      update = 1;
   }
   if (!update && sound) PlaySound(sound_Zona);
   MqlDateTime date;
   TimeToStruct(time1, date);
   time1 = datetime((string)date.year + "." + (string)date.mon + "." + (string)date.day + " 00:00");
   TimeToStruct(time1 + 86400, date);
   datetime time2 = datetime((string)date.year + "." + (string)date.mon + "." + (string)date.day + " 00:00");
   
   int shift = iBarShift(NULL, PERIOD_D1, time1, false);
   double price1 = iLow(NULL, PERIOD_D1, shift) + ATRr * _Point;
   double price2 = iHigh(NULL, PERIOD_D1, shift) - ATRr * _Point;
   
   // Рисуем линию
   string descr;
   int clr;
   for (int i = 1; i <= 2; i++)
   {
      descr = "ATR от Low " + (string)ATRr + "п.";
      clr = ATR_colorL;
      if (i == 2)
      {
         price1 = price2;
         descr = "ATR от Hi " + (string)ATRr + "п.";
         clr = ATR_colorH;
      }
      string name = "ATR_" + (string)time1 + " " + (string)i;                  // Название ATR_ не менять, используется в обработчике событий
      
      if (!update && ObjectFind(name) != -1)
      { 
         ObjectDelete("ATR_" + (string)time1 + " 1");
         ObjectDelete("ATR_" + (string)time1 + " 2");
         return;
      }
      if (!update) ObjectCreate(name, OBJ_TREND, 0, 0, 0, 0, 0);
      ObjectSet(name, OBJPROP_TIME1, time1);
      ObjectSet(name, OBJPROP_PRICE1, price1);
      ObjectSet(name, OBJPROP_TIME2, time2);
      ObjectSet(name, OBJPROP_PRICE2, price1);
      ObjectSetText(name, descr);                              // Описание         
      ObjectSet(name, OBJPROP_TIMEFRAMES, ATR_timeframe);      // Таймфрейм для отображения
      ObjectSet(name, OBJPROP_WIDTH, ATR_width);               // Толщина
      ObjectSet(name, OBJPROP_STYLE, ATR_style);               // Стиль
      ObjectSet(name, OBJPROP_COLOR, clr);                     // Цвет
      ObjectSet(name, OBJPROP_BACK, ATR_back);                 // Рисовать объект в фоне
      ObjectSet(name, OBJPROP_SELECTED, false);                // Снять выделение с объекта
      ObjectSet(name, OBJPROP_SELECTABLE, false);              // Запрет на редактирование
      ObjectSet(name, OBJPROP_RAY, false);                     // Рисовать не луч
   }
   TimeToStruct(TimeCurrent(), date);
   time1 = datetime((string)date.year + "." + (string)date.mon + "." + (string)date.day + " 00:00");
   if (ObjectFind("ATR_" + (string)time1 + " 1") != -1 || ObjectFind("ATR_" + (string)time1 + " 2") != -1) AtrFL = 1; else AtrFL = 0;
}

//+------------------------------------------------------------------+
//| Рисование Hi Low уровнеей                                        |
//+------------------------------------------------------------------+
void DrawHiLow(datetime time1 = 0)
{
   int update = 0;
   if (!time1) update = 1;
   
   if (!update)
   {
      if (sound) PlaySound(sound_Zona);
      if (DeleteByPrefix("HiLow_"))  // Зашли по клавише и удаляем объекты
      {
         HiLowFL = 0;
         return; 
      }
   }
   static datetime timeOld;
   time1 = TimeCurrent();
   datetime time2 = time1 + 86400;
   MqlDateTime date;
   TimeToStruct(time1, date);
   time1 = datetime((string)date.year + "." + (string)date.mon + "." + (string)date.day + " 00:00");
   TimeToStruct(time2, date);
   time2 = datetime((string)date.year + "." + (string)date.mon + "." + (string)date.day + " 00:00");
   timeOld = time1 ;
   double price1, price2;
   int shift, clr;
   for (int j = 0; j < HiLow_count; j++)
   {
      shift = iBarShift(NULL, PERIOD_D1, time1, true);
      if (shift != -1)
      {
         price1 = iLow(NULL, PERIOD_D1, shift+1);                        // поставив +1 хай лоу предыдущего дня стал рисоваться на текущем
         price2 = iHigh(NULL, PERIOD_D1, shift+1);                       // поставив +1 хай лоу предыдущего дня стал рисоваться на текущем
         clr = HiLow_color;
         if (TimeDayOfWeek(time1) == 5) clr = HiLow_colorF;
         // Рисуем линии
         for (int i = 1; i <= 2; i++)
         {
            if (i == 2) price1 = price2;
            string name = "HiLow_" + (string)time1 + " " + (string)i;             // Название HiLow_ не менять, используется в обработчике событий      
            if (!update) ObjectCreate(name, OBJ_TREND, 0, 0, 0, 0, 0);
            ObjectSet(name, OBJPROP_TIME1, time1);
            ObjectSet(name, OBJPROP_PRICE1, price1);
            ObjectSet(name, OBJPROP_TIME2, time2);
            ObjectSet(name, OBJPROP_PRICE2, price1);
            ObjectSet(name, OBJPROP_TIMEFRAMES, HiLow_timeframe); // Таймфрейм для отображения
            ObjectSet(name, OBJPROP_WIDTH, HiLow_width);          // Толщина
            ObjectSet(name, OBJPROP_STYLE, HiLow_style);          // Стиль
            ObjectSet(name, OBJPROP_COLOR, clr);                  // Цвет
            ObjectSet(name, OBJPROP_BACK, HiLow_back);            // Рисовать объект в фоне
            ObjectSet(name, OBJPROP_SELECTED, false);             // Снять выделение с объекта
            //ObjectSet(name, OBJPROP_SELECTABLE, false);         // Запрет на редактирование
            ObjectSet(name, OBJPROP_RAY, false);                  // Рисовать не луч
         }
      }
      if (update) break;
      time2 = time1;
      time1 -= 86400;
   }
   TimeToStruct(TimeCurrent(), date);
   time1 = datetime((string)date.year + "." + (string)date.mon + "." + (string)date.day + " 00:00");
   if (ObjectFind("HiLow_" + (string)time1 + " 1") != -1 || ObjectFind("HiLow_" + (string)time1 + " 2") != -1) HiLowFL = 1; else HiLowFL  = 0;
}

//+------------------------------------------------------------------+
//| Нормализует цену                                                 |
//+------------------------------------------------------------------+
double NormalizePrice(double price)
{
   return MathRound(price / SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE)) * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
}

//+------------------------------------------------------------------+
//| Рисование коррекционного уровня                                  |
//+------------------------------------------------------------------+
void DrawCorrect(datetime time1 = 0, double price1 = 0, int HiLow = 0)
{  
   static int CorrectAlert, CorrectAlertTime;
   static double price50;
   double price2, price3;
   datetime time2, time3;
   string name, basename = "Correct";
   int update = 0;

   if (!CorrectAlertTime) CorrectAlertTime = (int)ObjectGet("CorrectInfo", OBJPROP_TIME1);
   if (!CorrectAlert) CorrectAlert = (int)ObjectGetString(0, "CorrectInfo", OBJPROP_TEXT);
   if (!price50) price50 = ObjectGet("CorrectInfo", OBJPROP_PRICE1);

   name = basename + "1";
   if (!time1)
   {
      update = 1;
      price1 = ObjectGet(name, OBJPROP_PRICE1);
      if (!price1)
      {
         CorrectFL = 0; // Нет уровня на графике, а значит нет смысла каждый тик заходить в эту функцию
         return;
      } 
      time1 = (datetime)ObjectGet(name, OBJPROP_TIME1);
      if  (price1 > ObjectGet(name, OBJPROP_PRICE2)) HiLow = 1; else HiLow = -1;
   }
   if (update || time1 != ObjectGet(name, OBJPROP_TIME1)) // Если обновление или создание, иначе удаляем
   {
      int shift = iBarShift(NULL, 0, time1, false);
      if (HiLow  == 1)
      {
         if (shift) shift = iLowest(NULL, 0, MODE_LOW, shift, 0);
         price2 = iLow(NULL, 0, shift);
         time2 = iTime(NULL, 0, shift);
      }
      else
      {
         if (shift) shift = iHighest(NULL, 0, MODE_HIGH, shift, 0);
         price2 = iHigh(NULL, 0, shift);
         time2 = iTime(NULL, 0, shift);
      }
      if (!update) CorrectAlert = CorrectAlertTime = 0;     // Только что нарисовали, обнулим счетчик
      ObjectCreate(name, OBJ_TREND, 0, 0, 0, 0, 0);
      ObjectSet(name, OBJPROP_TIME1, time1);
      ObjectSet(name, OBJPROP_PRICE1, price1);
      ObjectSet(name, OBJPROP_TIME2, time2);
      ObjectSet(name, OBJPROP_PRICE2, price2);
      ObjectSet(name, OBJPROP_RAY, false);                  // Рисовать не луч
      ObjectSet(name, OBJPROP_COLOR, Correct_color1);       // Цвет
      ObjectSet(name, OBJPROP_STYLE, Correct_style1);       // Стиль
      ObjectSet(name, OBJPROP_WIDTH, Correct_width1);       // Толщина
      ObjectSet(name, OBJPROP_BACK, Correct_back1);         // Рисовать объект в фоне
      ObjectSet(name, OBJPROP_SELECTED, false);             // Выделенность объекта
      ObjectSet(name, OBJPROP_HIDDEN, true);                // Запрет на показ имени графического объекта в списке объектов 
      //ObjectSet(name, OBJPROP_SELECTABLE, false);           // Доступность объекта для редактирования
      
      time3 = correctWeekend(TimeCurrent(), TimeCurrent() + Correct_length);
      int clr, style, width, back, n = 2;
      for (int i = ArraySize(Correct_listD) - 1; i >= 0; i--)
      {
         price3 = price1 - MathAbs(price1 - price2) * HiLow * (100 - Correct_listD[i]) / 100;
         if (Correct_listD[i] == 50)
            {
               clr = Correct_color2; style = Correct_style2; width = Correct_width2; back = Correct_back2; price50 = price3;
               name = "Correct2_text";
               ObjectCreate(0, name, OBJ_TEXT, 0, 0, 0);
               ObjectSet(name, OBJPROP_HIDDEN, true);      
               ObjectSetString(0, name, OBJPROP_TEXT, (string)CorrectAlert);
               ObjectSet(name, OBJPROP_TIME1, time3);
               ObjectSet(name, OBJPROP_PRICE1, price50);
               ObjectSetText(name, (string)NormalizePrice(price50), Correct_FontS2, Correct_FontN2, Correct_FontC2);
               ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_RIGHT_LOWER);
            }
         else
            {clr = Correct_colorD; style = Correct_styleD; width = Correct_widthD; back = Correct_backD;}
         name = (string)basename + (string)(n++);
         ObjectCreate(name, OBJ_TREND, 0, 0, 0, 0, 0);
         ObjectSet(name, OBJPROP_TIME1, time1);
         ObjectSet(name, OBJPROP_PRICE1, price3);
         ObjectSet(name, OBJPROP_TIME2, time3);
         ObjectSet(name, OBJPROP_PRICE2, price3);
         ObjectSetText(name, (string)Correct_listD[i] + "%");          // Описание
         ObjectSet(name, OBJPROP_RAY, false);                  // Рисовать не луч
         ObjectSet(name, OBJPROP_COLOR, clr);                  // Цвет
         ObjectSet(name, OBJPROP_STYLE, style);                // Стиль
         ObjectSet(name, OBJPROP_WIDTH, width);                // Толщина
         ObjectSet(name, OBJPROP_BACK, back);                  // Рисовать объект в фоне
         ObjectSet(name, OBJPROP_SELECTED, false);             // Выделенность объекта
         ObjectSet(name, OBJPROP_HIDDEN, true);                // Запрет на показ имени графического объекта в списке объектов 
         ObjectSet(name, OBJPROP_SELECTABLE, false);           // Доступность объекта для редактирования
      }
      CorrectFL = 1;
   }
   else
   {
      DeleteByPrefix("Correct");
      CorrectFL = 0;
   }
   if ((CorrectFL && price50 && (HiLow == 1 && Bid >= price50)) || (HiLow == -1 && Bid <= price50))
   {
      if (ZonaAlert && !CorrectAlert && TimeCurrent() - CorrectAlertTime >= Correct_time)
      {
         CorrectAlert = 1;
         CorrectAlertTime = (int)TimeCurrent();
         if (ZonaAlertSound) PlaySound(sound_Correct);
         update = 1; // Что бы не было звука в конце функции
         if (ZonaAlertMode)
            AlertInfoAdd(ChartID(), _Symbol + ": заход за уровень 50%"); // Добавить строку в Alert
         else
            Alert(_Symbol + ": заход за уровень 50%");
      }
   }
   else
      CorrectAlert = 0;

   name = "CorrectInfo";
   ObjectCreate(0, name, OBJ_TEXT, 0, 0, 0);
   ObjectSet(name, OBJPROP_TIMEFRAMES, EMPTY);
   ObjectSet(name, OBJPROP_HIDDEN, true);      
   ObjectSetString(0, name, OBJPROP_TEXT, (string)CorrectAlert);
   ObjectSet(name, OBJPROP_TIME1, CorrectAlertTime);
   ObjectSet(name, OBJPROP_PRICE1, price50);

   if (!update && sound) PlaySound(sound_Zona);
}
//+------------------------------------------------------------------+
//| Корректирует координаты цены и времени если нужно для зон        |
//+------------------------------------------------------------------+
void CorrectRect(string name)
{
   datetime time;
   double price;
   if (ObjectGet(name, OBJPROP_TIME1) > ObjectGet(name, OBJPROP_TIME2))
   {
      time = (datetime)ObjectGet(name, OBJPROP_TIME1);
      ObjectSet(name, OBJPROP_TIME1, ObjectGet(name, OBJPROP_TIME2));
      ObjectSet(name, OBJPROP_TIME2, time);
   }
   if (ObjectGet(name, OBJPROP_PRICE1) < ObjectGet(name, OBJPROP_PRICE2))
   {
      price = ObjectGet(name, OBJPROP_PRICE1);
      ObjectSet(name, OBJPROP_PRICE1, ObjectGet(name, OBJPROP_PRICE2));
      ObjectSet(name, OBJPROP_PRICE2, price);
   }
}

//+------------------------------------------------------------------+
//| Ищет зоны в диапазоне цены                                       |
//+------------------------------------------------------------------+
void InitRect(string nameP = "")
{
   RectFL = 0;
   if (!ZonaAlert) return;
   string name;

   if (nameP == "ALL_OBJECTS_RECT_CORRECT")
   {
      for (int i = ObjectsTotal() - 1; i >= 0; i--)
         if (ObjectType(name = ObjectName(i)) == OBJ_RECTANGLE) CorrectRect(name);
   }
   else if (nameP != "")
   {
      if (ObjectType(nameP) == OBJ_RECTANGLE) CorrectRect(nameP);
   }

   ArrayResize(ListRect, 0);
   for (int i = ObjectsTotal() - 1; i >= 0; i--)
   {
      if (ObjectType(name = ObjectName(i)) == OBJ_RECTANGLE)
      {
         if (ObjectGet(name, OBJPROP_TIME1) <= TimeCurrent() && ObjectGet(name, OBJPROP_TIME2) >= TimeCurrent())
         {
            ArrayResize(ListRect, ArraySize(ListRect) + 1); 
            ListRect[ArraySize(ListRect) - 1].name = name;
            ListRect[ArraySize(ListRect) - 1].time = (datetime)ObjectGet("LR_" + name, OBJPROP_TIME1);
            RectFL = 1;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Сигнализирует о том что цена зашла в зону                        |
//+------------------------------------------------------------------+
void AlertRect()
{
   string name;
   string sss = "";
   double price_L = 0, price_H = 0, hight = 0;
   int shift;
   for (int i = ArraySize(ListRect) - 1; i >= 0; i--)
   {
      name = ListRect[i].name;
      if (ObjectGet(name, OBJPROP_PRICE1) >= Bid && ObjectGet(name, OBJPROP_PRICE2) <= Bid)
      {
         if (ListRect[i].time)
         {
            shift = iBarShift(NULL, 0, ListRect[i].time, false);
            if (shift)
            {
               price_L = iLow(NULL, 0, iLowest(NULL, 0, MODE_LOW, shift, 0));
               price_H = iHigh(NULL, 0, iHighest(NULL, 0, MODE_HIGH, shift, 0));
            }
            else
            continue;
            hight = ObjectGet(name, OBJPROP_PRICE1) - ObjectGet(name, OBJPROP_PRICE2);
         }
         if (!ListRect[i].time || price_H - ObjectGet(name, OBJPROP_PRICE1) >= hight || ObjectGet(name, OBJPROP_PRICE2) - price_L >= hight)
         {
            ListRect[i].time = TimeCurrent();
            string descr = ObjectGetString(0, name, OBJPROP_TEXT);
            if (descr == "") descr = name;

            name = "LR_" + name;
            ObjectCreate(0, name, OBJ_TEXT, 0, 0, 0);
            ObjectSet(name, OBJPROP_TIME1, ListRect[i].time);
            ObjectSet(name, OBJPROP_TIMEFRAMES , EMPTY);            
            ObjectSet(name, OBJPROP_HIDDEN, true);

            if (ZonaAlertMode)
               AlertInfoAdd(ChartID(), _Symbol + ": заход в зону  " + descr); // Добавить строку в Alert
            else
               Alert(_Symbol + ": заход в зону  " + descr);
            if (ZonaAlertSound) PlaySound(sound_Correct);
         }
      }
   }
   //Comment(sss);
}

////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////

//+------------------------------------------------------------------+
//| Отправка события во все окна                                     |
//+------------------------------------------------------------------+
void SendAllEvent(int id, long lparam = 0, double dparam = 0, string sparam = "")
{
   long currChart = ChartFirst();
   for (int i = 0; i < CHARTS_MAX; i++)
   {
      EventChartCustom(currChart, (ushort)id, lparam, dparam, sparam);
      if ((currChart = ChartNext(currChart)) < 0) break;
   }
}

//+------------------------------------------------------------------+
//| Создание Алерт окна                                              |
//+------------------------------------------------------------------+
void AlertInfoInit()
{
   int indent1 = 6;
   int corner = 2;
   string name;
   //DeleteByPrefix("AlertInfo");
   
   name = "AlertInfoRectT";
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, indent1 + 4);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, indent1 - 4 + AlertHeight);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, AlertWidth);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, AlertHeight);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, C'90,90,90');
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 0);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSet(name, OBJPROP_SELECTED, false);      // Выделенность объекта
   ObjectSet(name, OBJPROP_HIDDEN, true);         // Запрет на показ имени графического объекта в списке объектов 
   ObjectSet(name, OBJPROP_SELECTABLE, false);    // Доступность объекта для редактирования
   ObjectSet(name, OBJPROP_TIMEFRAMES, EMPTY);

   name = "AlertInfoRectK";
   ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
   ObjectSet(name, OBJPROP_CORNER, corner);
   ObjectSet(name, OBJPROP_YDISTANCE, indent1 + AlertHeight);
   ObjectSet(name, OBJPROP_XDISTANCE, indent1 + AlertWidth - 58);
   ObjectSet(name, OBJPROP_SELECTED, false);      // Выделенность объекта
   ObjectSet(name, OBJPROP_HIDDEN, true);         // Запрет на показ имени графического объекта в списке объектов 
   ObjectSet(name, OBJPROP_SELECTABLE, false);    // Доступность объекта для редактирования
   ObjectSet(name, OBJPROP_TIMEFRAMES, EMPTY);
   ObjectSet(name, OBJPROP_FONTSIZE, AlertFontSize);
   ObjectSetText(name, "Spase, Esc", 8, "Arial", AlertBorderClr);
   
   name = "AlertInfoRect";
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, indent1);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, indent1 + AlertHeight);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, AlertWidth);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, AlertHeight);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, AlertBackClr);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, 0);
   ObjectSetInteger(0, name, OBJPROP_COLOR, AlertBorderClr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, AlertBorderSt);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, AlertBorderWid);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSet(name, OBJPROP_SELECTED, false);      // Выделенность объекта
   ObjectSet(name, OBJPROP_HIDDEN, true);         // Запрет на показ имени графического объекта в списке объектов 
   ObjectSet(name, OBJPROP_SELECTABLE, false);    // Доступность объекта для редактирования
   ObjectSet(name, OBJPROP_TIMEFRAMES, EMPTY);

   for (int i = 1; i <= AlertICount; i++)
   {
      name = "AlertInfoLabel" + (string)i;
      ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
      ObjectSet(name, OBJPROP_CORNER, corner);
      ObjectSet(name, OBJPROP_YDISTANCE, indent1 + 10 + (i - 1) * 20);
      ObjectSet(name, OBJPROP_XDISTANCE, indent1 + 10);
      ObjectSet(name, OBJPROP_SELECTED, false);      // Выделенность объекта
      ObjectSet(name, OBJPROP_HIDDEN, true);         // Запрет на показ имени графического объекта в списке объектов 
      ObjectSet(name, OBJPROP_SELECTABLE, false);    // Доступность объекта для редактирования
      ObjectSet(name, OBJPROP_TIMEFRAMES, EMPTY);
      ObjectSet(name, OBJPROP_FONTSIZE, AlertFontSize);
      ObjectSetText(name, " ");
      ObjectSetString(0, name, OBJPROP_TOOLTIP, NULL);
   }
}

//+------------------------------------------------------------------+
//| Показать Алерт окно                                              |
//+------------------------------------------------------------------+
void AlertInfoShow()
{   
   ObjectSet("AlertInfoRectT", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSet("AlertInfoRectK", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSet("AlertInfoRect", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   string name = "AlertInfoLabel";
   long chID = ChartFirst();
   for (int i = 1; i <= AlertICount; i++)
   {
      ObjectSetString(0, name + (string)i, OBJPROP_TEXT, ObjectGetString(chID, name + (string)i, OBJPROP_TEXT));
      ObjectSetString(0, name + (string)i, OBJPROP_FONT, ObjectGetString(chID, name + (string)i, OBJPROP_FONT));
      ObjectSetString(0, name + (string)i, OBJPROP_TOOLTIP, ObjectGetString(chID, name + (string)i, OBJPROP_TOOLTIP));
      ObjectSetInteger(0, name + (string)i, OBJPROP_COLOR, ObjectGetInteger(chID, name + (string)i, OBJPROP_COLOR));
      ObjectSetInteger(0, name + (string)i, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   }
   GlobalVariableSet("DN_new_event", 1); // Есть не просмотренные события, но обновлять окно не нужно в OnTimer()
}

//+------------------------------------------------------------------+
//| Добавить событие в первое Алерт окно                             |
//+------------------------------------------------------------------+
void AlertInfoAdd(long chartID, string item, int clr = 0)
{   
   if (!clr) clr = AlertFontClrNew;
   string name = "AlertInfoLabel";
   long chID = ChartFirst();
   for (int i = 1; i < AlertICount; i++)
   {
      ObjectSetString(chID, name + (string)i, OBJPROP_TEXT, ObjectGetString(chID, name + (string)(i + 1), OBJPROP_TEXT));
      ObjectSetString(chID, name + (string)i, OBJPROP_FONT, ObjectGetString(chID, name + (string)(i + 1), OBJPROP_FONT));
      ObjectSetString(chID, name + (string)i, OBJPROP_TOOLTIP, ObjectGetString(chID, name + (string)(i + 1), OBJPROP_TOOLTIP));
      ObjectSetInteger(chID, name + (string)i, OBJPROP_COLOR, ObjectGetInteger(chID, name + (string)(i + 1), OBJPROP_COLOR));
   }
   if (StringLen(item) > AlertStrLen) item = StringSubstr(item, 0, AlertStrLen) + "...";
   ObjectSetString(chID, name + (string)AlertICount, OBJPROP_TEXT, item);
   ObjectSetString(chID, name + (string)AlertICount, OBJPROP_FONT, AlertFontNew);
   ObjectSetString(chID, name + (string)AlertICount, OBJPROP_TOOLTIP, (string)chartID);
   ObjectSetInteger(chID, name + (string)AlertICount, OBJPROP_COLOR, clr);
   
   GlobalVariableSet("DN_new_event", 2); // Есть новые события, нужно обновить окно в OnTimer()
   
   if (ChartGetInteger(0, CHART_BRING_TO_TOP)) 
      AlertInfoShow();
   else if (ZonaAlertType)
   {
      long currChart = ChartFirst();
      for (int i = 0; i < CHARTS_MAX; i++)
      {
         if (ChartGetInteger(currChart, CHART_BRING_TO_TOP))
         {
            EventChartCustom(currChart, 3);
            break;
         }
         if ((currChart = ChartNext(currChart)) < 0) break;
      }
   }  
   // Мигание кнопкой
   if (IsDllsAllowed() || ZonaAlertFlash)
   {
      if (ZonaAlertFlash == 1) pfwi.dwFlags = 2;
      if (ZonaAlertFlash == 2) pfwi.dwFlags = 14;
      FlashWindowEx(pfwi);
   }
}

//+------------------------------------------------------------------+
//| Спрятать Алерт окно                                              |
//+------------------------------------------------------------------+
void AlertInfoHide(int eventnull = 0)
{
   if (ObjectGet("AlertInfoRect", OBJPROP_TIMEFRAMES) == EMPTY) return;
   long chID = ChartFirst();
   for (int i = 1; i <= AlertICount; i++)
   {
      if (eventnull)
      {
         ObjectSetString(chID, "AlertInfoLabel" + (string)i, OBJPROP_FONT, AlertFont);
         ObjectSetString(chID, "AlertInfoLabel" + (string)i, OBJPROP_TOOLTIP, NULL);
         ObjectSetInteger(chID, "AlertInfoLabel" + (string)i, OBJPROP_COLOR, AlertFontClr);
      }
      ObjectSetInteger(0, "AlertInfoLabel" + (string)i, OBJPROP_TIMEFRAMES, EMPTY);
   }
   ObjectSetInteger(0, "AlertInfoRectT", OBJPROP_TIMEFRAMES, EMPTY);
   ObjectSetInteger(0, "AlertInfoRectK", OBJPROP_TIMEFRAMES, EMPTY);
   ObjectSetInteger(0, "AlertInfoRect", OBJPROP_TIMEFRAMES, EMPTY);
   if (eventnull) GlobalVariableSet("DN_new_event", 0); // Все события просмотрены, показывать окно в OnTimer() не нужно
}

//+------------------------------------------------------------------+
//| Открыть окно грфифка с которой пришло событие                    |
//+------------------------------------------------------------------+
void AlertInfoWinJump()
{
   long chID = NULL, chID_first = ChartFirst();
   string name = "AlertInfoLabel";
   int notview = 0;
   for (int i = AlertICount; i >= 1; i--) 
      if (ObjectGetString(0, name + (string)i, OBJPROP_TOOLTIP) != "") // Есть не просмотренное событие
      {
         if (!chID) chID = (long)ObjectGetString(0, name + (string)i, OBJPROP_TOOLTIP);
         if (chID == (long)ObjectGetString(0, name + (string)i, OBJPROP_TOOLTIP)) 
         {
            ObjectSetString(chID_first, "AlertInfoLabel" + (string)i, OBJPROP_FONT, AlertFont);
            ObjectSetString(chID_first, "AlertInfoLabel" + (string)i, OBJPROP_TOOLTIP, NULL);
            ObjectSetInteger(chID_first, "AlertInfoLabel" + (string)i, OBJPROP_COLOR, AlertFontClr);         
            ObjectSetString(0, "AlertInfoLabel" + (string)i, OBJPROP_FONT, AlertFont);
            ObjectSetString(0, "AlertInfoLabel" + (string)i, OBJPROP_TOOLTIP, NULL);
            ObjectSetInteger(0, "AlertInfoLabel" + (string)i, OBJPROP_COLOR, AlertFontClr);   
        }
        else
            notview++;
      }
   if (!notview) AlertInfoHide(1);  // Скрыть Алерт окно, если все события просмотрены
   WinShow(chID);
   EventChartCustom(chID, 4, chID); // Установим фокус ввода (обработчик в рисменеджере)
}

//+------------------------------------------------------------------+
//| Поиск окна графика по названию инструмента                       |
//+------------------------------------------------------------------+
long findChart(string symbol)
{
   long currChart = ChartFirst();
   for (int i = 0; i < CHARTS_MAX; i++)
   {
      if (ChartSymbol(currChart) == symbol) break;
      if ((currChart = ChartNext(currChart)) == -1) break;
   }
   return currChart;
}

//+------------------------------------------------------------------+
//| Показать окно графика                                            |
//+------------------------------------------------------------------+
void WinShow(long currChart, string symbol = NULL)
{
   if (symbol == "") currChart = findChart(symbol);
   if (currChart < 0) return;
   ChartSetInteger(currChart, CHART_BRING_TO_TOP, 1);
   ChartRedraw(currChart);
 }
 
//+------------------------------------------------------------------+
//| Изменение маштаба графика                                        |
//+------------------------------------------------------------------+
void ChangeScale(int direct)
{
   int scale = (int)ChartGetInteger(0, CHART_SCALE);
   if (direct) 
      ChartSetInteger(0, CHART_SCALE, 0, scale + 1);
   else      
      ChartSetInteger(0, CHART_SCALE, 0, scale - 1);
   ChartNavigate(0, CHART_END, 0);
}

//+------------------------------------------------------------------+
//| Изменение таймфрейма графика                                     |
//+------------------------------------------------------------------+
void ChangePeriod(int direct)
{
   static int TF[] = {1, 5, 15, 30, 60, 240, 1440, 10080, 43200};
   int i, p = _Period;
   for (i = 0; i < ArraySize(TF); i++) if (p == TF[i]) break;
   //Print(" --- i: "+i);
   if (direct) 
      i = i - 1; // E
   else      
      i = i + 1; // D
   if (i < 0) i = 0;
   if (i >= ArraySize(TF)) i = ArraySize(TF) - 1;
   ChartSetSymbolPeriod(0, NULL, TF[i]);
}
//*--------------------------------------------------------------------*
//| Расчет АТР
//*--------------------------------------------------------------------*
void ATR_na_monitor()
{
   int summ = 0;
   double seg = 0;
   int update = 0;
   // Рассчет ATR
   if (TimeCurrent() - day > 60 || !ATR) // Что бы не пересчитывать каждый раз
   {
      datetime time1;
      day = TimeCurrent();
      hist = 0;
      for (int i = ATR_hist; i > 0; i--)
         {
         time1 = iTime(NULL, PERIOD_D1, i);
         if(iBarShift(NULL, PERIOD_M30, time1, false) >= 0)
            {
            summ += (int)((iHigh(NULL, PERIOD_D1, i) - iLow(NULL, PERIOD_D1, i)) / _Point);
            hist++;
            }
         }
      ATR = (double)summ / hist;
      ATR20 = ATR * ATR_SL; 
   }
   seg = (int)((iHigh(NULL, PERIOD_D1, 0) - iLow(NULL, PERIOD_D1, 0)) / _Point);
   if(norm == false) ObjectSetText( "tabl"+IntegerToString(1), "АТР(" + (string)hist + ") = " + DoubleToStr(ATR,0) + " ( " + DoubleToStr(seg,0) + " ); SL = " + DoubleToStr(ATR20,0));
   else ObjectSetText( "tabl"+IntegerToString(1), "АТР(" + (string)hist + ") = " + DoubleToStr(ATR/10,1) + " ( " + DoubleToStr(seg/10,1) + " ); SL = " + DoubleToStr(ATR20/10,1));
   if(ATR <= seg) 
      {
      ObjectSet( "tabl"+ IntegerToString(1), OBJPROP_COLOR, clrRed);
      ObjectSet( "tabl"+ IntegerToString(1), OBJPROP_FONTSIZE, razm2);
      }
   else 
      {
      ObjectSet( "tabl"+ IntegerToString(1), OBJPROP_COLOR, clrBlack); 
      ObjectSet( "tabl"+ IntegerToString(1), OBJPROP_FONTSIZE, razm1);
      }
   WindowRedraw();
   return;
}
//*--------------------------------------------------------------------*
//| Расчет Спреда
//*--------------------------------------------------------------------*
void Spred()
{
   double Spr;
   Spr = NormalizeDouble((Ask-Bid)/_Point,0);
   if(norm == false) ObjectSetText ( "tabl"+IntegerToString(2), "Спред = "+(string)Spr);
   else ObjectSetText ( "tabl"+IntegerToString(2), "Спред = " + DoubleToStr(Spr/10,1));
   return;
}
//*--------------------------------------------------------------------*
//| Считываем внешний файл для NKZ
//*--------------------------------------------------------------------*
void Read_File_NKZ()
   {
   DeleteByPrefix("Маржа_");
   int i=0;                                                      // Для перебора массива
   double NKZZr=0;
   ResetLastError();
   Handle=FileOpen(File_Name_NKZ,FILE_SHARE_READ|FILE_CSV,";");          // Открытие файла
   if(Handle == INVALID_HANDLE)                                                // Неудача при открытие файла
      {
      key_updat_nkz = 1;
      if(GetLastError()==4103)                                 // Если файла не существует
         {
         Alert("Нет файла с именем ",File_Name_NKZ);                // Извещаем
         return;
         }
      else if(GetLastError() > 0) 
         {
         Alert(_Symbol, " Ошибка при открытии файла Маржи №", GetLastError());         //
         return;
         }
      else if(GetLastError() == 0) 
         {
         return;
         }
      }
   while(FileIsEnding(Handle) == false)
      {
      Instr=FileReadString(Handle);                            // Считали название инструмента
      Str_DtTm=FileReadString(Handle);                         // Считали время
      Str_Marjin=FileReadString(Handle);                           // Считали маржинальные требования
      Str_Cena_Min=FileReadString(Handle);                         // Считали минимальную цену
      Dat_DtTm = StrToTime(Str_DtTm);                          // Преобразуем данные
      Marjin = StrToDouble(Str_Marjin);                        // Преобразуем данные
      Cena_Min = StrToDouble(Str_Cena_Min);                    // Преобразуем данные
      if(StringSubstr(_Symbol,0,6) == "USDRUB")
         {
         Instr_Symbol = "USDRUR";
         }
      else if(StringSubstr(_Symbol,0,6) == "#CL")
         {
         Instr_Symbol = "CL";
         }
      else if(StringSubstr(_Symbol,0,6) == "XAUUSD")
         {
         Instr_Symbol = "GOLD";
         }
      else Instr_Symbol=StringSubstr(_Symbol,0,6);
      if(Instr == Instr_Symbol)                                  // Если инструменты совпадают то заносим данные в массив
         {
         InffO[i].dateHist = Dat_DtTm;                         // Запишем стартовую дату
         InffO[i].MARGHA = Marjin;                         // Запишем маржу с сайта
         Marjin = Marjin * 1.1;                                      // Сделаем как у Митюкова
         if(Instr == "USDJPY" || Instr == "USDHUF" || Instr == "USDCZK" || Instr == "USDCNH")
            {
            NKZZr = (Marjin/Cena_Min)*10;
            NKZZr = (-1)*(NKZZr/10000000);
            }
         else if(Instr == "USDILS" || Instr == "USDMXN" || Instr == "USDPLN" || Instr == "USDRUR" || Instr == "USDSEK" || Instr == "USDNOK")
            {
            NKZZr = (Marjin/Cena_Min)*10;
            NKZZr = (-1)*(NKZZr/1000000);
            }
         else if(Instr == "USDCAD" || Instr == "USDCHF"  || Instr == "USDBRL")
            {
            NKZZr = (Marjin/Cena_Min)*10;
            NKZZr = (-1)*(NKZZr/100000);
            }
         else if(Instr == "GOLD")
            {
            NKZZr = (Marjin/Cena_Min)*10;
            NKZZr = NKZZr/100;
            }
         
            
                       
         else if(Instr == "CL")
            {
            NKZZr = (Marjin/Cena_Min)*10;
            NKZZr = NKZZr/10;
            }
         else
            {
            NKZZr = (Marjin/Cena_Min)*10;
            };
         InffO[i].NKZ = NKZZr;
         vertikal(i);
         i++;
         };
      if(FileIsEnding(Handle)==true) break;                    // Если файловый указатель в конце то выход из чтения
      }
   FileClose(Handle);                                          // Закрываем файл
   key_updat_nkz = 0;
   return;
   }
//*--------------------------------------------------------------------*
//| Выбираем строку из массива для НКЗ
//*--------------------------------------------------------------------*
void massiv(datetime time)
   {
   datetime Timm=0;
   for (int i = ArraySize(InffO) - 1; i >= 0; i--)
      {
      if(time > InffO[i].dateHist && InffO[i].dateHist > Timm)
         {
         Timm = InffO[i].dateHist;
         InffoKey = i;
         }
      }
   return;   
   }
//*--------------------------------------------------------------------*
//| Рисуем вертикальную линию с подписью о новой марже
//*--------------------------------------------------------------------*
void vertikal(int i)
   {
   string descr = "Маржа - " + (string)InffO[i].MARGHA + " (" + (string)InffO[i].NKZ + ")";
   datetime tim = InffO[i].dateHist;
   string name = "Маржа_" + (string)tim + " " + (string)InffO[i].NKZ;
   if(ObjectCreate(name,OBJ_VLINE,0,tim,0))
      {
      ObjectSet(name,OBJPROP_COLOR,Marj_color);
      ObjectSet(name,OBJPROP_STYLE,Marj_style);
      ObjectSet(name,OBJPROP_WIDTH,Marj_width);
      ObjectSet(name,OBJPROP_STYLE,Marj_style);
      ObjectSetText(name, descr);
      }
   return;
   }
//*--------------------------------------------------------------------*
//| Считываем внешний файл для Банковского уровня
//*--------------------------------------------------------------------*
void Read_File_BU()
   {
   int i=0, usd=0;                                                      // Для перебора массива
   string Sym_1, Sym_2; 
   double NKZZb=0;
   Handle=FileOpen(File_Name_BU,FILE_CSV|FILE_READ,";");          // Открытие файла
   if(Handle<0)                                                // Неудача при открытие файла
      {
      if(GetLastError()==4103)                                 // Если файла не существует
         Alert("Нет файла с именем ",File_Name_BU);                // Извещаем
      else                                                     // При другой ошибке
         Alert("Ошибка при открытии файла BU", GetLastError());         //
      PlaySound("Bzrrr.wav");                                  // Звуковое сопровождение 
      return;
      }
   while(FileIsEnding(Handle)==false)
      {
      Instr=FileReadString(Handle);                            // Считали название инструмента
      Str_DtTm=FileReadString(Handle);                         // Считали время
      Str_Procent=FileReadString(Handle);                           // Считали процентную ставку
      Dat_DtTm = StrToTime(Str_DtTm);                          // Преобразуем данные
      B_Procent = MathAbs(StringToDouble(Str_Procent));                        // Преобразуем данные
      Instr_Symbol=_Symbol;
      Sym_1 = StringSubstr(Instr_Symbol,0,3);
      Sym_2 = StringSubstr(Instr_Symbol,3,3);
      if(Instr == Sym_1 || Instr == Sym_2)                                  // Если инструменты совпадают то заносим данные в массив
         {
         if(Instr == "USD")
            {
            InfBU_USD[usd].dateHist = Dat_DtTm;
            InfBU_USD[usd].BU = B_Procent;
            usd++;
            }
         else
            {
            InfBU[i].dateHist = Dat_DtTm;
            InfBU[i].BU = B_Procent;
            i++;
            }
         }
      if(FileIsEnding(Handle)==true) break;                    // Если файловый указатель в конце то выход из чтения
      }
   FileClose(Handle);                                          // Закрываем файл
   return;
   }
//*--------------------------------------------------------------------*
//| Выбираем строку из массива для Банковского уровня
//*--------------------------------------------------------------------*
void massiv_bu(datetime time)
   {
   datetime Timm=0;
   double B_Proc = 0; 
   B_bankPercent = 0;
   for (int i = ArraySize(InfBU) - 1; i >= 0; i--)
      {
      if(time > InfBU[i].dateHist && InfBU[i].dateHist > Timm)
         {
         Timm = InfBU[i].dateHist;
         B_bankPercent = InfBU[i].BU;
         }
      }
   Timm = 0;
   for (int y = ArraySize(InfBU) - 1; y >= 0; y--)
      {
      if(time > InfBU_USD[y].dateHist && InfBU_USD[y].dateHist > Timm)
         {
         Timm = InfBU_USD[y].dateHist;
         B_Proc = InfBU_USD[y].BU;
         }
      }
   B_bankPercent = B_bankPercent + B_Proc;
   return;   
   }
//*--------------------------------------------------------------------*
//| Считываем внешний файл для зима лето Уровней Америки  // http://www.cmegroup.com/CmeWS/mvc/Margins/OUTRIGHT.csv?sortField=exchange&sortAsc=true&exchange=CME&sector=FX
//*--------------------------------------------------------------------*
void Read_File_ZL()
   {
   int usd=0, eur=0, rur=0, alf=0, ins=0;                                                      // Для перебора массива
   Handle=FileOpen(File_Name_UTC,FILE_CSV|FILE_READ,";");          // Открытие файла
   if(Handle<0)                                                // Неудача при открытие файла
      {
      if(GetLastError()==4103)                                 // Если файла не существует
         Alert("Нет файла с именем ",File_Name_UTC);                // Извещаем
      else                                                     // При другой ошибке
         Alert("Ошибка при открытии файла ZL", GetLastError());         //
      PlaySound("Bzrrr.wav");                                  // Звуковое сопровождение 
      return;
      }
   while(FileIsEnding(Handle)==false)
      {
      Instr=FileReadString(Handle);                            // Считали название инструмента
      Str_DtTm=FileReadString(Handle);                         // Считали время
      Str_UTC=FileReadString(Handle);                           // Считали отклонение от UTC
      Dat_DtTm = StrToTime(Str_DtTm);                          // Преобразуем данные
      UTC = (int)Str_UTC;                        // Преобразуем данные
      if(Instr == "USD")
         {
         InfZL_USD[usd].dateHist = Dat_DtTm;
         InfZL_USD[usd].ZL = UTC;
         usd++;
         }
      else if(Instr == "EUR")
         {
         InfZL_EUR[eur].dateHist = Dat_DtTm;
         InfZL_EUR[eur].ZL = UTC;
         eur++;
         }
      else if(Instr == "RUR")
         {
         InfZL_RUR[rur].dateHist = Dat_DtTm;
         InfZL_RUR[rur].ZL = UTC;
         rur++;
         }      
      else if(Instr == "ALF")
         {
         InfZL_ALF[alf].dateHist = Dat_DtTm;
         InfZL_ALF[alf].ZL = UTC;
         alf++;
         }      
      else if(Instr == "INS")
         {
         InfZL_INS[ins].dateHist = Dat_DtTm;
         InfZL_INS[ins].ZL = UTC;
         ins++;
         }      
      if(FileIsEnding(Handle)==true) break;                    // Если файловый указатель в конце то выход из чтения
      }
   FileClose(Handle);                                          // Закрываем файл
   return;
   }
//*--------------------------------------------------------------------*
//| Выбираем строку из массива для зима лето
//*--------------------------------------------------------------------*
void massiv_zl(datetime time)
   {
   datetime Timm=0;
   for (int i = ArraySize(InfZL_USD) - 1; i >= 0; i--)
      {
      if(InfZL_USD[i].dateHist > 0)
         {
         if(time > InfZL_USD[i].dateHist && InfZL_USD[i].dateHist > Timm)
            {
            Timm = InfZL_USD[i].dateHist;
            Utc_Usd = (int)InfZL_USD[i].ZL;
            }
         }
      }
   Timm = 0;
   for (int i = ArraySize(InfZL_EUR) - 1; i >= 0; i--)
      {
      if(InfZL_EUR[i].dateHist > 0)
         {
         if(time > InfZL_EUR[i].dateHist && InfZL_EUR[i].dateHist > Timm)
            {
            Timm = InfZL_EUR[i].dateHist;
            Utc_Eur = (int)InfZL_EUR[i].ZL;
            }
         }
      }
   Timm = 0;
   for (int i = ArraySize(InfZL_RUR) - 1; i >= 0; i--)
      {
      if(InfZL_RUR[i].dateHist > 0)
         {
         if(time > InfZL_RUR[i].dateHist && InfZL_RUR[i].dateHist > Timm)
            {
            Timm = InfZL_RUR[i].dateHist;
            Utc_Rur = (int)InfZL_RUR[i].ZL;
            }
         }
      }
   Timm = 0;
   for (int i = ArraySize(InfZL_ALF) - 1; i >= 0; i--)
      {
      if(InfZL_ALF[i].dateHist > 0)
         {
         if(time > InfZL_ALF[i].dateHist && InfZL_ALF[i].dateHist > Timm)
            {
            Timm = InfZL_ALF[i].dateHist;
            Utc_Alf = (int)InfZL_ALF[i].ZL;
            }
         }
      }
   Timm = 0;
   for (int i = ArraySize(InfZL_INS) - 1; i >= 0; i--)
      {
      if(InfZL_INS[i].dateHist > 0)
         {
         if(time > InfZL_INS[i].dateHist && InfZL_INS[i].dateHist > Timm)
            {
            Timm = InfZL_INS[i].dateHist;
            Utc_Ins = (int)InfZL_INS[i].ZL;
            }
         }
      }
   return;   
   }
//*--------------------------------------------------------------------
//          Создаем кнопки
//*--------------------------------------------------------------------
void PutButton(string name,int x,int y,string text,int xsize,int ysize, color clr)
  {
   ObjectCreate(0,name,OBJ_BUTTON,0,0,0);

//--- установим координаты кнопки
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
//--- установим размер кнопки
   ObjectSetInteger(0,name,OBJPROP_XSIZE,xsize);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,ysize);
//--- установим угол графика, относительно которого будут определяться координаты точки
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
//--- установим текст
   ObjectSetString(0,name,OBJPROP_TEXT,text);
//--- установим шрифт текста
   ObjectSetString(0,name,OBJPROP_FONT,"Arial");
//--- установим размер шрифта
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,button_fontsize);
   color clr_text = clrBlack;
   if(button_bgcolor_key == true || name == "Отк.EUR" || name == "Зак.EUR" || name == "Отк.USD" || name == "Зак.USD") clr_text = button_color;
//--- установим цвет текста
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr_text);
   if(button_bgcolor_key == true) clr = button_bgcolor;
//--- установим цвет фона
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,clr);
//--- установим цвет границы
   ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,button_bdcolor);
//--- вернем кнопку в ненажатое состояние
   ObjectSetInteger(0,name,OBJPROP_STATE,false);
  return;
  }  

//********************************************************************
// Создадим панель кнопок 
//********************************************************************
void StartPanel()
   {
//   zone_name();
//   zone_zone();
//   HiLow();
//   zone_re();
   int xsize = button_widths;
   int ysize = button_heights;
   ChartTimePriceToXY(0, 0, button_time, button_price, bx, by);
   bx -= button_widths;
   int by1 = by;
   if(button_HiLow > 0)
      {
      PutButton("НКЗ",bx,by,"НКЗ",xsize,ysize,NKZ_color);
      by = by + button_heights + button_y_distances;
      PutButton("3/4",bx,by,"3/4",xsize,ysize,NKZd_colorHi_3);
      by = by + button_heights + button_y_distances;
      PutButton("ДКЗ",bx,by,"ДКЗ",xsize,ysize,NKZd_colorHi);
      by = by + button_heights + button_y_distances;
      PutButton("1/4",bx,by,"1/4",xsize,ysize,NKZd_colorHi_1);
      by = by + button_heights + button_y_distances;
      PutButton(">>>",bx,by,"Маржа",xsize,ysize,button_bgcolor);
      by = by + button_heights + button_y_distances;
      PutButton("Test",bx,by,"АТР",xsize,ysize,button_bgcolor);
      bx -= (button_widths + button_x_distances);
      by = by1;
      PutButton("Отк.EUR",bx,by,"Отк. €",xsize,ysize,A_colorEO);
      by = by + button_heights + button_y_distances;
      PutButton("Зак.EUR",bx,by,"Зак. €",xsize,ysize,A_colorEZ);
      by = by + button_heights + button_y_distances;
      PutButton("Отк.USD",bx,by,"Отк. $",xsize,ysize,A_colorAO);
      by = by + button_heights + button_y_distances;
      PutButton("Зак.USD",bx,by,"Зак. $",xsize,ysize,A_colorAZ);
      by = by + button_heights + button_y_distances;
      PutButton("МКЗ",bx,by,"МКЗ",xsize,ysize,button_bgcolor);
      by = by + button_heights + button_y_distances;
      PutButton("<USD>",bx,by,"Стрелки",xsize,ysize,button_bgcolor);
      by = by + button_heights + button_y_distances;
      PutButton("Х",bx,by,"Х",xsize + button_widths + button_x_distances,ysize,button_bgcolor);
      bx -= (button_x_distances + button_heights);
      xsize = button_heights;
      ysize = (4 * button_heights) + (3 * button_y_distances);
      by = by1;            
      PutButton("V",bx,by,"§",xsize,ysize,button_bgcolor);
      ysize = (2 * button_heights) + button_y_distances;
      by = by + (4 * button_heights) + (4 * button_y_distances);
      PutButton("Web",bx,by,"/",xsize,ysize,button_bgcolor);
      ysize = button_heights;
      by = by + (2 * button_heights) + (2 * button_y_distances);
      PutButton("ATRr",bx,by,"A",xsize,ysize,button_bgcolor);
      }
   else
      {
      by -= button_heights;
      PutButton("Test",bx,by,"АТР",xsize,ysize,button_bgcolor);
      by = by - button_heights - button_y_distances;
      PutButton(">>>",bx,by,"Маржа",xsize,ysize,button_bgcolor);
      by = by - button_heights - button_y_distances;
      PutButton("1/4",bx,by,"1/4",xsize,ysize,NKZd_colorLow_1);
      by = by - button_heights - button_y_distances;
      PutButton("ДКЗ",bx,by,"ДКЗ",xsize,ysize,NKZd_colorLow);
      by = by - button_heights - button_y_distances;
      PutButton("3/4",bx,by,"3/4",xsize,ysize,NKZd_colorLow_3);
      by = by - button_heights - button_y_distances;
      PutButton("НКЗ",bx,by,"НКЗ",xsize,ysize,NKZ_color);
      bx -= (button_widths + button_x_distances);
      by1 = by;
      PutButton("Отк.EUR",bx,by,"Отк. €",xsize,ysize,A_colorEO);
      by = by + button_heights + button_y_distances;
      PutButton("Зак.EUR",bx,by,"Зак. €",xsize,ysize,A_colorEZ);
      by = by + button_heights + button_y_distances;
      PutButton("Отк.USD",bx,by,"Отк. $",xsize,ysize,A_colorAO);
      by = by + button_heights + button_y_distances;
      PutButton("Зак.USD",bx,by,"Зак. $",xsize,ysize,A_colorAZ);
      by = by + button_heights + button_y_distances;
      PutButton("МКЗ",bx,by,"МКЗ",xsize,ysize,button_bgcolor);
      by = by + button_heights + button_y_distances;
      PutButton("<USD>",bx,by,"Стрелки",xsize,ysize,button_bgcolor);
      by = by + button_heights + button_y_distances;
      PutButton("Х",bx,by,"Х",xsize + button_widths + button_x_distances,ysize,button_bgcolor);
      bx -= (button_x_distances + button_heights);
      xsize = button_heights;
      ysize = (4 * button_heights) + (3 * button_y_distances);
      by = by1;            
      PutButton("V",bx,by,"§",xsize,ysize,button_bgcolor);
      ysize = (2 * button_heights) + button_y_distances;
      by = by + (4 * button_heights) + (4 * button_y_distances);
      PutButton("Web",bx,by,"/",xsize,ysize,button_bgcolor);
      ysize = button_heights;
      by = by + (2 * button_heights) + (2 * button_y_distances);
      PutButton("ATRr",bx,by,"A",xsize,ysize,button_bgcolor);
      }
   seee = 0;
   seeeV = 0;
   seeeA = 0;
   }
//********************************************************************
// Удалим панель кнопок 
//********************************************************************
void DeletePanel()
   {
         ObjectDelete("НКЗ");
         ObjectDelete("3/4");
         ObjectDelete("ДКЗ");
         ObjectDelete("1/4");
         ObjectDelete(">>>");
         ObjectDelete("Х");
         ObjectDelete("Отк.EUR");
         ObjectDelete("Зак.EUR");
         ObjectDelete("Отк.USD");
         ObjectDelete("Зак.USD");
         ObjectDelete("МКЗ");
         ObjectDelete("<USD>");
         ObjectDelete("V");
         ObjectDelete("Web");
         ObjectDelete("Test");
         ObjectDelete("ATRr");
   }
//********************************************************************
// Определяем указатель мыши над максимумом или над минимум 
//********************************************************************
void HiLow()
   {
   double price_H, price_L;
   int shift_H, shift_L, shift;
   price_H = price_L = shift_H = shift_L = button_HiLow = NULL;
   shift = iBarShift(NULL, 0, button_time, false);
   shift_L = iLowest(NULL, 0, MODE_LOW, 10 * 2, shift - 10);
   price_L = iLow(NULL, 0, shift_L);
   shift_H = iHighest(NULL, 0, MODE_HIGH, 10 * 2, shift - 10);
   price_H = iHigh(NULL, 0, shift_H);
   if (button_price > price_H) 
      {
      button_price = price_H;                // Цена
      button_time = iTime(NULL, 0, shift_H); // Время
      button_HiLow = 1;                       // Hi
      }
   else if (button_price < price_L)
      {
      button_price = price_L;                // Цена
      button_time = iTime(NULL, 0, shift_L); // Время
      button_HiLow = -1;                      // Low
      }
   else
      {
      Comment("Указатель мыши должен, находиться выше максимума, либо ниже минимума!");
      if (sound) PlaySound(sound_Error);
      return;
      }
            // Подкорректируем время вершинки с младшего таймфрейма
   datetime time2 =  button_time + _Period * 60;
   if(time2 > TimeCurrent()) time2 = TimeCurrent();
   int tm[] = {1, 5, 15, 30, 60, 240, 14400, 10080, 43200};
   for(int i = 0; i < ArraySize(tm); i++)
      {
      shift_L = iBarShift(NULL, tm[i], button_time, true);
      shift_H = iBarShift(NULL, tm[i], time2, true);
      if (shift_L != -1 && shift_H != -1)
         {
         if(button_HiLow == -1)
            button_time = iTime(NULL, tm[i], iLowest(NULL, tm[i], MODE_LOW, shift_L - shift_H, shift_H + 1)); // Время
         else
            button_time = iTime(NULL, tm[i], iHighest(NULL, tm[i], MODE_HIGH, shift_L - shift_H, shift_H + 1)); // Время
         break;
         }
      }
   }

//*--------------------------------------------------------------------*
//| Обновим массив
//*--------------------------------------------------------------------*
void obnovit()
   {
   datetime time1 = TimeCurrent();
      if(NKZZ[InffoKeyy].NKZ != NKZ_NEW[InffoKeyNew].NKZ && InffoKeyNew != -1)               //      if(NKZZ[InffoKeyy].NKZ != NKZ_NEW[InffoKeyNew].NKZ)
         {
         for(int w = 0; w < ArraySize(NKZZ); w++)
            {
            if(NKZZ[w].Instr == NULL)
               {
               NKZZ[w].Instr = NKZZ[InffoKeyy].Instr;
               MqlDateTime date;
               TimeToStruct(time1, date);
               time1 = datetime((string)date.year + "." + (string)date.mon + "." + (string)date.day + " 00:00");
               NKZZ[w].dateHist = time1;              //   NKZZ[w].dateHist = NKZ_NEW[InffoKeyNew].dateHist;
               NKZZ[w].NKZ = NKZ_NEW[InffoKeyNew].NKZ;
               NKZZ[w].cena = NKZZ[InffoKeyy].cena;
               Key = 1;
               if (ZonaAlertMode) AlertInfoAdd(ChartID(), NKZZ[InffoKeyy].Instr + ": Новые маржинальные требования"); // Добавить строку в Alert
               else Alert(_Symbol + ": Новые маржинальные требования");
//Alert(NKZZ[InffoKeyy].NKZ, " - ",NKZ_NEW[InffoKeyNew].NKZ);
               break;
               }
            }
         }
   return;
   }
//*--------------------------------------------------------------------*
//| Выбираем строку из массива для НКЗ
//*--------------------------------------------------------------------*
void massiv(string Symbbol)
   {
   datetime Timm=0;
   for (int i = ArraySize(NKZZ) - 1; i >= 0; i--)
      {
      if(NKZZ[i].Instr == Symbbol)
         {
         if(TimeCurrent() > NKZZ[i].dateHist && NKZZ[i].dateHist > Timm)
            {
            Timm = NKZZ[i].dateHist;
            InffoKeyy = i;
            }
         }
      }
   return;   
   }
//*--------------------------------------------------------------------*
//| Выбираем строку из массива для НКЗ New
//*--------------------------------------------------------------------*
void massiv_new(string Symbbol)
   {
   InffoKeyNew = -1;
   for (int i = ArraySize(NKZ_NEW) - 1; i >= 0; i--)
      {
      if(NKZ_NEW[i].Instr == Symbbol)
         {
         InffoKeyNew = i;
         break;
         }
      }
   return;   
   }
//*--------------------------------------------------------------------*
//| Проверим обновления (сравним два файла и если необходимо то допишем инфу)
//*--------------------------------------------------------------------*
int Update_U()
   {
   string mus[9];
   string musor_povtor = "";
   Key = 0;
      ResetLastError();
      int filehandle = FileOpen("cme.csv",FILE_READ|FILE_CSV,";");
      //--- проверка ошибки
      if(filehandle != INVALID_HANDLE)
         {
         int q = 0;
         while(FileIsEnding(filehandle)==false)
            {
            Comment(_Symbol + " Открыли cme.csv для проверки обновления № " + (string)filehandle);
            for(int i = 0; i < ArraySize(mus); i++)
               {
               mus[i] = FileReadString(filehandle);
               }
//Alert(mus[0],mus[1],mus[3],mus[6]);
            if(mus[0] == "\"NYM\"" && mus[1] == "\"CRUDE OIL\"")
               {
               if((mus[3] == "\"CL\"" && musor_povtor != mus[3]) || (mus[3] == "\"BZ\"" && musor_povtor != mus[3]))
                  {
//Alert(1);
                  musor_povtor = mus[3];
                  kovichki(mus[3]);
                  NKZ_NEW[q].Instr = musor;
                  kovichki(mus[6]);
                  marja_new = NormalizeDouble(StringToDouble(musor),0);
                  NKZ_NEW[q].NKZ = marja_new;
                  q++;
                  }
//               continue;
               }
            else if(mus[0] == "\"CMX\"" && mus[1] == "\"METALS\"")
               {
               if(mus[3] == "\"GC\"" && musor_povtor != mus[3])
                  {
//Alert(2);
                  musor_povtor = mus[3];
                  kovichki(mus[3]);
                  NKZ_NEW[q].Instr = musor;
                  kovichki(mus[6]);
                  marja_new = NormalizeDouble(StringToDouble(musor),0);
                  NKZ_NEW[q].NKZ = marja_new;
                  q++;
                  }
//               continue;
               }
            else if(mus[0] == "\"CME\"" && mus[1] == "\"FX\"")
               {
               if((mus[3] == "\"NE\"" && musor_povtor != mus[3]) || (mus[3] == "\"AD\"" && musor_povtor != mus[3]) || (mus[3] == "\"C1\"" && musor_povtor != mus[3]) || 
               (mus[3] == "\"EC\"" && musor_povtor != mus[3]) || (mus[3] == "\"E1\"" && musor_povtor != mus[3]) || (mus[3] == "\"BP\"" && musor_povtor != mus[3]) ||  
               (mus[3] == "\"J1\"" && musor_povtor != mus[3]) || (mus[3] == "\"CZ\"" && musor_povtor != mus[3]) || (mus[3] == "\"AC\"" && musor_povtor != mus[3]) || 
               (mus[3] == "\"AJ\"" && musor_povtor != mus[3]) || (mus[3] == "\"AN\"" && musor_povtor != mus[3]) || (mus[3] == "\"BF\"" && musor_povtor != mus[3]) || 
               (mus[3] == "\"BR\"" && musor_povtor != mus[3]) || (mus[3] == "\"BY\"" && musor_povtor != mus[3]) || (mus[3] == "\"CA\"" && musor_povtor != mus[3]) || 
               (mus[3] == "\"CN\"" && musor_povtor != mus[3]) ||  (mus[3] == "\"CNH\"" && musor_povtor != mus[3]) || (mus[3] == "\"CY\"" && musor_povtor != mus[3]) || 
               (mus[3] == "\"CC\"" && musor_povtor != mus[3]) || (mus[3] == "\"FR\"" && musor_povtor != mus[3]) || (mus[3] == "\"IS\"" && musor_povtor != mus[3]) || 
               (mus[3] == "\"K\"" && musor_povtor != mus[3]) || (mus[3] == "\"KE\"" && musor_povtor != mus[3]) || (mus[3] == "\"MP\"" && musor_povtor != mus[3]) || 
               (mus[3] == "\"PZ\"" && musor_povtor != mus[3]) || (mus[3] == "\"R\"" && musor_povtor != mus[3]) || (mus[3] == "\"RF\"" && musor_povtor != mus[3]) || 
               (mus[3] == "\"RP\"" && musor_povtor != mus[3]) || (mus[3] == "\"RU\"" && musor_povtor != mus[3]) || (mus[3] == "\"RY\"" && musor_povtor != mus[3]) || 
               (mus[3] == "\"SE\"" && musor_povtor != mus[3]) || (mus[3] == "\"SJ\"" && musor_povtor != mus[3]) || (mus[3] == "\"UN\"" && musor_povtor != mus[3]) || 
               (mus[3] == "\"Z\"" && musor_povtor != mus[3]))
                  {
//Alert(3);
                  musor_povtor = mus[3];
                  kovichki(mus[3]);
                  NKZ_NEW[q].Instr = musor;
                  kovichki(mus[6]);
                  marja_new = NormalizeDouble(StringToDouble(musor),0);
                  NKZ_NEW[q].NKZ = marja_new;
                  q++;
                  }
               }
            if(FileIsEnding(filehandle)==true) break;                    // Если файловый указатель в конце то выход из чтения
            }
         FileClose(filehandle);
         for (int i = 0; i < ArraySize(NKZ_NEW); i++)
            {
            if(NKZ_NEW[i].Instr == NULL) break;
            konek[i] = NKZ_NEW[i].Instr + ";" + TimeToString(NKZ_NEW[i].dateHist) + ";" + DoubleToString(NKZ_NEW[i].NKZ) + "\n";
            }
         ResetLastError();
         filehandle = FileOpen("cmeprov.csv",FILE_WRITE|FILE_CSV);
         //--- проверка ошибки
         if(filehandle != INVALID_HANDLE)
            {
            for (int i = 0; i < ArraySize(konek); i++)
               {
               FileWriteString(filehandle,konek[i]);
               }
            }
         //--- закрываем файл
         FileClose(filehandle);
        }
      else {Comment(_Symbol + " Не открылся cme.csv при проверке обновления № " + (string)GetLastError()); return 1;}
      ResetLastError();
      filehandle=FileOpen("nkz.csv",FILE_READ|FILE_CSV,";");
      //--- проверка ошибки
      if(filehandle != INVALID_HANDLE)
         {
         int q = 0;
         while(FileIsEnding(filehandle)==false)
            {
            musor=FileReadString(filehandle);                            // Считали колонку 1
            NKZZ[q].Instr = musor;
            musor=FileReadString(filehandle);
            dat_dtTm_new = StringToTime(musor);
            NKZZ[q].dateHist = dat_dtTm_new;
            musor=FileReadString(filehandle);
            marja_new = NormalizeDouble(StringToDouble(musor),0);
            NKZZ[q].NKZ = marja_new;
            musor=FileReadString(filehandle);
            cenna = NormalizeDouble(StringToDouble(musor),2);
            NKZZ[q].cena = cenna;
            q++;
            if(FileIsEnding(filehandle)==true) break;                    // Если файловый указатель в конце то выход из чтения
            }
         }
      else {Comment("Не открылся nkz.csv при проверке обновления"); return 1;}
/*
AUDCAD	AC 1
AUDUSD	AD 1
AUDJPY	AJ 1
AUDNZD	AN 1
GBPCHF	BF 1
GBPUSD	BP 1
BRLUSD	BR 0
GBPJPY	BY 1
CADUSD	C1 0
EURAUD	CA 1
EURCAD	СС 1
EURNOK	CN 1
USDCHN	CNH 0
CADJPY	CY 1
CZKUSD	CZ 0
USDCHF	E1 0
EURUSD	EC 1
HUFUSD	FR 0
ILSUSD	IS 1
JPUUSD	J1 0
CZKEUR	K 1
EURSEK	KE 1
MXNUSD	MP 0
NZDUSD	NE 1
PLNUSD	PZ 0
HUFEUR	R 1
EURCHF	RF 1
EURGBP	RP 1
RUBUSD	RU 0
EURJPY	RY 1
SEKUSD	SE 0
CHFJPY	SJ 1
NOKUSD	UN 0
PLNEUR	Z 1
GOLD	   GC          ! 
BRENT	   BZ 1
CL	      CL          !
*/
      massiv("EURCAD");
      massiv_new("CC");
      obnovit();
      massiv("USDPLN");
      massiv_new("PZ");
      obnovit();
      massiv("HUFEUR");
      massiv_new("R");
      obnovit();
      massiv("EURCHF");
      massiv_new("RF");
      obnovit();
      massiv("EURGBP");
      massiv_new("RP");
      obnovit();
      massiv("USDRUR");
      massiv_new("RU");
      obnovit();
      massiv("EURJPY");
      massiv_new("RY");
      obnovit();
      massiv("USDSEK");
      massiv_new("SE");
      obnovit();
      massiv("CHFJPY");
      massiv_new("SJ");
      obnovit();
      massiv("USDNOK");
      massiv_new("UN");
      obnovit();
      massiv("PLNEUR");
      massiv_new("Z");
      obnovit();
      massiv("GOLD");
      massiv_new("GC");
      obnovit();
      massiv("BRENT");
      massiv_new("BZ");
      obnovit();
      massiv("CL");
      massiv_new("CL");
      obnovit();
      massiv("AUDCAD");
      massiv_new("AC");
      obnovit();
      massiv("AUDJPY");
      massiv_new("AJ");
      obnovit();
      massiv("AUDNZD");
      massiv_new("AN");
      obnovit();
      massiv("GBPCHF");
      massiv_new("BF");
      obnovit();
      massiv("USDBRL");
      massiv_new("BR");
      obnovit();
      massiv("GBPJPY");
      massiv_new("BY");
      obnovit();
      massiv("EURAUD");
      massiv_new("CA");
      obnovit();
      massiv("EURNOK");
      massiv_new("CN");
      obnovit();
      massiv("USDCNH");
      massiv_new("CNH");
      obnovit();
      massiv("CADJPY");
      massiv_new("CY");
      obnovit();
      massiv("USDCZK");
      massiv_new("CZ");
      obnovit();
      massiv("USDHUF");
      massiv_new("FR");
      obnovit();
      massiv("USDILS");
      massiv_new("IS");
      obnovit();
      massiv("CZKEUR");
      massiv_new("K");
      obnovit();
      massiv("EURSEK");
      massiv_new("KE");
      obnovit();
      massiv("USDMXN");
      massiv_new("MP");
      obnovit();
      massiv("NZDUSD");
      massiv_new("NE");
      obnovit();
      massiv("AUDUSD");
      massiv_new("AD");
      obnovit();
      massiv("USDCAD");
      massiv_new("C1");
      obnovit();
      massiv("EURUSD");
      massiv_new("EC");
      obnovit();
      massiv("USDCHF");
      massiv_new("E1");
      obnovit();
      massiv("GBPUSD");
      massiv_new("BP");
      obnovit();
      massiv("USDJPY");
      massiv_new("J1");
      obnovit();
      massiv("EURGBP");
      massiv_new("RP");
      obnovit();
      if(Key == 1)
         {
         for (int i = 0; i < ArraySize(NKZZ); i++)
            {
            if(NKZZ[i].Instr == NULL) break;
            konek[i] = NKZZ[i].Instr + ";" + TimeToString(NKZZ[i].dateHist) + ";" + DoubleToString(NKZZ[i].NKZ) + ";" + DoubleToString(NKZZ[i].cena) + "\n";
            }
         ResetLastError();
         int filehandle1 = FileOpen("nkz1.csv",FILE_WRITE|FILE_CSV);
         //--- проверка ошибки
         if(filehandle1 != INVALID_HANDLE)
            {
            for (int i = 0; i < ArraySize(konek); i++)
               {
               FileWriteString(filehandle1,konek[i]);
               }
            }
         //--- закрываем файл
         FileClose(filehandle);
         Key = 0;
         FileClose(filehandle1);
         FileCopy("nkz.csv",0,"nkz_copy.csv",0|FILE_REWRITE);
         FileMove("nkz1.csv",0,"nkz.csv",0|FILE_REWRITE);
         Comment("Новые маржинальные требования");
         return 0;
         }
   AlertInfoAdd(ChartID(), "Обновления Маржи нет.");
   return 0;
   }
//*--------------------------------------------------------------------*
//| Выкинем лишние ковычки
//*--------------------------------------------------------------------*
void kovichki(string rez)
   {
   string schar = "r", rezul; 
   int lenght = StringLen(rez);
   for(int x = 0; x < lenght; x++)
      {
      schar = StringSetChar(schar,0,StringGetChar(rez,x));
      if(schar != "\"") 
         rezul += schar; 
      }
   musor = rezul;
   return;
   }   
//*--------------------------------------------------------------------*
//| Рисуем зоны от кнопок
//*--------------------------------------------------------------------*
void zonki(string knopka, string nam1, string nam2, string nam3, double procent)
   {
   ObjectSetInteger(0,knopka,OBJPROP_STATE,false);
   if (seee == 0 && DeleteByPrefix(nam1 + (string)button_time))
      {
      if (sound) PlaySound(sound_Zona);
      return;
      }
   else if(seee == 1 && DeleteByPrefix(nam2 + (string)button_time))
      {
      if (sound) PlaySound(sound_Zona);
      return;
      }
   else if(seee == 2 && DeleteByPrefix(nam3 + (string)button_time))
      {
      if (sound) PlaySound(sound_Zona);
      return;
      }
   double NKZ;
   if(seee == 2)                       // Готовим данные по АТР 
      {
      if(knopka == "1/4" || knopka == "3/4") return;
      else if(knopka == "ДКЗ") procent = 1;
      else if(knopka == "НКЗ") procent = 2;
      button_zonaUpdateInfo = Testik();

      }
   else
      {      
      massiv(button_time);// Выбор строчки из массива
      if(seee == 1) InffoKey++;
      button_zonaUpdateInfo = InffO[InffoKey].NKZ;             //@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
      if (InffO[InffoKey].NKZ < 0) button_zonaUpdateInfo = MathAbs(MathRound((button_price - 1 / (1 / button_price - InffO[InffoKey].NKZ * button_HiLow)) / Point));  //@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
      NKZ = button_zonaUpdateInfo;
      if (NKZ == 0)
         {
         Comment("Недельная зона не задана!");
         if (sound) PlaySound(sound_Error);
         return;
         }

      }
   NKZ = button_zonaUpdateInfo * procent;
   double price2 = button_price - NKZ * _Point * button_HiLow;
   double price3 = price2 + NKZ * _Point * 0.1 * button_HiLow;  // Вычисляем высоту зоны, 10% во внутрь
   double price4 = price2;                               // Вычисляем высоту зоны, 10% во внутрь
   int NKZd_color = 0;
   string opisanie = "НКЗ ";
   if (knopka == "НКЗ") NKZd_color = NKZ_color;
   else if (knopka == "3/4")
      {opisanie = "3/4 "; if(button_HiLow > 0) NKZd_color = NKZd_colorHi_3; else  NKZd_color = NKZd_colorLow_3;}
   else if (knopka == "ДКЗ")
      {opisanie = "ДКЗ "; if(button_HiLow > 0) NKZd_color = NKZd_colorHi; else  NKZd_color = NKZd_colorLow;}
   else if (knopka == "1/4")
      {opisanie = "1/4 "; if(button_HiLow > 0) NKZd_color = NKZd_colorHi_1; else  NKZd_color = NKZd_colorLow_1;}
   if (seee == 2) {opisanie = "АТР "; NKZd_color = col_ATR;}

   if(seee == 0) 
      DrawZone(nam1, opisanie + (string)procent + " - " + IntegerToString((int)(NKZ)) + "п.", button_time, button_price, button_time + NKZ_angle, price2, price3, price4, (int)(NKZ_length * procent), NKZd_color, NKZ_timeframe, button_zonaUpdateInfo);
   else if(seee == 1)
      DrawZone(nam2, opisanie + (string)procent + " - " + IntegerToString((int)(NKZ)) + "п.", button_time, button_price, button_time + NKZ_angle, price2, price3, price4, (int)(NKZ_length * procent), NKZd_color, NKZ_timeframe, button_zonaUpdateInfo);
   else if(seee == 2)
      DrawZone(nam3, opisanie + (string)procent + " - " + IntegerToString((int)(NKZ)) + "п.", button_time, button_price, button_time + NKZ_angle, price2, price3, price4, (int)(NKZ_length * procent), NKZd_color, NKZ_timeframe, button_zonaUpdateInfo);
   return;
   }
//*--------------------------------------------------------------------*
//| Открытие и закрытие Америки и Европы
//*--------------------------------------------------------------------*
void open_close(string knopka, string nam1, color coler)
   {

         ObjectSetInteger(0,knopka,OBJPROP_STATE,false);
         massiv_zl(button_time);
         if (DeleteByPrefix(nam1 + (string)TimeDayOfYear(button_time)))
            {
            if (sound) PlaySound(sound_Zona);
            return;
            }
         string name, OZA_OZE;
         double price1, Utc_Utc;
         datetime time1, time2;
         if(knopka == "Отк.EUR") OZA_OZE = Open_EUR;
         else if(knopka == "Зак.EUR") OZA_OZE = Close_EUR;
         else if(knopka == "Отк.USD") OZA_OZE = Open_USD;
         else if(knopka == "Зак.USD") OZA_OZE = Close_USD;
         if(knopka == "Зак.EUR" || knopka == "Отк.EUR") Utc_Utc = Utc_Eur;                   // price1 = iClose(NULL, 0, shift);
         else Utc_Utc = Utc_Usd;
         MqlDateTime date;
         datetime TimeUSD = (datetime)(StringToTime(OZA_OZE) - (Utc_Utc*3600));
         if(TerminalTime == "RUR")
            {
            TimeUSD += ((Utc_Rur+delta)*3600);
            }
         else if(TerminalTime == "EUR")
            {
            TimeUSD += ((Utc_Eur+delta)*3600);
            }
         else if(TerminalTime == "USD")
            {
            TimeUSD += ((Utc_Usd+delta)*3600);
            }
         else if(TerminalTime == "GMT")
            {
            TimeUSD += ((delta)*3600);
            }
         else if(TerminalTime == "ALF")
            {
            TimeUSD += ((Utc_Alf+delta)*3600);
            }
         else if(TerminalTime == "INS")
            {
            TimeUSD += ((Utc_Ins+delta)*3600);
            }
         time1 = button_time;
         TimeToStruct(time1, date);
         if(TimeDayOfYear(TimeUSD) - TimeDayOfYear(StringToTime(OZA_OZE)) >= 1) time1 = datetime((string)date.year + "." + (string)date.mon + "." + (string)(date.day + 1) + " "+ (string)TimeUSD);
         else time1 = datetime((string)date.year + "." + (string)date.mon + "." + (string)date.day + " "+ (string)TimeUSD);
         time2 = time1 + A_length2;
         int shift = iBarShift(NULL, 0, time1, true);
         if(knopka == "Зак.EUR" || knopka == "Зак.USD") price1 = iClose(NULL, 0, shift);                   // price1 = iClose(NULL, 0, shift);
         else price1 = iOpen(NULL, 0, shift);
         // Подкорректируем цену с младшего таймфрэйма
         int tm[] = {1, 5, 15, 30, 60, 240, 14400, 10080, 43200};
         for (int i = 0; i < ArraySize(tm) && tm[i] <= _Period; i++)
            {
            if ((shift = iBarShift(NULL, tm[i], time1, true)) != -1)
               {
               if(knopka == "Зак.EUR" || knopka == "Зак.USD") price1 = iClose(NULL, tm[i], shift);                     // price1 = iClose(NULL, tm[i], shift);
               else price1 = iOpen(NULL, tm[i], shift);
               break;
               }
            }
         name = nam1 + (string)TimeDayOfYear(button_time);
         time2 = correctWeekend(button_time, time2);
         ObjectCreate(name, OBJ_TREND, 0, 0, 0, 0, 0);
         ObjectSet(name, OBJPROP_TIME1, time1);
         ObjectSet(name, OBJPROP_PRICE1, price1);
         ObjectSet(name, OBJPROP_TIME2, time2);
         ObjectSet(name, OBJPROP_PRICE2, price1);
         ObjectSet(name, OBJPROP_TIMEFRAMES, A_timeframe); // Таймфрейм для отображения
         ObjectSet(name, OBJPROP_WIDTH, A_width1);         // Толщина
         ObjectSet(name, OBJPROP_STYLE, A_style1);         // Стиль
         ObjectSet(name, OBJPROP_COLOR, coler);         // Цвет
         ObjectSet(name, OBJPROP_BACK, true);              // Рисовать объект в фоне
         ObjectSet(name, OBJPROP_SELECTED, false);         // Снять выделение с объекта
         //ObjectSet(name, OBJPROP_SELECTABLE, false);     // Запрет на редактирование
         ObjectSet(name, OBJPROP_RAY, false);              // Рисовать не луч
         return;
   }
//*--------------------------------------------------------------------*
//| Узнаем свежесть промежуточного файла обновления
//*--------------------------------------------------------------------*
void info_file()
   {
   ResetLastError();
   if((l=FileGetInteger("cme.csv",FILE_MODIFY_DATE,false)) == -1) 
      Alert("Error, Code = ", GetLastError());
   return;
   }
//*--------------------------------------------------------------------*
//| Запустим скрипт обновления
//*--------------------------------------------------------------------*
void webb()
   {
   string Sumbbol;
   if (ZonaAlertMode) AlertInfoAdd(ChartID(), " Проверяем сайт СМЕ! "); // Добавить строку в Alert
   else Alert(" Проверяем сайт СМЕ! ");
   char buf[];
   StringToCharArray(MT4_MESSAGE,buf);
   int MT4InternalMsg = RegisterWindowMessageA(buf);
   StringToCharArray(TA_SCRIPT_NAME,buf);
   int hwnd = WindowHandle(_Symbol,PERIOD_CURRENT);
   if(hwnd == 0)
      {
      if (ZonaAlertMode) AlertInfoAdd(ChartID(), _Symbol + ": СМЕ не проверен!"); // Добавить строку в Alert
      else Alert(_Symbol + ": СМЕ не проверен!");
      return;
      }
   SendMessageA(hwnd, MT4InternalMsg, 16,buf);
   return;
   }

//*--------------------------------------------------------------------*
//| Ганн
//*--------------------------------------------------------------------*
void gann()
   {
   Comment("Ганн!");
   datetime time2 = correctWeekend(button_time, button_time + Gann_length);
   datetime timm = button_time;
   static int i = 0;
//   int d = TimeDayOfYear(button_time);
   string name = "Gann_" + (string)button_time;
   if (Period() == PERIOD_W1 || Period() == PERIOD_MN1) {i = 0; Comment("На периоде W1 и MN1 не строим!"); return;}
   if (i == 1)
      {
      i = 0;
      ObjectDelete(name);
      }
   else
      {
//               double scale = NormalizeDouble((((iHigh(NULL,PERIOD_D1,d)-iLow(NULL,PERIOD_D1,d))/Point)/100)/Gann_k,2);
      double periodXX = 0;
      int svech = 0;
      string perr = "";
      switch(_Period)
         {
            case PERIOD_M1  : periodXX = 60; svech = 1440; perr = "M1"; break;
            case PERIOD_M5  : periodXX = 12; svech = 288; perr = "M5"; break;
            case PERIOD_M15 : periodXX = 4; svech = 96; perr = "M15"; break;
            case PERIOD_M30 : periodXX = 2; svech = 48; perr = "M30"; break;
            case PERIOD_H1  : periodXX = 1; svech = 24; perr = "H1"; break;
            case PERIOD_H4  : periodXX = 0.25; svech = 6; perr = "H4"; break;
            case PERIOD_D1  : periodXX = 0.0416667; svech = 1; perr = "D1"; break;
         }
      MqlDateTime date;
      TimeToStruct(timm, date);
      timm = datetime((string)date.year + "." + (string)date.mon + "." + (string)(date.day) + " 00:00:00");
      int Sizz = iBarShift(NULL,PERIOD_CURRENT,timm,true) - svech;
      double scale = NormalizeDouble((((iHigh(NULL,PERIOD_CURRENT,iHighest(NULL,PERIOD_CURRENT,MODE_HIGH,svech,Sizz))-iLow(NULL,PERIOD_CURRENT,iLowest(NULL,PERIOD_CURRENT,MODE_LOW,svech,Sizz)))/Point)/100)/periodXX*Gann_k,2);
      button_HiLow *= -1;
      if (!Gann_change) name += (string)(Gann_Scale[i] * button_HiLow);
      ObjectDelete(name);
      ObjectCreate(0, name, OBJ_GANNLINE, 0, button_time, button_price, time2, 0);
      ObjectSetDouble(0, name, OBJPROP_SCALE, scale * button_HiLow);
      ObjectSetText(name, perr + " " + (string)(DoubleToStr(scale * button_HiLow,1)));
      ObjectSet(name, OBJPROP_TIMEFRAMES, Gann_timeframe); // Таймфрейм для отображения
      ObjectSet(name, OBJPROP_WIDTH, Gann_width);          // Толщина
      ObjectSet(name, OBJPROP_STYLE, Gann_style);          // Стиль
      ObjectSet(name, OBJPROP_COLOR, Gann_color);          // Цвет
      i++;
      }
   if (sound) PlaySound(sound_Zona);
   return;
   }
//*--------------------------------------------------------------------*
//| Для редактирования и создания зоны от зоны
//*--------------------------------------------------------------------*
void zone_zone()
   {
   string name = button_name;
   if (button_zonaUpdate)
      {
      if (ObjectGet(name, OBJPROP_SELECTED) || ObjectGet(StringSubstr(name, 0, 24), OBJPROP_SELECTED))
            {
               button_price = ObjectGet(StringSubstr(name, 0, 24), OBJPROP_PRICE1);
               button_time = datetime(StringSubstr(name, 5, 19));
               button_zonaUpdateInfo = StringToDouble(StringSubstr(name, 27, 0));
               if (StringSubstr(name, 25, 1) == "H") button_HiLow = 1;
               if (StringSubstr(name, 25, 1) == "L") button_HiLow = -1;
               
               if (!button_HiLow || !button_price || !button_zonaUpdateInfo)
               {
                  Comment("Не получается! Наверное зона построена старой версией индикатора");
                  if (sound) PlaySound(sound_Error);
                  return;
               }                  
            }
            else
            {
               int x, y;
               ChartTimePriceToXY(0, 0, (datetime)ObjectGet(name, OBJPROP_TIME2), ObjectGet(name, OBJPROP_PRICE2), x, y);
               if (MathAbs(x - MouseX) < 30)
               {
                  if (ObjectGet(StringSubstr(name, 0, 24), OBJPROP_PRICE1) > button_price) 
                  {
                     button_HiLow = 1;
                     button_price = ObjectGet(name, OBJPROP_PRICE2);
                     if(NKZ_verch == false) button_price = ObjectGet(name, OBJPROP_PRICE1);
                  }
                  else
                  {
                     button_HiLow = -1;
                     button_price = ObjectGet(name, OBJPROP_PRICE1);
                     if(NKZ_verch == false) button_price = ObjectGet(name, OBJPROP_PRICE2);
                  }
                  button_time = (datetime)ObjectGet(name, OBJPROP_TIME2);
                  button_zonaUpdate = 5;
               }
               else
                  button_zonaUpdate = 0;
            }
         }
      else 
         button_zonaUpdate = 0;
      return;
   }
//*--------------------------------------------------------------------*
//| Попробуем найти зону и взять из нее данные, вдруг это повторное создание зоны с вершинки
//*--------------------------------------------------------------------*
void zone_re()
   {
   string name = button_name;
   if (button_zonaUpdate == 4) button_zonaUpdate = 0;
   for (int i = ObjectsTotal() - 1; i >= 0; i--)
         {
            if (ObjectType(name = ObjectName(i)) == OBJ_RECTANGLE)
            {
               if (button_lparam == HotKey1)
               {
                  if (StringFind(name, "DKZ__" + TimeToString(button_time), 0) == 0)
                  {
                     button_zonaUpdateInfo = StrToDouble(StringSubstr(name, 27, 0));
                     break;
                  }
               }
               else if (button_lparam == HotKey3)
               {
                  if (StringFind(name, "NKZ__" + TimeToString(button_time), 0) == 0)
                  {
                     button_zonaUpdateInfo = StrToDouble(StringSubstr(name, 27, 0));
                     break;
                  }
               }
               else if (button_lparam == HotKey2 || button_lparam == HotKey36)
               {
                  if (StringSubstr(name, 0, 3) == "NKZ" && StringSubstr(name, 5, 16) == TimeToString(button_time) && StringSubstr(name, 3, 1) != "_")
                  {
                     button_zonaUpdateInfo = StrToDouble(StringSubstr(name, 27, 0));
                     break;
                  }                  
               }
            }
         }         
   return;
   }
//*--------------------------------------------------------------------*
//| Узнаем имя зоны под мышкой
//*--------------------------------------------------------------------*
void zone_name()
   {
   if (InfoKey == -1 && button_lparam != HotKey11 && button_lparam != HotKey10)
      {
            Comment("Нет информации по инструменту в настройках индикатора!");
            if (sound) PlaySound(sound_Error);
            return;
      }
         
         // Проверим на обновление зоны когда указатель на редактируемой зоне
   string name;
   int zonaUpdate = 0;
   double zonaUpdateInfo = 0;
   name = ZoneUnderCursor(button_time, button_price);
   if (name != "")
      {
      if (StringSubstr(name, 0, 4) == "DKZ_") zonaUpdate = 1;
      if (StringSubstr(name, 0, 5) == "NKZ0_") zonaUpdate = 2;
      if (StringSubstr(name, 0, 5) == "NKZ1_") zonaUpdate = 2;
      if (StringSubstr(name, 0, 5) == "NKZ2_") zonaUpdate = 2;
      if (StringSubstr(name, 0, 5) == "NKZ__") zonaUpdate = 3;
      if (StringSubstr(name, 0, 5) == "NKZN_") zonaUpdate = 4; 
      if (StringSubstr(name, 0, 5) == "NKZn_") zonaUpdate = 4; 
      if (StringSubstr(name, 0, 5) == "NKZT_") zonaUpdate = 4; 
      if (StringSubstr(name, 0, 5) == "NKZt_") zonaUpdate = 4; 
      if (StringSubstr(name, 0, 5) == "NKZD_") zonaUpdate = 4; 
      if (StringSubstr(name, 0, 5) == "NKZd_") zonaUpdate = 4; 
      if (StringSubstr(name, 0, 5) == "NKZC_") zonaUpdate = 4; 
      if (StringSubstr(name, 0, 5) == "NKZc_") zonaUpdate = 4; 
      if (StringSubstr(name, 0, 5) == "NKZb_") zonaUpdate = 4; 
      if (StringSubstr(name, 0, 5) == "NKZa_") zonaUpdate = 4; 
      }
   button_name = name;
   button_zonaUpdate = zonaUpdate;
   button_zonaUpdateInfo = zonaUpdateInfo;
   return;
   }
//*--------------------------------------------------------------------*
//| Перед стартом панели соберем данные
//*--------------------------------------------------------------------*
void SborDannix()
   {
   HiLow();
   StartPanel();
   return;
   }
//*--------------------------------------------------------------------*
//| Расчет волотильности для МКЗ
//*--------------------------------------------------------------------*
void Vol_MKZ()
   {
   int summ = 0, mkz_clr = 0, zon = vol_kol_zon - 1, period = vol_period;
   datetime time1, time2;
   double price1, price2, zone_visota = vol_zone_visota;
   string name, descr;
   if(!vol_atr)
      {
      if(vol_mkz_atr)
         {
         period = vol_period_test;
         zone_visota = vol_zone_visota_test;
         }
      for(int i = zon; i >= 0; i--)
         {
         int z = i, x = vol_kol_period + i;
         summ = 0;
         for(int y = ++z; y <= x; y++) 
            {
            summ += (int)((iHigh(NULL, period, y) - iLow(NULL, period, y)) / _Point);
            }
         vol_atr = summ / vol_kol_period;
         time1 = iTime(NULL,period,i);
         vol_time = time1;
         z = i;
         if(z)time2 = iTime(NULL,period,--z);
         else time2 = time1 + (DaysInMonth(time1) * 86400);                           
         // H
         if(vol_mkz_atr)
            {
            price1 = iOpen(NULL, period, i) + vol_atr * _Point;            
            name = "ATR__" + (string)time1 + "_H";
            }
         else
            {
            price1 = iLow(NULL, period, i) + vol_atr * _Point;
            name = "MKZ__" + (string)time1 + "_H";
            }
         price2 = price1 + (zone_visota * _Point);
         descr = (string)vol_atr;
         if(price1 > iHigh(NULL, period, i)) mkz_clr = vol_col_net;
         else mkz_clr = vol_col_H;
         Zoni_MKZ(name, descr, time1, price1, time2, price2, mkz_clr);
         // L
         if(vol_mkz_atr)
            {
            price1 = iOpen(NULL, period, i) - vol_atr * _Point;            
            name = "ATR__" + (string)time1 + "_L";
            }
         else
            {
            price1 = iHigh(NULL, period, i) - vol_atr * _Point;
            name = "MKZ__" + (string)time1 + "_L";
            }
         price2 = price1 - (zone_visota * _Point);
         descr = (string)vol_atr;
         if(price1 < iLow(NULL, period, i)) mkz_clr = vol_col_net;
         else mkz_clr = vol_col_L;
         Zoni_MKZ(name, descr, time1, price1, time2, price2, mkz_clr);
         if(vol_mkz_atr)
            {
            // H
            price1 = iOpen(NULL, period, i) + vol_atr * _Point*vol_zone_proc;            
            name = "ATRm_" + (string)time1 + "_H";
            price2 = price1 + (zone_visota * _Point);
            descr = (string)(vol_atr*vol_zone_proc);
            if(price1 > iHigh(NULL, period, i)) mkz_clr = vol_col_net;
            else mkz_clr = vol_col_H;
            Zoni_MKZ(name, descr, time1, price1, time2, price2, mkz_clr);
            // L
            price1 = iOpen(NULL, period, i) - vol_atr * _Point*vol_zone_proc;            
            name = "ATRm_" + (string)time1 + "_L";
            price2 = price1 - (zone_visota * _Point);
            descr = (string)(vol_atr*vol_zone_proc);
            if(price1 < iLow(NULL, period, i)) mkz_clr = vol_col_net;
            else mkz_clr = vol_col_L;
            Zoni_MKZ(name, descr, time1, price1, time2, price2, mkz_clr);
            // Линия баланса
            name = "ATRB_" + (string)time1;
            price1 = iOpen(NULL, period, i);
            ObjectCreate(name, OBJ_TREND, 0, 0, 0, 0, 0);
            ObjectSet(name, OBJPROP_TIME1, time1);
            ObjectSet(name, OBJPROP_PRICE1, price1);
            ObjectSet(name, OBJPROP_TIME2, time2);
            ObjectSet(name, OBJPROP_PRICE2, price1);
            ObjectSet(name, OBJPROP_TIMEFRAMES, A_timeframe); // Таймфрейм для отображения
            ObjectSet(name, OBJPROP_WIDTH, 0);         // Толщина
            ObjectSet(name, OBJPROP_STYLE, vol_baza_styl);         // Стиль
            ObjectSet(name, OBJPROP_COLOR, clrBlack);         // Цвет
            ObjectSet(name, OBJPROP_BACK, true);              // Рисовать объект в фоне
            ObjectSet(name, OBJPROP_SELECTED, false);         // Снять выделение с объекта
            //ObjectSet(name, OBJPROP_SELECTABLE, false);     // Запрет на редактирование
            ObjectSet(name, OBJPROP_RAY, false);              // Рисовать не луч
            }
         }
      if(vol_mkz_atr) vol_key = vol_atr = vol_mkz_atr = 0; else vol_key = 1;
      }
   else
      {
      if(vol_time == iTime(NULL,vol_period,0))
         {
         time1 = iTime(NULL,vol_period,0);
         time2 = time1 + (DaysInMonth(time1) * 86400);
//         MqlDateTime date;
//         TimeToStruct(time1, date);
//         time2 = datetime((string)date.year + "." + (string)(date.mon + 1) + "." + (string)date.day + " "+ (string)date.hour +":"+(string)date.min);         
//         time2 = TimeCurrent();                           
         // H
         price1 = iLow(NULL, vol_period, 0) + vol_atr * _Point;
         price2 = price1 + (vol_zone_visota * _Point);
         name = "MKZ__" + (string)time1 + "_H";
         descr = (string)vol_atr;
         if(price1 > iHigh(NULL, vol_period, 0)) mkz_clr = vol_col_net;
         else mkz_clr = vol_col_H;
         Zoni_MKZ(name, descr, time1, price1, time2, price2, mkz_clr);
         // L
         price1 = iHigh(NULL, vol_period, 0) - vol_atr * _Point;
         price2 = price1 - (vol_zone_visota * _Point);
         name = "MKZ__" + (string)time1 + "_L";
         descr = (string)vol_atr;
         if(price1 < iLow(NULL, vol_period, 0)) mkz_clr = vol_col_net;
         else mkz_clr = vol_col_L;
         Zoni_MKZ(name, descr, time1, price1, time2, price2, mkz_clr);
         }
      else
         {
         vol_atr = 0;
         }
      }
   WindowRedraw();
   return;
   }          
//*--------------------------------------------------------------------*
//| Рисуем зоны для МКЗ
//*--------------------------------------------------------------------*
void Zoni_MKZ(string name, string descr, datetime time1, double price1, datetime time2, double price2, int clr)
   {
   // Рисуем зону
   bool cr = ObjectCreate(name, OBJ_RECTANGLE, 0, 0, 0, 0, 0);
   ObjectSet(name, OBJPROP_TIME1, time1);
   ObjectSet(name, OBJPROP_PRICE1, price1);
   ObjectSet(name, OBJPROP_TIME2, time2); 
   ObjectSet(name, OBJPROP_PRICE2, price2);
   ObjectSetText(name, descr);                           // Описание
   ObjectSet(name, OBJPROP_STYLE, vol_line_stil);          // Цвет
   ObjectSet(name, OBJPROP_WIDTH, vol_line_tol);          // Цвет
   ObjectSet(name, OBJPROP_COLOR, clr);          // Цвет
   ObjectSet(name, OBJPROP_TIMEFRAMES, vol_timeframe);       // Таймфрейм для отображения
   ObjectSet(name, OBJPROP_SELECTED, false);             // Снять выделение с объекта
   ObjectSet(name, OBJPROP_BACK, vol_zalivka);                  // Рисовать объект в фоне
   return;
   }
//*--------------------------------------------------------------------*
//| Рисуем уровни
//*--------------------------------------------------------------------*
void Op_Cl_E_A(string knopka, string nam1, color coler)
   {
   ObjectSetInteger(0,knopka,OBJPROP_STATE,false);
   if (DeleteByPrefix(nam1))
      {
      if(nam1 == "EURO_") {seeeOE = 0; seeeOE_time = 0; seeeOE_price = 0;}
      else if(nam1 == "EUR__") {seeeZE = 0; seeeZE_time = 0; seeeZE_price = 0;}
      else if(nam1 == "USDO_") {seeeOA = 0; seeeOU_time = 0; seeeOU_price = 0;}
      else if(nam1 == "USD__") {seeeZA = 0; seeeZU_time = 0; seeeZU_price = 0;}
      seeeKEY = 0;
      if (sound) PlaySound(sound_Zona);
      return;
      }
   datetime time5;
   for(int i = 0; i < ObjectsTotal(); i++)
      {
      DeleteByPrefix("Buy_");
      DeleteByPrefix("Sel_");
      }
   for(int ii = AO_count; ii > 0; ii--)
      {
      time5 = iTime(NULL, PERIOD_D1, ii);
      if(iBarShift(NULL, PERIOD_M30, time5, true) >= 0 || iBarShift(NULL, PERIOD_M30, (datetime)time5 + 3600, true) >= 0)
         {
         massiv_zl(time5);
         string name, OZA_OZE;
         double price1, Utc_Utc;
         datetime time1, time2;
         if(knopka == "Отк.EUR") OZA_OZE = Open_EUR;
         else if(knopka == "Зак.EUR") OZA_OZE = Close_EUR;
         else if(knopka == "Отк.USD") OZA_OZE = Open_USD;
         else if(knopka == "Зак.USD") OZA_OZE = Close_USD;
         if(knopka == "Зак.EUR" || knopka == "Отк.EUR") Utc_Utc = Utc_Eur;                   // price1 = iClose(NULL, 0, shift);
         else Utc_Utc = Utc_Usd;
         MqlDateTime date;
         datetime TimeUSD = (datetime)(StringToTime(OZA_OZE) - (Utc_Utc*3600));
         if(TerminalTime == "RUR")
            {
            TimeUSD += ((Utc_Rur+delta)*3600);
            }
         else if(TerminalTime == "EUR")
            {
            TimeUSD += ((Utc_Eur+delta)*3600);
            }
         else if(TerminalTime == "USD")
            {
            TimeUSD += ((Utc_Usd+delta)*3600);
            }
         else if(TerminalTime == "GMT")
            {
            TimeUSD += ((delta)*3600);
            }
         else if(TerminalTime == "ALF")
            {
            TimeUSD += ((Utc_Alf+delta)*3600);
            }
         else if(TerminalTime == "INS")
            {
            TimeUSD += ((Utc_Ins+delta)*3600);
            }
         time1 = time5;
         TimeToStruct(time1, date);
         if(TimeDayOfYear(TimeUSD) - TimeDayOfYear(StringToTime(OZA_OZE)) >= 1) time1 = datetime((string)date.year + "." + (string)date.mon + "." + (string)(date.day + 1) + " "+ (string)TimeUSD);
         else time1 = datetime((string)date.year + "." + (string)date.mon + "." + (string)date.day + " "+ (string)TimeUSD);
         time2 = time1 + A_length2;
         int shift = iBarShift(NULL, 0, time1, true);
         if(knopka == "Зак.EUR" || knopka == "Зак.USD") price1 = iClose(NULL, 0, shift);                   // price1 = iClose(NULL, 0, shift);
         else price1 = iOpen(NULL, 0, shift);
         // Подкорректируем цену с младшего таймфрэйма
         int tm[] = {1, 5, 15, 30, 60, 240, 14400, 10080, 43200};
         for (int i = 0; i < ArraySize(tm) && tm[i] <= _Period; i++)
            {
            if ((shift = iBarShift(NULL, tm[i], time1, true)) != -1)
               {
               if(knopka == "Зак.EUR" || knopka == "Зак.USD") price1 = iClose(NULL, tm[i], shift);                     // price1 = iClose(NULL, tm[i], shift);
               else price1 = iOpen(NULL, tm[i], shift);
               break;
               }
            }
         name = nam1 + (string)time1;
         time2 = correctWeekend(time1, time2);
         ObjectCreate(name, OBJ_TREND, 0, 0, 0, 0, 0);
         ObjectSet(name, OBJPROP_TIME1, time1);
         ObjectSet(name, OBJPROP_PRICE1, price1);
         ObjectSet(name, OBJPROP_TIME2, time2);
         ObjectSet(name, OBJPROP_PRICE2, price1);
         ObjectSet(name, OBJPROP_TIMEFRAMES, A_timeframe); // Таймфрейм для отображения
         ObjectSet(name, OBJPROP_WIDTH, A_width1);         // Толщина
         ObjectSet(name, OBJPROP_STYLE, A_style1);         // Стиль
         ObjectSet(name, OBJPROP_COLOR, coler);         // Цвет
         ObjectSet(name, OBJPROP_BACK, true);              // Рисовать объект в фоне
         ObjectSet(name, OBJPROP_SELECTED, false);         // Снять выделение с объекта
         //ObjectSet(name, OBJPROP_SELECTABLE, false);     // Запрет на редактирование
         ObjectSet(name, OBJPROP_RAY, false);              // Рисовать не луч

         // Стрелочки на истории
         if(strelochki == true)
            {
            string nan1 = "", nan2 = "", nan3 = ""; 
            if(nam1 == "EURO_")
               {
               if(A_0_25_OE == true) nan1 = "NKZC_";
               if(A_0_50_OE == true) nan2 = "NKZD_";
               if(A_1_00_OE == true) nan3 = "NKZN_";
               Strel_Hist(nan1, nan2, nan3, time1, price1);
               }
            else if(nam1 == "EUR__")
               {
               if(A_0_25_ZE == true) nan1 = "NKZC_";
               if(A_0_50_ZE == true) nan2 = "NKZD_";
               if(A_1_00_ZE == true) nan3 = "NKZN_";
               Strel_Hist(nan1, nan2, nan3, time1, price1);
               }
            else if(nam1 == "USDO_")
               {
               if(A_0_25_OU == true) nan1 = "NKZC_";
               if(A_0_50_OU == true) nan2 = "NKZD_";
               if(A_1_00_OU == true) nan3 = "NKZN_";
               Strel_Hist(nan1, nan2, nan3, time1, price1);
               }
            else if(nam1 == "USD__")
               {
               if(A_0_25_ZU == true) nan1 = "NKZC_";
               if(A_0_50_ZU == true) nan2 = "NKZD_";
               if(A_1_00_ZU == true) nan3 = "NKZN_";
               Strel_Hist(nan1, nan2, nan3, time1, price1);
               }
            }
         }
      }
   seeeKEY = 1;
   return;
   }
//*--------------------------------------------------------------------*
//| Рисуем уровни на сегодняшнем дне
//*--------------------------------------------------------------------*
void Op_Cl_E_A_Seg()
   {
   datetime time5 = iTime(NULL, PERIOD_D1, 0);
//   if(!seeeKEY) massiv_zl(time5);
   massiv_zl(time5);
   string OZA_OZE;
   double Utc_Utc;
   if(seeeOE) 
      {
      OZA_OZE = Open_EUR; 
      Utc_Utc = Utc_Eur;
      Line_A_E(time5,OZA_OZE,Utc_Utc, "EURO_",A_colorEO);
      }
   if(seeeZE) 
      {
      OZA_OZE = Close_EUR; 
      Utc_Utc = Utc_Eur;
      Line_A_E(time5,OZA_OZE,Utc_Utc, "EUR__",A_colorEZ);
      }
   if(seeeOA) 
      {
      OZA_OZE = Open_USD; 
      Utc_Utc = Utc_Usd;
      Line_A_E(time5,OZA_OZE,Utc_Utc, "USDO_",A_colorAO);
      }
   if(seeeZA) 
      {
      OZA_OZE = Close_USD; 
      Utc_Utc = Utc_Usd;
      Line_A_E(time5,OZA_OZE,Utc_Utc, "USD__",A_colorAZ);
      }
      if(!A_25_OE_key && A_0_25_OE == true && seeeOE_time > 0 && seeeOE_price > 0) A_25_OE_key = Gde_Zona("NKZC_", seeeOE_time, seeeOE_price);
      if(!A_25_ZE_key && A_0_25_ZE == true && seeeZE_time > 0 && seeeZE_price > 0) A_25_ZE_key = Gde_Zona("NKZC_", seeeZE_time, seeeZE_price);
      if(!A_25_OU_key && A_0_25_OU == true && seeeOU_time > 0 && seeeOU_price > 0) A_25_OU_key = Gde_Zona("NKZC_", seeeOU_time, seeeOU_price);
      if(!A_25_ZU_key && A_0_25_ZU == true && seeeZU_time > 0 && seeeZU_price > 0) A_25_ZU_key = Gde_Zona("NKZC_", seeeZU_time, seeeZU_price);
      if(!A_50_OE_key && A_0_50_OE == true && seeeOE_time > 0 && seeeOE_price > 0) A_50_OE_key = Gde_Zona("NKZD_", seeeOE_time, seeeOE_price);
      if(!A_50_ZE_key && A_0_50_ZE == true && seeeZE_time > 0 && seeeZE_price > 0) A_50_ZE_key = Gde_Zona("NKZD_", seeeZE_time, seeeZE_price);
      if(!A_50_OU_key && A_0_50_OU == true && seeeOU_time > 0 && seeeOU_price > 0) A_50_OU_key = Gde_Zona("NKZD_", seeeOU_time, seeeOU_price);
      if(!A_50_ZU_key && A_0_50_ZU == true && seeeZU_time > 0 && seeeZU_price > 0) A_50_ZU_key = Gde_Zona("NKZD_", seeeZU_time, seeeZU_price);
      if(!A_10_OE_key && A_1_00_OE == true && seeeOE_time > 0 && seeeOE_price > 0) A_10_OE_key = Gde_Zona("NKZN_", seeeOE_time, seeeOE_price);
      if(!A_10_ZE_key && A_1_00_ZE == true && seeeZE_time > 0 && seeeZE_price > 0) A_10_ZE_key = Gde_Zona("NKZN_", seeeZE_time, seeeZE_price);
      if(!A_10_OU_key && A_1_00_OU == true && seeeOU_time > 0 && seeeOU_price > 0) A_10_OU_key = Gde_Zona("NKZN_", seeeOU_time, seeeOU_price);
      if(!A_10_ZU_key && A_1_00_ZU == true && seeeZU_time > 0 && seeeZU_price > 0) A_10_ZU_key = Gde_Zona("NKZN_", seeeZU_time, seeeZU_price);
   return;
   }
//*--------------------------------------------------------------------*
//| Рисуем  линии для Америк И Европ
//*--------------------------------------------------------------------*
void Line_A_E(datetime time5, string OZA_OZE, double Utc_Utc,string nam1, color coler)
   {
   string name;
   double price1;
   datetime time1, time2;
   MqlDateTime date;
   datetime TimeUSD = (datetime)(StringToTime(OZA_OZE) - (Utc_Utc*3600));
   if(TerminalTime == "RUR")
      {
      TimeUSD += ((Utc_Rur+delta)*3600);
      }
   else if(TerminalTime == "EUR")
      {
      TimeUSD += ((Utc_Eur+delta)*3600);
      }
   else if(TerminalTime == "USD")
      {
      TimeUSD += ((Utc_Usd+delta)*3600);
      }
   else if(TerminalTime == "GMT")
      {
      TimeUSD += ((delta)*3600);
      }
   else if(TerminalTime == "ALF")
      {
      TimeUSD += ((Utc_Alf+delta)*3600);
      }
   else if(TerminalTime == "INS")
      {
      TimeUSD += ((Utc_Ins+delta)*3600);
      }
   time1 = time5;
   TimeToStruct(time1, date);
   if(TimeDayOfYear(TimeUSD) - TimeDayOfYear(StringToTime(OZA_OZE)) >= 1) time1 = datetime((string)date.year + "." + (string)date.mon + "." + (string)(date.day + 1) + " "+ (string)TimeUSD);
   else time1 = datetime((string)date.year + "." + (string)date.mon + "." + (string)date.day + " "+ (string)TimeUSD);
   if(time1 < TimeCurrent())
   {
   time2 = time1 + A_length2;
   int shift = iBarShift(NULL, 0, time1, true);
   if(nam1 == "EUR__" || nam1 == "USD__") price1 = iClose(NULL, 0, shift);                   // price1 = iClose(NULL, 0, shift);
   else price1 = iOpen(NULL, 0, shift);
   // Подкорректируем цену с младшего таймфрэйма
   int tm[] = {1, 5, 15, 30, 60, 240, 14400, 10080, 43200};
   for (int i = 0; i < ArraySize(tm) && tm[i] <= _Period; i++)
      {
      if ((shift = iBarShift(NULL, tm[i], time1, true)) != -1)
         {
         if(nam1 == "EUR__" || nam1 == "USD__") price1 = iClose(NULL, tm[i], shift);                     // price1 = iClose(NULL, tm[i], shift);
         else price1 = iOpen(NULL, tm[i], shift);
         break;
         }
      }
   name = nam1 + (string)time1;
   time2 = correctWeekend(time1, time2);
         ObjectCreate(name, OBJ_TREND, 0, 0, 0, 0, 0);
         ObjectSet(name, OBJPROP_TIME1, time1);
         ObjectSet(name, OBJPROP_PRICE1, price1);
         ObjectSet(name, OBJPROP_TIME2, time2);
         ObjectSet(name, OBJPROP_PRICE2, price1);
         ObjectSet(name, OBJPROP_TIMEFRAMES, A_timeframe); // Таймфрейм для отображения
         ObjectSet(name, OBJPROP_WIDTH, A_width1);         // Толщина
         ObjectSet(name, OBJPROP_STYLE, A_style1);         // Стиль
         ObjectSet(name, OBJPROP_COLOR, coler);         // Цвет
         ObjectSet(name, OBJPROP_BACK, true);              // Рисовать объект в фоне
         ObjectSet(name, OBJPROP_SELECTED, false);         // Снять выделение с объекта
         //ObjectSet(name, OBJPROP_SELECTABLE, false);     // Запрет на редактирование
         ObjectSet(name, OBJPROP_RAY, false);              // Рисовать не луч
   if(nam1 == "EURO_") {seeeOE_time = time1; seeeOE_price = price1;}
   else if(nam1 == "EUR__") {seeeZE_time = time1; seeeZE_price = price1;}
   else if(nam1 == "USDO_") {seeeOU_time = time1; seeeOU_price = price1;}
   else if(nam1 == "USD__") {seeeZU_time = time1; seeeZU_price = price1;}
   seeeKEY = 1;
//Alert(seeeOE_time, time1,seeeOE_price,price1);
   }
   return;
   }
//*--------------------------------------------------------------------*
//| Найдем ближайшую зону 1/4 или ДКЗ или НКЗ
//*--------------------------------------------------------------------*
void Gde_Zonki()
   {
   string name;
   int u = 0;
   for(int i = 0; i < ObjectsTotal(); i++)
      {
      name = "";
      if((name = ObjectName(0,i,0,OBJ_RECTANGLE)) != NULL)
         {
         if(ObjectGet(name, OBJPROP_TIME1) <= TimeCurrent() && ObjectGet(name, OBJPROP_TIME2) >= TimeCurrent() && StringSubstr(name,0,3) == "NKZ")
            {
            Zonki[u].name = name;
            Zonki[u].time1 = (datetime)ObjectGet(name, OBJPROP_TIME1);
            Zonki[u].price1 = ObjectGetDouble(0,name,OBJPROP_PRICE1);
            Zonki[u].time2 = (datetime)ObjectGet(name, OBJPROP_TIME2);
            Zonki[u].price2 = ObjectGetDouble(0,name,OBJPROP_PRICE2);
            u++;
            }
         }
      }
   for(int i = u; i < ArraySize(Zonki); i++)
      {
      Zonki[u].name = "";
      Zonki[u].time1 = 0;
      Zonki[u].price1 = 0;
      Zonki[u].time2 = 0;
      Zonki[u].price2 = 0;
      }
   return;
   }

//*--------------------------------------------------------------------*
//| Найдем ближайшую зону 1/4 или ДКЗ или НКЗ
//*--------------------------------------------------------------------*
int Gde_Zona(string nam1, datetime time1, double price1)
   {
//Alert("! ",nam1);
   string nameZ, name1;
   int key = 0, w_w =0;
   double price2 = 0;
   for(int i = 0; i < ObjectsTotal(); i++)
      {
      DeleteByPrefix("Buy_");
      DeleteByPrefix("Sel_");
      }
   for(int i = 0; i < ArraySize(Zonki); i++)
      {
      key = 0;
      nameZ = Zonki[i].name;
      if(nameZ != "")
         {
         if(StringSubstr(nameZ,0,5) != nam1)
            {
            if(nam1 == "NKZC_") nam1 = "NKZc_";
            else if(nam1 == "NKZD_") nam1 = "NKZd_";
            else if(nam1 == "NKZN_") nam1 = "NKZn_";
            } 
         if(Zonki[i].time1 <= time1 && Zonki[i].time2 >= time1 && StringSubstr(nameZ,0,5) == nam1)
         {
         if(StringSubstr(nameZ,25,1) == "L" && Zonki[i].price1 < price1 && Zonki[i].price2 < price1)
            {
               price2 = Zonki[i].price1;
               name1 = "Buy_" + (string)time1 + (string)price2;
               key = 1;               
            } 
         else if(StringSubstr(nameZ,25,1) == "H" && Zonki[i].price1 > price1 && Zonki[i].price2 > price1)
            {
               price2 = Zonki[i].price2;
               name1 = "Sel_" + (string)time1 +"_"+ (string)price2;
               key = 2;               
            } 
         if(key > 0) 
            {
               if(key == 1) 
                  {
                  ObjectCreate(name1,OBJ_ARROW_UP,0,time1,price2,0,0,0,0);
                  ObjectSet(name1, OBJPROP_COLOR, clrGreen);         // Цвет
                  ObjectSet(name1, OBJPROP_ANCHOR, ANCHOR_BOTTOM);         // привязка
                  }
               else if(key == 2) 
                  {
                  ObjectCreate(name1,OBJ_ARROW_DOWN,0,time1,price2,0,0,0,0);
                  ObjectSet(name1, OBJPROP_COLOR, clrRed);         // Цвет
                  ObjectSet(name1, OBJPROP_ANCHOR, ANCHOR_TOP);         // привязка
                  }
               ObjectSet(name1, OBJPROP_WIDTH, 4);         // размер
               ObjectSet(name1, OBJPROP_SELECTED, false);         // Снять выделение с объекта
               if (ZonaAlertMode) AlertInfoAdd(ChartID(), _Symbol + ": Закрепление за зоной"); // Добавить строку в Alert
               else Alert(_Symbol + ": Закрепление за зоной");
               if (ZonaAlertSound) PlaySound(sound_Correct);
               w_w = 1;
            }
         }
         }
      }
   return w_w;
   }
//*--------------------------------------------------------------------*
//| Рисуем стрелочки на истории
//*--------------------------------------------------------------------*
void Strel_Hist(string nam1, string nam2, string nam3, datetime time1, double price1)
   {
   string name2, name1, nan;
   double price2 = 0;
   int key=0;
   for(int i = 0; i < ObjectsTotal(); i++)
      {
      name2 = "";
      key = 0;
      price2 = 0;
      if((name2 = ObjectName(0,i,0,OBJ_RECTANGLE)) != NULL)
         {
         for(int y = 0; y < 3; y++)
            {
            if(y == 0) nan = nam1; else if(y == 1) nan = nam2; else if(y == 2) nan = nam3;
            if(StringSubstr(name2,0,5) != nan)
               {
               if(nan == "NKZC_") nan = "NKZc_";
               else if(nan == "NKZD_") nan = "NKZd_";
               else if(nan == "NKZN_") nan = "NKZn_";
               } 
               if(ObjectGet(name2, OBJPROP_TIME1) <= time1 && ObjectGet(name2, OBJPROP_TIME2) >= time1 && StringSubstr(name2,0,5) == nan)
                  {
                  if(StringSubstr(name2,25,1) == "L" && ObjectGet(name2, OBJPROP_PRICE1) < price1 && ObjectGet(name2, OBJPROP_PRICE2) < price1)
                     {
                     price2 = ObjectGet(name2, OBJPROP_PRICE1);
                     name1 = "Buy_" + (string)time1 + (string)price2;
                     key = 1;               
                     } 
                  else if(StringSubstr(name2,25,1) == "H" && ObjectGet(name2, OBJPROP_PRICE1) > price1 && ObjectGet(name2, OBJPROP_PRICE2) > price1)
                     {
                     price2 = ObjectGet(name2, OBJPROP_PRICE2);
                     name1 = "Sel_" + (string)time1 +"_"+ (string)price2;
                     key = 2;               
                     } 
                  if(key > 0) 
                     {
                     if(key == 1) 
                       {
                       ObjectCreate(name1,OBJ_ARROW_UP,0,time1,price2,0,0,0,0);
                       ObjectSet(name1, OBJPROP_COLOR, clrGreen);         // Цвет
                       ObjectSet(name1, OBJPROP_ANCHOR, ANCHOR_BOTTOM);         // привязка
                       }
                     else if(key == 2) 
                       {
                       ObjectCreate(name1,OBJ_ARROW_DOWN,0,time1,price2,0,0,0,0);
                       ObjectSet(name1, OBJPROP_COLOR, clrRed);         // Цвет
                       ObjectSet(name1, OBJPROP_ANCHOR, ANCHOR_TOP);         // привязка
                       }
                     ObjectSet(name1, OBJPROP_WIDTH, 4);         // размер
                     ObjectSet(name1, OBJPROP_SELECTED, false);         // Снять выделение с объекта
                     }
                  }
               }
           }
      }
   }
//*--------------------------------------------------------------------*
//| Ищем следы оставленные до инита или смены таймфрейма
//*--------------------------------------------------------------------*
void Poisk()
   {
   string name;
   int mkz = 0, euro = 0, eurz = 0, usdo = 0, usdz = 0;
   for(int i = 0; i < ObjectsTotal(); i++)
      {
      name = ObjectName(i);
      if (StringSubstr(name, 0, 5) == "MKZ__") {vol_key = 0; vol_atr = 0; mkz = 1;}
      else if (StringSubstr(name, 0, 5) == "EURO_") {seeeOE = 1; seeeKEY = 0;  euro = 1;}
      else if (StringSubstr(name, 0, 5) == "EUR__") {seeeZE = 1; seeeKEY = 0;  eurz = 1;}
      else if (StringSubstr(name, 0, 5) == "USDO_") {seeeOA = 1; seeeKEY = 0;  usdo = 1;}
      else if (StringSubstr(name, 0, 5) == "USD__") {seeeZA = 1; seeeKEY = 0;  usdz = 1;}
      }
   if(mkz) Vol_MKZ();
   if(euro) {Op_Cl_E_A("Отк.EUR","EURO_",A_colorEO); seeeOE = 1; Op_Cl_E_A("Отк.EUR","EURO_",A_colorEO);}
   if(eurz) {Op_Cl_E_A("Зак.EUR","EUR__",A_colorEZ); seeeZE = 1; Op_Cl_E_A("Зак.EUR","EUR__",A_colorEZ);}
   if(usdo) {Op_Cl_E_A("Отк.USD","USDO_",A_colorAO); seeeOA = 1; Op_Cl_E_A("Отк.USD","USDO_",A_colorAO);}
   if(usdz) {Op_Cl_E_A("Зак.USD","USD__",A_colorAZ); seeeZA = 1; Op_Cl_E_A("Зак.USD","USD__",A_colorAZ);}
   return;
   }
//*--------------------------------------------------------------------*
//| Тест
//*--------------------------------------------------------------------*
double Testik()
   {
   double ATRr;
   datetime time1;
   int summ = 0, histr = 0, qw = iBarShift(NULL, PERIOD_D1,button_time,true);
   for(int i = 1; i <= kol_ATR; i++)
      {
      time1 = iTime(NULL, PERIOD_D1, qw + i);
      if(iBarShift(NULL, PERIOD_M30, time1, true) >= 0)
         {
         summ += (int)((iHigh(NULL, PERIOD_D1, qw + i) - iLow(NULL, PERIOD_D1, qw + i)) / _Point);
         histr++;
         }
      }
   ATRr = (double)summ / histr;
   return ATRr;
   }
//*--------------------------------------------------------------------*
//| Расчет мин цены и  SL на экран
//*--------------------------------------------------------------------*
void InfoMarjin()
   {
   double Free = AccountFreeMargin();
   double One_Lot = MarketInfo(Symbol(),MODE_MARGINREQUIRED);
   double Min_Lot = MarketInfo(Symbol(),MODE_MINLOT);
   double Max_Lot = MarketInfo(Symbol(),MODE_MAXLOT);
   double Step = MarketInfo(Symbol(),MODE_LOTSTEP);
   double LotVal = MarketInfo(Symbol(),MODE_TICKVALUE);
   double Spr = Min_Lot * One_Lot;
   if(st1 == true) ObjectSetText ( "tabl"+IntegerToString(3), "Мин.Лот = "+(string)Min_Lot + " по цене = "+DoubleToStr(Spr,2) + " $");
   else ObjectDelete("tabl"+IntegerToString(3));
   double Lot = 0;
   if(LotVal && Step) Lot = MathFloor((Free*MaxRisk)/100/(StopLoss*LotVal)/Step)*Step;   
   if(Lot < Min_Lot) Lot = Min_Lot;
   if(Lot > Max_Lot) Lot = Max_Lot;
   if(Lot * One_Lot > Free) Lot = 0.0;
   if(st2 == true) ObjectSetText ( "tabl"+IntegerToString(4), "Риск = " + (string)MaxRisk + "% SL = " + (string)StopLoss + "п. Lot = " + DoubleToStr(Lot,2));
   else ObjectDelete("tabl"+IntegerToString(4));
   if(st3 == true) ObjectSetText ( "tabl"+IntegerToString(5), "Цена за 1 пункт 1 лота = " + DoubleToStr(LotVal,2) + "$");
   else ObjectDelete("tabl"+IntegerToString(5));
   return;
   }
//*--------------------------------------------------------------------*
//| Определим высокосный день
//*--------------------------------------------------------------------*
bool LeapYear(datetime aTime)
   {
   MqlDateTime stm;
   TimeToStruct(aTime,stm);
   // кратен 4
   if(stm.year%4 == 0)
      {
      // кратен 100
      if(stm.year%100 == 0)
         {
         // кратен 400
         if(stm.year%400 == 0)
            {
            return (true);
            }            
         }
      // не кратен 100
      else
         {
         return (true);
         }
      }
   return (false);
   }
//*--------------------------------------------------------------------*
//| Определим количество дней в месяце
//*--------------------------------------------------------------------*
int DaysInMonth(datetime aTime)
   {
   MqlDateTime stm;
   TimeToStruct(aTime,stm);
   if(stm.mon == 2)
      {
      // Февраль
      if(LeapYear(aTime))
         {
         // февраль високосного года
         return (29);
         }
      else
         {
         // февраль обычного года
         return (28);
         }
      }
   else
      {
      // остальные месяцы
      return (31 - ((stm.mon - 1)%7)%2);
      }
   }


   
