#include "PivotPoint.mqh"
#include "Trend.mqh"

#include "../../include/utils/RatesUtils.mqh";

struct BlockBreakout {
    TrendType bias;
    PivotPoint pivot;

    BlockBreakout() {
        clear();
    }

    bool is_valid() {
        return bias != TREND_RANGING && pivot.is_valid();
    }

    void clear() {
        bias = TREND_RANGING;
        pivot.clear();
    }
};

struct StructureBlock {
    PivotPoint start;
    PivotPoint end;
    BlockBreakout breakout;

    StructureBlock() {
        clear();
    }

    void clear() {
        start.clear();
        end.clear();
        breakout.clear();
    }

    double get_start_price() {
        // TODO
        /*return is_bullish()
                   ? RatesUtils::get_rate_lowest_price(start.rate_index, true)
                   : RatesUtils::get_rate_highest_price(start.rate_index, true);*/
        return this.start.rate_price;
    }

    double get_end_price() {
        /*return is_bullish()
                   ? RatesUtils::get_rate_highest_price(end.rate_index, true)
                   : RatesUtils::get_rate_lowest_price(end.rate_index, true);*/
        return this.end.rate_price;
    }

    double get_top_price() {
        // TODO
        /*return is_bullish()
                   ? RatesUtils::get_rate_highest_price(end.rate_index, true)
                   : RatesUtils::get_rate_highest_price(start.rate_index, true);*/
        return is_bullish()
                   ? this.end.rate_price
                   : this.start.rate_price;
    }

    double get_bottom_price() {
        // TODO
        /*return is_bullish()
                   ? RatesUtils::get_rate_lowest_price(start.rate_index, true)
                   : RatesUtils::get_rate_lowest_price(end.rate_index, true);*/
        return is_bullish()
                   ? this.start.rate_price
                   : this.end.rate_price;
    }

    bool is_bullish() {
        return get_trend_type() == TREND_BULLISH;
    }

    bool is_bearish() {
        return get_trend_type() == TREND_BEARISH;
    }

    bool is_valid() {
        return start.is_valid() && end.is_valid();
    }

    TrendType get_trend_type() {

        if (!is_valid())
            return TREND_RANGING;

        double start_price = start.rate_price;
        double end_price = end.rate_price;

        if (end_price > start_price)
            return TREND_BULLISH;

        else if (end_price < start_price)
            return TREND_BEARISH;

        else
            return TREND_RANGING;
    }

    bool is_equal(StructureBlock& other) {
        bool same_valid = (this.is_valid() && other.is_valid());
        bool same_start = this.start.is_equal(other.start);
        bool same_end = this.end.is_equal(other.end);
        return (same_valid && same_start && same_end);
    }
};

/*
struct StructureBlockScreenshot {
    datetime start_date, end_date;
    double start_price, end_price;
    bool bullish;
    bool bearish;

    StructureBlockScreenshot() {
        clear();
    }

    StructureBlockScreenshot(StructureBlock& src) {
        clear();

        if (!src.is_valid())
            return;

        this.start_date = RatesUtils::get_rate_time(src.start.rate_index);
        this.end_date = RatesUtils::get_rate_time(src.end.rate_index);
        this.start_price = src.get_start_price();
        this.end_price = src.get_end_price();
        this.bullish = src.is_bullish();
        this.bearish = src.is_bearish();
    }

    bool is_valid() {
        return ((this.start_date != 0) && (this.end_date != 0));
    }

    bool is_equal(StructureBlockScreenshot& compare) {
        bool same_start = start_date == compare.start_date;
        bool same_bullish = bullish == compare.bullish;
        bool same_bearish = bearish == compare.bearish;
        return (same_start && same_bullish && same_bearish);
    }

    double get_size() {
        return get_top_price() - get_bottom_price();
    }

    double get_top_price() {
        return bullish ? end_price : start_price;
    }

    double get_bottom_price() {
        return bullish ? start_price : end_price;
    }

    void clear() {
        this.start_date = 0;
        this.end_date = 0;
        this.start_price = 0;
        this.end_price = 0;
        this.bullish = false;
        this.bearish = false;
    }
};
*/
