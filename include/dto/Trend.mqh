#include "./../../include/dto/PivotPoint.mqh"

enum TrendType {
    TREND_RANGING,
    TREND_BULLISH,
    TREND_BEARISH,
};

struct TrendConfig {
    PivotOrder order;
    int length;
    double sensitivity;
};

struct Trend {
    TrendType type;
    PivotPoint start;
    PivotPoint end;

    Trend() {
        clear();
    }

    void clear() {
        this.type = TREND_RANGING;
        start.clear();
        end.clear();
    }

    bool is_valid() {
        return start.is_valid() && end.is_valid() && (this.type != TREND_RANGING);
    }
};
