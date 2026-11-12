//+------------------------------------------------------------------+
//| Logger.mqh                                                       |
//| Basic logging helper.                                            |
//+------------------------------------------------------------------+
#ifndef TM_EA_LOGGER_MQH
#define TM_EA_LOGGER_MQH

class CLogger
{
private:
   int    m_file;
   string m_symbol;
   int    m_magic;

public:
   CLogger()
   {
      m_file = INVALID_HANDLE;
      m_symbol = "";
      m_magic = 0;
   }

   void Init(const string symbol, const int magic)
   {
      m_symbol = symbol;
      m_magic = magic;
      string fileName = "TM_TrendFollowerScalper_" + symbol + ".log";
      m_file = FileOpen(fileName, FILE_WRITE | FILE_TXT | FILE_COMMON);
      if(m_file != INVALID_HANDLE)
         FileSeek(m_file, 0, SEEK_END);
   }

   void Deinit()
   {
      if(m_file != INVALID_HANDLE)
      {
         FileClose(m_file);
         m_file = INVALID_HANDLE;
      }
   }

   void Log(const string message)
   {
      string line = TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) +
                    " | " + m_symbol +
                    " | magic=" + IntegerToString(m_magic) +
                    " | " + message;

      Print(line);

      if(m_file != INVALID_HANDLE)
      {
         FileWriteString(m_file, line + "\n");
         FileFlush(m_file);
      }
   }
};

#endif // TM_EA_LOGGER_MQH
