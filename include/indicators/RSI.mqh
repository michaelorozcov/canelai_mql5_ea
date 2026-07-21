enum ENUM_RSI_EXTENSION {
    RSI_NONE_EXT,
    RSI_OVERBOUGHT_EXT,
    RSI_OVERSOLD_EXT,
};

enum ENUM_RSI_PERIOD {
    RSI_PERIOD_7 = 7,
    RSI_PERIOD_14 = 14,
    RSI_PERIOD_20 = 20,
};

class RSI {

  private:
    static const int RSI_BUFFER_NUMBER;
    static const int RSI_DIGITS_NUMBER;

  public:
    static int get_rsi_handler(int period = 14, ENUM_APPLIED_PRICE apply_to = PRICE_CLOSE) {
        return iRSI(_Symbol, _Period, period, apply_to);
    }

    static ENUM_RSI_EXTENSION get_rsi_extension(
        int handler, datetime time, double threshold_top, double threshold_bottom) {

        double value = 0.0;
        bool success = get_rsi_value(value, handler, time);

        if (!success) {
            Print("RSI: Error getting value at: ", time);
            return RSI_NONE_EXT;
        }

        if (value > threshold_top)
            return RSI_OVERBOUGHT_EXT;

        if (value < threshold_bottom)
            return RSI_OVERSOLD_EXT;

        return RSI_NONE_EXT;
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

        out_result = NormalizeDouble(rsi_value, RSI_DIGITS_NUMBER);
        return true;
    }
};

static const int RSI::RSI_BUFFER_NUMBER = 0;
static const int RSI::RSI_DIGITS_NUMBER = 2;
