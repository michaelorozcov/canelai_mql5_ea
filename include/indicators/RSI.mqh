enum ENUM_RSI_EXTENSION {
    RSI_NONE_EXT,
    RSI_OVERBOUGHT_EXT,
    RSI_OVERSOLD_EXT,
};

enum ENUM_RSI_PERIOD {
    RSI_PERIOD_0 = 0,
    RSI_PERIOD_5 = 5,
    RSI_PERIOD_7 = 7,
    RSI_PERIOD_9 = 9,
    RSI_PERIOD_14 = 14,
};

class RSI {

  private:
    static const int RSI_BUFFER_NUMBER;

  public:
    static int get_rsi_handler(int period = 14, ENUM_APPLIED_PRICE apply_to = PRICE_CLOSE) {
        return iRSI(_Symbol, _Period, period, apply_to);
    }

    static bool get_rsi_value(
        double& out_result, int in_handler, datetime in_time) {

        if (in_handler == INVALID_HANDLE) {
            Print("RSI: INVALID_HANDLE ", in_handler);
            return false;
        }

        double rsi_values[];
        CopyBuffer(in_handler, RSI_BUFFER_NUMBER, in_time, 1, rsi_values);

        if (ArraySize(rsi_values) < 1) {
            Print("RSI: FAIL COPY");
            return false;
        }

        double rsi_value = rsi_values[0];

        if ((rsi_value < 0) || (rsi_value > 100)) {
            Print("RSI: WRONG VALUE ", rsi_value);
            return false;
        }

        out_result = NormalizeDouble(rsi_value, _Digits);
        return true;
    }
};

static const int RSI::RSI_BUFFER_NUMBER = 0;
