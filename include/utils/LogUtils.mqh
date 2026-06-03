#include "Constants.mqh"

class LogUtils {
  public:
    static string get_log_filename(string base_filename) {
        string str_date = TimeToString(TimeGMT(), TIME_DATE);
        StringReplace(str_date, ".", "-");
        return StringFormat(LOGS_FILENAME_TEMPLATE, base_filename, str_date);
    }

    static int get_log_handle(string log_filename) {
        return FileOpen(log_filename, FILE_READ | FILE_WRITE | FILE_TXT);
    }

    static void log(string base_filename, string message) {
        string log_filename = get_log_filename(base_filename);
        int log_handle = get_log_handle(log_filename);

        if (log_handle == INVALID_HANDLE) {
            Print("Operation FileOpen failed: ", GetLastError());
            return;
        }

        string str_date = TimeToString(TimeGMT(), TIME_DATE | TIME_MINUTES | TIME_SECONDS);
        string entry = StringFormat(LOGS_ENTRY_TEMPLATE, str_date, message);

        FileSeek(log_handle, 0, SEEK_END);
        FileWrite(log_handle, entry);
        FileClose(log_handle);
    }
};
