//+------------------------------------------------------------------+
//| Types.mqh                                                        |
//| Shared types and enums for TM_TrendFollowerScalper.              |
//+------------------------------------------------------------------+
#ifndef TM_EA_TYPES_MQH
#define TM_EA_TYPES_MQH

enum ENUM_TREND_STATE
{
   TREND_STATE_NONE = 0,
   TREND_STATE_UP,
   TREND_STATE_DOWN
};

enum ENUM_SETUP_TYPE
{
   SETUP_NONE = 0,
   SETUP_PULLBACK,
   SETUP_BREAKOUT
};

struct SSignal
{
   bool            valid;
   int             direction;          // +1 buy, -1 sell
   ENUM_SETUP_TYPE setup;
   datetime        signalBarTime;
   double          entryReference;
   double          invalidationLevel;
   string          reason;
};

#endif // TM_EA_TYPES_MQH
