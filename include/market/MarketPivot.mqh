class MarketPivot {

  private:
    static string chart_pivot_names[];
    static PivotPoint highs_order_1[];
    static PivotPoint lows_order_1[];

    static void delete_chart_pivots() {
        for (int i = 0; i < ArraySize(chart_pivot_names); i++)
            ChartUtils::delete_chart_object(chart_pivot_names[i]);
        ArrayUtils::clear(chart_pivot_names);
    }

    static void get_chart_pivot(ChartPivot& chart_pivot, PivotPoint& pivot) {
        string type = (pivot.type == PIVOT_TYPE_HIGH) ? "H" : "L";
        string order = "1";
        color colour = CHART_PIVOT_COLOR_1;
        int factor = 1;

        switch (pivot.order) {

        case PIVOT_ORDER_1:
            break;

        case PIVOT_ORDER_2:
            order = "2";
            factor = 2;
            colour = CHART_PIVOT_COLOR_2;
            break;

        case PIVOT_ORDER_3:
            order = "3";
            factor = 3;
            colour = CHART_PIVOT_COLOR_3;
            break;

        default:
            break;
        }

        MqlRates rate;
        RatesUtils::get_rate(rate, pivot.rate_index);

        chart_pivot.name = "P" + type + order + "_" + IntegerToString(pivot.rate_index);
        chart_pivot.colour = colour;
        chart_pivot.time = rate.time;
        chart_pivot.price = get_pivot_price(pivot, true);
    }

    static void draw_pivot_point(PivotPoint& pivot) {
        ChartPivot chart_pivot;
        get_chart_pivot(chart_pivot, pivot);

        ChartUtils::create_chart_object(
            OBJ_ARROW_CHECK,
            chart_pivot.name,
            chart_pivot.time,
            chart_pivot.price);

        ObjectSetInteger(
            0,
            chart_pivot.name,
            OBJPROP_COLOR,
            chart_pivot.colour);

        ArrayUtils::add_item(chart_pivot_names, chart_pivot.name);
    }

    static void draw_pivot_points(PivotPoint& pivots[]) {
        for (int i = 0; i < ArraySize(pivots); i++)
            draw_pivot_point(pivots[i]);
    }

    static bool is_pivot(
        PivotType type, int previous_index, int current_index, int next_index) {

        MqlRates previous, current, next;
        RatesUtils::get_rate(previous, previous_index);
        RatesUtils::get_rate(current, current_index);
        RatesUtils::get_rate(next, next_index);

        if (type == PIVOT_TYPE_HIGH)
            return (current.high > previous.high) && (current.high > next.high);

        else if (type == PIVOT_TYPE_LOW)
            return (current.low < previous.low) && (current.low < next.low);

        return false;
    }

    static void set_first_order_pivots(
        PivotPoint& dest[], PivotType type, int start, int end, int strength) {

        ArrayUtils::clear(dest);

        for (int i = start; i >= end; i--) {
            for (int j = 1; j <= strength; j++) {

                if (!is_pivot(type, (i + j), i, (i - j)))
                    break;

                if (j == strength) {
                    PivotPoint pivot = PivotPoint(i, type, PIVOT_ORDER_1);
                    ArrayUtils::add_item(dest, pivot);
                }
            }
        }
    }

  public:
    static void delete_pivot_points() {
        // Chart
        delete_chart_pivots();

        // Data
        ArrayUtils::clear(highs_order_1);
        ArrayUtils::clear(lows_order_1);
    }

    static void set_pivot_points(int lowest_rate_index, bool visual_mode) {
        delete_pivot_points();

        // Order 1
        int strength = FIRST_ORDER_PIVOT_STRENGTH;
        int start = RatesUtils::get_highest_rate_index() - strength;
        int end = lowest_rate_index + strength;

        set_first_order_pivots(highs_order_1, PIVOT_TYPE_HIGH, start, end, strength);
        set_first_order_pivots(lows_order_1, PIVOT_TYPE_LOW, start, end, strength);

        if (visual_mode) {
            draw_pivot_points(highs_order_1);
            draw_pivot_points(lows_order_1);
        }
    }

    static void get_pivot_points(
        PivotPoint& dest[], PivotType type, PivotOrder order) {

        ArrayUtils::clear(dest);
        bool highs = (type == PIVOT_TYPE_HIGH);

        if (highs)
            ArrayUtils::copy(dest, highs_order_1);
        else
            ArrayUtils::copy(dest, lows_order_1);
    }

    static void get_pivot_points(
        PivotPoint& dest[], PivotType type, PivotOrder order, int start_index) {

        ArrayUtils::clear(dest);

        PivotPoint pivots[];
        get_pivot_points(pivots, type, order);

        for (int i = 0; i < ArraySize(pivots); i++)
            if (pivots[i].rate_index <= start_index)
                ArrayUtils::add_item(dest, pivots[i]);
    }

    static void get_pivot_points(
        PivotPoint& dest[], PivotType type, PivotOrder order, int start_index, int amount) {

        ArrayUtils::clear(dest);

        PivotPoint pivots[];
        get_pivot_points(pivots, type, order, start_index);

        ArrayCopy(dest, pivots, 0, 0, amount);
    }

    static void get_previous_pivot(PivotPoint& dest, PivotPoint& ref) {

        PivotPoint pivots[];
        get_pivot_points(pivots, ref.type, ref.order);

        for (int i = 0; i < ArraySize(pivots); i++) {
            if (pivots[i].rate_index <= ref.rate_index)
                break;
            else
                dest = pivots[i];
        }
    }

    static void get_previous_opposite_pivot(PivotPoint& dest, PivotPoint& ref) {
        PivotType opposite_type = get_opposite_pivot_type(ref);

        PivotPoint temp;
        ref.clone(temp);
        temp.type = opposite_type;

        get_previous_pivot(dest, temp);
    }

    static void get_previous_pivot_with_same_opposite(
        PivotPoint& dest, PivotPoint& ref,
        TrendType trend_type, int max_iterations) {

        dest.clear();

        PivotPoint ref_pivot, ref_opposite;
        ref.clone(ref_pivot);
        get_next_opposite_pivot(ref_opposite, ref_pivot);

        if (!ref_pivot.is_valid() || !ref_opposite.is_valid())
            return;

        for (int i = 1; i <= max_iterations; i++) {

            PivotPoint previous_pivot;
            get_previous_pivot(previous_pivot, ref_pivot);

            if (!previous_pivot.is_valid())
                break;

            PivotPoint previous_opposite;
            get_next_opposite_pivot(previous_opposite, previous_pivot);

            if (!previous_opposite.is_valid() || !previous_opposite.is_equal(ref_opposite))
                break;

            double ref_price = MarketPivot::get_pivot_price(ref_pivot, true);
            double previous_price = MarketPivot::get_pivot_price(previous_pivot, true);

            if (trend_type == TREND_BULLISH && (previous_price > ref_price))
                break;

            if (trend_type == TREND_BEARISH && (previous_price < ref_price))
                break;

            dest = previous_pivot;
            dest.clone(ref_pivot);
        }
    }

    static void get_next_pivot(PivotPoint& dest, PivotPoint& ref) {

        PivotPoint pivots[];
        get_pivot_points(pivots, ref.type, ref.order);

        for (int i = 0; i < ArraySize(pivots); i++) {
            if (pivots[i].rate_index < ref.rate_index) {
                dest = pivots[i];
                break;
            }
        }
    }

    static void get_next_opposite_pivot(PivotPoint& dest, PivotPoint& ref) {
        PivotType opposite_type = get_opposite_pivot_type(ref);

        PivotPoint temp;
        ref.clone(temp);
        temp.type = opposite_type;

        get_next_pivot(dest, temp);
    }

    static void get_next_pivot_with_same_opposite(
        PivotPoint& dest, PivotPoint& ref,
        TrendType trend_type, int max_iterations) {

        dest.clear();

        PivotPoint ref_pivot, ref_opposite;
        ref.clone(ref_pivot);
        get_previous_opposite_pivot(ref_opposite, ref_pivot);

        if (!ref_pivot.is_valid() || !ref_opposite.is_valid())
            return;

        for (int i = 1; i <= max_iterations; i++) {

            PivotPoint next_pivot;
            get_next_pivot(next_pivot, ref_pivot);

            if (!next_pivot.is_valid())
                break;

            PivotPoint next_opposite;
            get_previous_opposite_pivot(next_opposite, next_pivot);

            if (!next_opposite.is_valid() || !next_opposite.is_equal(ref_opposite))
                break;

            double ref_price = MarketPivot::get_pivot_price(ref_pivot, true);
            double next_price = MarketPivot::get_pivot_price(next_pivot, true);

            if (trend_type == TREND_BULLISH && (next_price < ref_price))
                break;

            if (trend_type == TREND_BEARISH && (next_price > ref_price))
                break;

            dest = next_pivot;
            dest.clone(ref_pivot);
        }
    }

    static PivotType get_opposite_pivot_type(PivotPoint& reference) {
        return (reference.type == PIVOT_TYPE_HIGH) ? PIVOT_TYPE_LOW : PIVOT_TYPE_HIGH;
    }

    static PivotType get_pivot_type_from_trend_type(TrendType trend_type) {
        return (trend_type == TREND_BEARISH) ? PIVOT_TYPE_HIGH : PIVOT_TYPE_LOW;
    }

    static double get_pivot_price(PivotPoint& pivot, bool wick) {
        if (pivot.type == PIVOT_TYPE_HIGH)
            return RatesUtils::get_rate_highest_price(pivot.rate_index, wick);
        else
            return RatesUtils::get_rate_lowest_price(pivot.rate_index, wick);
    }
};

static PivotPoint MarketPivot::highs_order_1[];
static PivotPoint MarketPivot::lows_order_1[];
static string MarketPivot::chart_pivot_names[];
