enum ENUM_BOLLINGER_BANDS_EXT {
    BB_NONE_EXT,
    BB_UPPER_BAND_EXT,
    BB_LOWER_BAND_EXT,
};

enum ENUM_BOLLINGER_PERIOD {
    BB_PERIOD_7 = 7,
    BB_PERIOD_14 = 14,
    BB_PERIOD_20 = 20,
};

struct BollingerBandsValues {
    double upper_band;
    double middle_band;
    double lower_band;
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

    /*
        Reference values, round to 1 decimal:
        < 0     Break lower band
        = 0     Over lower band
        = 0.5   Over middle band
        = 1     Over upper band
        > 1     Break upper band
    */
    static bool get_bollinger_extension(
        double& bb_ext_value,
        int handler, datetime time, double price) {

        BollingerBandsValues bb_values;
        if (get_bollinger_bands_values(bb_values, handler, time)) {

            double numerator = (price - bb_values.lower_band);
            double denominator = (bb_values.upper_band - bb_values.lower_band);

            if (denominator > 0) {
                bb_ext_value = NormalizeDouble((numerator / denominator), _Digits);
                return true;
            }
        }

        return false;
    }

    static bool get_bollinger_bands_values(
        BollingerBandsValues& out_values,
        int in_handler, datetime in_time) {

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

        return true;
    }
};

static const int BollingerBands::BB_MIDDLE_BAND = 0;
static const int BollingerBands::BB_UPPER_BAND = 1;
static const int BollingerBands::BB_LOWER_BAND = 2;
