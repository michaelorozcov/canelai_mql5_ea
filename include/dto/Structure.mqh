#include "./../../include/dto/PivotPoint.mqh"
#include "./../../include/dto/Trend.mqh"

#include "./../../include/market/MarketPivot.mqh"

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

    bool is_valid() {
        return start.is_valid() && end.is_valid();
    }

    TrendType get_trend_type() {

        if (!is_valid())
            return TREND_RANGING;

        double start_price = MarketPivot::get_pivot_price(start, true);
        double end_price = MarketPivot::get_pivot_price(end, true);

        if (end_price > start_price)
            return TREND_BULLISH;

        else if (end_price < start_price)
            return TREND_BEARISH;

        else
            return TREND_RANGING;
    }

    double get_price_top() {
        PivotPoint pivot = is_bullish() ? end : start;
        return MarketPivot::get_pivot_price(pivot, true);
    }

    double get_price_bottom() {
        PivotPoint pivot = is_bullish() ? start : end;
        return MarketPivot::get_pivot_price(pivot, true);
    }

    bool is_bullish() {
        return get_trend_type() == TREND_BULLISH;
    }

    bool is_bearish() {
        return get_trend_type() == TREND_BEARISH;
    }
};
