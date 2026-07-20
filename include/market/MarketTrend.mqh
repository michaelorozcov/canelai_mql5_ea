#include "./../../include/dto/PivotPoint.mqh"
#include "./../../include/dto/Trend.mqh"

#include "./../../include/utils/ArrayUtils.mqh"
#include "./../../include/utils/ChartUtils.mqh"
#include "./../../include/utils/Constants.mqh"
#include "./../../include/utils/RatesUtils.mqh"

#include "./../../include/market/MarketPivot.mqh"

class MarketTrend {

  private:
    static int trend_counter;
    static string trend_names[];

    static string get_chart_trend_name(Trend& trend) {
        return "T_" + IntegerToString(++trend_counter);
    }

    static color get_chart_trend_color(Trend& trend) {
        return (trend.type == TREND_BULLISH) ? TREND_BULLISH_COLOR : TREND_BEARISH_COLOR;
    }

    static double get_chart_trend_start_price(Trend& trend) {
        return MarketPivot::get_pivot_price(trend.start, true);
    }

    static double get_chart_trend_end_price(Trend& trend) {
        return MarketPivot::get_pivot_price(trend.end, true);
    }

    static double get_trend_threshold(PivotPoint& pivots[], TrendConfig& config) {

        PivotPoint first = pivots[0], last;
        ArrayUtils::get_last_item(last, pivots);

        double avg_range = RatesUtils::get_average_range(
            first.rate_index, last.rate_index);

        return (avg_range * config.sensitivity);
    }

  public:
    static void delete_trends() {
        for (int i = 0; i < ArraySize(trend_names); i++)
            ChartUtils::delete_chart_object(trend_names[i]);
        ArrayUtils::clear(trend_names);
        trend_counter = 0;
    }

    static void draw_trend(Trend& trend) {

        if (!trend.is_valid())
            return;

        string trend_name = get_chart_trend_name(trend);

        ChartUtils::create_chart_object(
            OBJ_TREND,
            trend_name,
            RatesUtils::get_rate_time(trend.start.rate_index),
            get_chart_trend_start_price(trend),
            RatesUtils::get_rate_time(trend.end.rate_index),
            get_chart_trend_end_price(trend));

        ObjectSetInteger(
            0,
            trend_name,
            OBJPROP_COLOR,
            get_chart_trend_color(trend));

        ArrayUtils::add_item(trend_names, trend_name);
    }

    static bool are_trend_pivots(
        PivotPoint& pivots[], TrendType trend_type, TrendConfig& config) {

        if (ArraySize(pivots) < 2)
            return false;

        double threshold = get_trend_threshold(pivots, config);

        for (int i = 0; i < (ArraySize(pivots) - 1); i++) {

            int current_index = pivots[i].rate_index;
            int next_index = pivots[i + 1].rate_index;

            double current_price = MarketPivot::get_pivot_price(pivots[i], true);
            double next_price = MarketPivot::get_pivot_price(pivots[i + 1], true);

            bool price_diff = MathAbs(current_price - next_price) >= threshold;
            if (!price_diff)
                return false;

            if (trend_type == TREND_BULLISH && (current_price > next_price))
                return false;

            if (trend_type == TREND_BEARISH && (current_price < next_price))
                return false;
        }

        return true;
    }

    static void get_init_trend(Trend& trend, int lowest_rate_index) {
        trend.clear();

        int start_index = RatesUtils::get_highest_rate_index();
        int end_index = lowest_rate_index;

        for (int i = start_index; i > end_index; i--) {

            Trend bullish_trend, bearish_trend;
            get_init_trend_by_type(bullish_trend, TREND_BULLISH, i);
            get_init_trend_by_type(bearish_trend, TREND_BEARISH, i);

            if (bullish_trend.is_valid() && bearish_trend.is_valid()) {
                continue;

            } else if (bullish_trend.is_valid()) {
                trend = bullish_trend;
                break;

            } else if (bearish_trend.is_valid()) {
                trend = bearish_trend;
                break;
            }
        }
    }

    static void get_init_trend_by_type(
        Trend& trend, TrendType trend_type, int start_index) {

        PivotPoint pivots[];
        PivotType type = MarketPivot::get_pivot_type_from_trend_type(trend_type);

        for (int i = 0; i < ArraySize(TREND_BIAS_CONFIG); i++) {
            TrendConfig bias = TREND_BIAS_CONFIG[i];

            MarketPivot::get_pivot_points(
                pivots, type, bias.order, start_index, bias.length);

            bool trend_pivots = are_trend_pivots(pivots, trend_type, bias);
            if (!trend_pivots)
                continue;

            get_trend(trend, trend_type, pivots);
            break;
        }
    }

    static void get_trend(Trend& trend, TrendType type, PivotPoint& pivots[]) {

        PivotPoint start = pivots[0], end;
        ArrayUtils::get_last_item(end, pivots);

        trend.type = type;
        trend.start = start;
        trend.end = end;
    }
};

static int MarketTrend::trend_counter = 0;
static string MarketTrend::trend_names[];
