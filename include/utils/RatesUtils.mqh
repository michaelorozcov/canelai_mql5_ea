#include "ArrayUtils.mqh"
#include "ChartUtils.mqh"
#include "Constants.mqh"

class RatesUtils {

  private:
    static MqlRates rates[];

    static void draw_limit(string name, datetime time) {
        ChartUtils::create_chart_object(OBJ_VLINE, name, time);
        ObjectSetInteger(
            0, name, OBJPROP_COLOR, RATES_LIMIT_COLOR);
        ObjectSetInteger(
            0, name, OBJPROP_STYLE, RATES_LIMIT_STYLE);
    }

    static void draw_rates_limits() {
        if (ArraySize(rates) < 2)
            return;

        draw_limit(
            RATES_LIMIT_LEFT,
            get_rate_time(get_analysis_start_index()));

        draw_limit(
            RATES_LIMIT_RIGHT,
            get_rate_time(ANALYSIS_LIMIT_LOWEST_INDEX));
    }

  public:
    static void delete_rates() {
        ChartUtils::delete_chart_object(RATES_LIMIT_LEFT);
        ChartUtils::delete_chart_object(RATES_LIMIT_RIGHT);
        ArrayUtils::clear(rates);
    }

    static void set_rates(AdvisorArgs& data) {

        ArrayUtils::clear(rates);
        ArraySetAsSeries(rates, true);

        CopyRates(
            _Symbol, _Period, 0,
            get_shift_rates(_Period, RATES_LIMIT_SHIFT_MINUTES),
            rates);

        if (data.visual_mode)
            draw_rates_limits();
    }

    static void get_rate(MqlRates& rate, int rate_index) {
        if ((rate_index >= 0) && (rate_index < ArraySize(rates)))
            rate = rates[rate_index];
    }

    static int get_shift_rates(ENUM_TIMEFRAMES period, int minutes) {
        int session_seconds = (minutes * 60);
        int period_seconds = PeriodSeconds(period);
        return (session_seconds / period_seconds);
    }

    static int get_highest_rate_index() {
        return (ArraySize(rates) - 1);
    }

    static int get_analysis_start_index() {
        return get_shift_rates(_Period, ANALYSIS_LIMIT_SHIFT_MINUTES);
    }

    static bool is_bullish_rate(int rate_index) {
        MqlRates rate;
        get_rate(rate, rate_index);
        return (rate.close > rate.open);
    }

    static bool is_bearish_rate(int rate_index) {
        MqlRates rate;
        get_rate(rate, rate_index);
        return (rate.open > rate.close);
    }

    static datetime get_rate_time(int rate_index) {
        MqlRates rate;
        get_rate(rate, rate_index);
        return rate.time;
    }

    static double get_rate_lowest_price(int rate_index, bool wicks) {
        MqlRates rate;
        get_rate(rate, rate_index);

        if (!wicks)
            return (rate.close < rate.open) ? rate.close : rate.open;

        return rate.low;
    }

    static double get_rate_highest_price(int rate_index, bool wicks) {
        MqlRates rate;
        get_rate(rate, rate_index);

        if (!wicks)
            return (rate.close > rate.open) ? rate.close : rate.open;

        return rate.high;
    }

    static double get_rate_size(int rate_index) {
        MqlRates rate;
        get_rate(rate, rate_index);
        return MathAbs(rate.open - rate.close);
    }

    static double get_average_size(int start_index, int end_index) {
        double average = 0;
        int counter = 0;

        for (int i = start_index; i >= end_index; i--) {
            average += get_rate_size(i);
            counter++;
        }

        if (average == 0.0 || counter == 0)
            return 0;

        return (average / counter);
    }

    static double get_rate_range(int rate_index) {
        MqlRates rate;
        get_rate(rate, rate_index);
        return MathAbs(rate.high - rate.low);
    }

    static double get_average_range(int start_index, int end_index) {
        double average = 0;
        int counter = 0;

        for (int i = start_index; i >= end_index; i--) {
            average += get_rate_range(i);
            counter++;
        }

        if (average == 0.0 || counter == 0)
            return 0;

        return (average / counter);
    }

    static long get_rate_volume(int rate_index) {
        MqlRates rate;
        get_rate(rate, rate_index);
        return rate.tick_volume;
    }

    static double get_average_volume(int start_index, int end_index) {
        double average = 0;
        int counter = 0;

        for (int i = start_index; i >= end_index; i--) {
            average += ((double)get_rate_volume(i));
            counter++;
        }

        if (average == 0.0 || counter == 0)
            return 0;

        return (average / counter);
    }

    static bool is_respected_price(
        int start, int end, double price, bool upper_limit,
        bool check_wicks, double margin) {

        double limit = upper_limit ? (price + margin) : (price - margin);

        for (int i = start; i >= end; i--) {

            if (upper_limit) {
                double high = get_rate_highest_price(i, check_wicks);
                if (high > limit)
                    return false;

            } else {
                double low = get_rate_lowest_price(i, check_wicks);
                if (low < limit)
                    return false;
            }
        }

        return true;
    }
};

static MqlRates RatesUtils::rates[];
