enum ENUM_BOLLINGER_BANDS_EXT {
    BB_NONE_EXT,
    BB_UPPER_BAND_EXT,
    BB_LOWER_BAND_EXT,
};

enum ENUM_BOLLINGER_VALUES {
    BB_VALUE_10 = 10,
    BB_VALUE_15 = 15,
    BB_VALUE_20 = 20,
};

struct BollingerBandsValues {
    double upper_band;
    double middle_band;
    double lower_band;
    double band_width_size;
    double band_width_pct;
};

class BollingerBands {

  private:
    static const int BB_MIDDLE_BAND;
    static const int BB_UPPER_BAND;
    static const int BB_LOWER_BAND;

  public:
    static int get_bollinger_handler(
        int period = 20, int shift = 0,
        double deviation = 2.0, ENUM_APPLIED_PRICE apply_to = PRICE_CLOSE) {
        return iBands(_Symbol, _Period,
                      period, shift, deviation, apply_to);
    }

    static bool get_bollinger_bands_values(
        datetime in_time, int in_handler,
        BollingerBandsValues& out_values) {

        if (in_handler == INVALID_HANDLE) {
            Print("BOLLINGER: INVALID_HANDLE ", in_handler);
            return false;
        }

        double base[];
        double upper[];
        double lower[];
        int const AMOUNT = 1;

        CopyBuffer(in_handler, BB_MIDDLE_BAND, in_time, AMOUNT, base);
        CopyBuffer(in_handler, BB_UPPER_BAND, in_time, AMOUNT, upper);
        CopyBuffer(in_handler, BB_LOWER_BAND, in_time, AMOUNT, lower);

        double middle_value = ArraySize(base) > 0 ? base[0] : -1;
        out_values.middle_band = NormalizeDouble(middle_value, _Digits);

        double upper_value = ArraySize(upper) > 0 ? upper[0] : -1;
        out_values.upper_band = NormalizeDouble(upper_value, _Digits);

        double lower_value = ArraySize(lower) > 0 ? lower[0] : -1;
        out_values.lower_band = NormalizeDouble(lower_value, _Digits);

        double width_size = MathAbs(upper_value - lower_value);
        out_values.band_width_size = NormalizeDouble(width_size, _Digits);

        // It represents the normalized width regarding to price.
        double width_pct = (width_size / middle_value) * 100.0;
        out_values.band_width_pct = NormalizeDouble(width_pct, _Digits);

        return true;
    }
};

static const int BollingerBands::BB_MIDDLE_BAND = 0;
static const int BollingerBands::BB_UPPER_BAND = 1;
static const int BollingerBands::BB_LOWER_BAND = 2;
