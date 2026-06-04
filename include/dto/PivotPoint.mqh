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
    double rate_price;
    datetime rate_time;

    PivotType type;
    PivotOrder order;

    PivotPoint() {
        clear();
    }

    PivotPoint(
        int index, double price, datetime time, PivotType arg_type, PivotOrder arg_order) {
        this.rate_index = index;
        this.rate_price = price;
        this.rate_time = time;
        this.type = arg_type;
        this.order = arg_order;
    }

    void clear() {
        this.rate_index = 0;
        this.rate_price = 0;
        this.rate_time = 0;
    }

    bool is_valid() {
        return ((this.rate_price != 0) && (this.rate_time != 0));
    }

    bool is_equal(PivotPoint& other) {
        return (rate_price == other.rate_price) &&
               (rate_time == other.rate_time) &&
               (type == other.type) &&
               (order == other.order);
    }

    void clone(PivotPoint& dest) {
        dest.rate_index = this.rate_index;
        dest.rate_price = this.rate_price;
        dest.rate_time = this.rate_time;
        dest.type = this.type;
        dest.order = this.order;
    }
};

struct ChartPivot {
    string name;
    color colour;
    datetime time;
    double price;
};
