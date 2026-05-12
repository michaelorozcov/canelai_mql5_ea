enum PivotType {
    PIVOT_TYPE_HIGH,
    PIVOT_TYPE_LOW,
};

enum PivotOrder {
    PIVOT_ORDER_1,
    PIVOT_ORDER_2,
    PIVOT_ORDER_3,
};

struct PivotPoint {
    int rate_index;
    PivotType type;
    PivotOrder order;

    PivotPoint() {
        clear();
    }

    PivotPoint(
        int arg_rate_index, PivotType arg_type, PivotOrder arg_order) {
        this.rate_index = arg_rate_index;
        this.type = arg_type;
        this.order = arg_order;
    }

    void clear() {
        rate_index = 0;
    }

    bool is_valid() {
        return rate_index > 0;
    }

    bool is_equal(PivotPoint& other) {
        return (rate_index == other.rate_index) &&
               (type == other.type) &&
               (order == other.order);
    }

    void clone(PivotPoint& dest) {
        dest.rate_index = rate_index;
        dest.type = type;
        dest.order = order;
    }
};

struct ChartPivot {
    string name;
    color colour;
    datetime time;
    double price;
};
