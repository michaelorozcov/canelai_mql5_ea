class MarketStructure {
  private:
    static string chart_block_names[];
    static StructureBlock structure_blocks_impulses[];

    static void delete_chart_structure_blocks() {
        for (int i = 0; i < ArraySize(chart_block_names); i++)
            ChartUtils::delete_chart_object(chart_block_names[i]);
        ArrayUtils::clear(chart_block_names);
    }

    static color get_block_color(StructureBlock& block) {
        return block.is_bullish() ? TREND_BULLISH_COLOR : TREND_BEARISH_COLOR;
    }

    static void draw_structure_block(StructureBlock& block) {

        string block_name = "block_" + IntegerToString(block.start.rate_index);

        ChartUtils::create_chart_object(
            OBJ_RECTANGLE,
            block_name,
            RatesUtils::get_rate_time(block.start.rate_index),
            MarketPivot::get_pivot_price(block.start, true),
            RatesUtils::get_rate_time(block.end.rate_index),
            MarketPivot::get_pivot_price(block.end, true));

        ObjectSetInteger(
            0, block_name, OBJPROP_COLOR, get_block_color(block));
        ObjectSetInteger(0, block_name, OBJPROP_FILL, true);

        ArrayUtils::add_item(chart_block_names, block_name);
    }

    static void draw_structure_blocks() {
        for (int i = 0; i < ArraySize(structure_blocks_impulses); i++)
            draw_structure_block(structure_blocks_impulses[i]);
    }

    static double get_structure_threshold(PivotPoint& start, PivotPoint& end) {
        double avg_range = RatesUtils::get_average_range(
            start.rate_index, end.rate_index);
        return (avg_range * STRUCTURE_BREAKOUT_THRESHOLD_FACTOR);
    }

    static void get_init_block(StructureBlock& init_block, Trend& init_trend) {

        init_block.start = init_trend.start;
        MarketPivot::get_next_opposite_pivot(init_block.end, init_block.start);

        PivotPoint merged_opposite;
        MarketPivot::get_next_pivot_with_same_opposite(
            merged_opposite, init_block.end,
            init_trend.type, STRUCTURE_MAX_PIVOTS_ANALYSIS);

        if (merged_opposite.is_valid())
            init_block.end = merged_opposite;
    }

    static void get_block_from_breakout(
        StructureBlock& block, BlockBreakout& breakout) {

        block.end = breakout.pivot;
        MarketPivot::get_previous_opposite_pivot(block.start, block.end);

        PivotPoint merged_opposite;
        MarketPivot::get_previous_pivot_with_same_opposite(
            merged_opposite, block.start,
            breakout.bias, STRUCTURE_MAX_PIVOTS_ANALYSIS);

        if (merged_opposite.is_valid())
            block.start = merged_opposite;
    }

    static void set_block_breakout(StructureBlock& block) {

        BlockBreakout ceil_breakout, bottom_breakout;
        get_ceil_breakout(ceil_breakout, block);
        get_bottom_breakout(bottom_breakout, block);

        bool ceil = ceil_breakout.is_valid();
        bool bottom = bottom_breakout.is_valid();

        if (!ceil && !bottom)
            return;

        else if (ceil && bottom)
            block.breakout = (bottom_breakout.pivot.rate_index > ceil_breakout.pivot.rate_index)
                                 ? bottom_breakout
                                 : ceil_breakout;

        else if (ceil && !bottom)
            block.breakout = ceil_breakout;

        else if (!ceil && bottom)
            block.breakout = bottom_breakout;
    }

    static void get_ceil_breakout(BlockBreakout& breakout, StructureBlock& block) {

        PivotPoint ref = block.is_bullish() ? block.end : block.start;

        PivotPoint pivots[];
        MarketPivot::get_pivot_points(
            pivots, ref.type, ref.order, ref.rate_index, STRUCTURE_MAX_PIVOTS_ANALYSIS);

        for (int i = 0; i < ArraySize(pivots); i++) {

            if (pivots[i].rate_index >= ref.rate_index)
                continue;

            double block_price = MarketPivot::get_pivot_price(ref, true);
            double pivot_price = MarketPivot::get_pivot_price(pivots[i], false);

            if (pivot_price <= block_price)
                continue;

            double threshold = get_structure_threshold(ref, pivots[i]);
            if (MathAbs(pivot_price - block_price) < threshold)
                continue;

            breakout.bias = TREND_BULLISH;
            breakout.pivot = pivots[i];

            PivotPoint next_pivot;
            MarketPivot::get_next_pivot_with_same_opposite(
                next_pivot, breakout.pivot, breakout.bias,
                STRUCTURE_MAX_PIVOTS_ANALYSIS);

            if (!next_pivot.is_valid())
                break;

            double next_price = MarketPivot::get_pivot_price(next_pivot, true);
            if (next_price >= pivot_price)
                breakout.pivot = next_pivot;

            break;
        }
    }

    static void get_bottom_breakout(BlockBreakout& breakout, StructureBlock& block) {

        PivotPoint ref = block.is_bullish() ? block.start : block.end;

        PivotPoint pivots[];
        MarketPivot::get_pivot_points(
            pivots, ref.type, ref.order, ref.rate_index, STRUCTURE_MAX_PIVOTS_ANALYSIS);

        for (int i = 0; i < ArraySize(pivots); i++) {

            if (pivots[i].rate_index >= ref.rate_index)
                continue;

            double block_price = MarketPivot::get_pivot_price(ref, true);
            double pivot_price = MarketPivot::get_pivot_price(pivots[i], false);

            if (pivot_price >= block_price)
                continue;

            double threshold = get_structure_threshold(ref, pivots[i]);
            if (MathAbs(block_price - pivot_price) < threshold)
                continue;

            breakout.bias = TREND_BEARISH;
            breakout.pivot = pivots[i];

            PivotPoint next_pivot;
            MarketPivot::get_next_pivot_with_same_opposite(
                next_pivot, breakout.pivot, breakout.bias,
                STRUCTURE_MAX_PIVOTS_ANALYSIS);

            if (!next_pivot.is_valid())
                break;

            double next_price = MarketPivot::get_pivot_price(next_pivot, true);
            if (next_price <= pivot_price)
                breakout.pivot = next_pivot;

            break;
        }
    }

    static void get_init_trend(Trend& init_trend, AdvisorArgs& data) {
        MarketTrend::get_init_trend(init_trend);

        if (data.visual_mode)
            MarketTrend::draw_trend(init_trend);
    }

  public:
    static void delete_market_structure() {
        delete_chart_structure_blocks();
        ArrayUtils::clear(structure_blocks_impulses);
    }

    static void set_market_structure(AdvisorArgs& data) {

        Trend init_trend;
        get_init_trend(init_trend, data);

        if (!init_trend.is_valid())
            return;

        StructureBlock init_block;
        get_init_block(init_block, init_trend);
        set_block_breakout(init_block);
        ArrayUtils::add_item(structure_blocks_impulses, init_block);

        if (!init_block.is_valid())
            return;

        StructureBlock previous_impulse = init_block;

        for (int i = 1; i <= STRUCTURE_MAX_PIVOTS_ANALYSIS; i++) {

            if (!previous_impulse.is_valid() || !previous_impulse.breakout.is_valid())
                break;

            StructureBlock new_impulse;
            get_block_from_breakout(new_impulse, previous_impulse.breakout);
            set_block_breakout(new_impulse);

            if (!new_impulse.is_valid())
                break;

            ArrayUtils::add_item(structure_blocks_impulses, new_impulse);

            previous_impulse = new_impulse;
        }

        if (data.visual_mode)
            draw_structure_blocks();
    }

    static void get_latest_blocks(StructureBlock& dest[], int amount) {

        if (amount > ArraySize(structure_blocks_impulses))
            return;

        int start = ArraySize(structure_blocks_impulses) - amount;
        ArrayCopy(dest, structure_blocks_impulses, 0, start, amount);
    }

    static double get_block_strength(StructureBlock& block) {
        if (!block.is_valid())
            return 0.0;

        double start = MarketPivot::get_pivot_price(block.start, true);
        double end = MarketPivot::get_pivot_price(block.end, true);

        return MathAbs(start - end);
    }
};

static string MarketStructure::chart_block_names[];
static StructureBlock MarketStructure::structure_blocks_impulses[];
