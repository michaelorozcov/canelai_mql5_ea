class ATR {
  public:
    static int get_atr_handler(int period = 14) {
        return iATR(_Symbol, _Period, period);
    }

    static bool get_atr_value(
        double& out_result, const int in_handler, const datetime in_time) {

        if (in_handler == INVALID_HANDLE) {
            Print("ATR: INVALID_HANDLE ", in_handler);
            return false;
        }

        if (BarsCalculated(in_handler) <= 0) {
            Print("ATR: Not calculated yet");
            return false;
        }

        double atr_values[];
        int copied = CopyBuffer(in_handler, ATR_BUFFER_NUMBER, in_time, 1, atr_values);

        if (copied != 1) {
            Print("ATR: CopyBuffer failed. Error=", GetLastError());
            return false;
        }

        out_result = atr_values[0];

        return true;
    }

  private:
    static const int ATR_BUFFER_NUMBER;
};

static const int ATR::ATR_BUFFER_NUMBER = 0;
