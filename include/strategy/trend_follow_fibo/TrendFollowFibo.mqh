#include "./../../../include/dto/args_input/general/FiboLevels.mqh"
#include "./../../../include/strategy/NewRateBased.mqh"

const string ENTRY_PRICE_TEXT = "ENTRY_PRICE";
const string SL_PRICE_TEXT = "SL_PRICE";
const string TP_PRICE_TEXT = "TP_PRICE";

struct BlockData {
    TrendType type;
    datetime start_time;
    datetime end_time;

    BlockData() {
        this.type = TREND_RANGING;
        this.start_time = 0;
        this.end_time = 0;
    }
};

class TrendFollowFibo : public NewRateBased {

  public:
    TrendFollowFibo(AdvisorArgs& param_args, string param_advisor_id)
        : NewRateBased(param_args, param_advisor_id) {
        // Empty body
        this.pending_order_ticket = 0;
    }

    void on_new_rate() override {
        process_new_rate();
    }

    void on_trading_time_change(bool trading_time) override {
        process_trading_time_change(trading_time);
    }

  private:
    ulong pending_order_ticket;
    BlockData block_data;

    void process_new_rate() {

        delete_market_analysis();
        set_market_analysis();

        StructureBlock latest_block;
        get_latest_block(latest_block);

        if (!latest_block.is_valid()) {
            log("Not valid last block");
            return;
        }

        check_trigger_conditions(latest_block);
        draw_fibo_levels(latest_block);
    }

    void delete_market_analysis() {
        RatesUtils::delete_rates();
        MarketPivot::delete_pivot_points();
        MarketStructure::delete_market_structure();

        ChartUtils::delete_chart_object(ENTRY_PRICE_TEXT);
        ChartUtils::delete_chart_object(SL_PRICE_TEXT);
        ChartUtils::delete_chart_object(TP_PRICE_TEXT);
    }

    void set_market_analysis() {
        RatesUtils::set_rates(
            this.args.trend_follow_fibo.analysis_shift_minutes,
            this.args.trend_follow_fibo.analysis_lowest_index,
            this.args.general.visual_mode);
        MarketPivot::set_pivot_points(
            this.args.trend_follow_fibo.analysis_lowest_index,
            this.args.general.visual_mode);
        MarketStructure::set_market_structure(
            this.args.trend_follow_fibo.analysis_lowest_index,
            this.args.general.visual_mode);
    }

    void get_latest_block(StructureBlock& dest) {
        dest.clear();

        StructureBlock blocks[];
        MarketStructure::get_latest_blocks(blocks, 1);

        if (ArraySize(blocks) > 0) {
            dest = blocks[0];
        }
    }

    void draw_fibo_levels(StructureBlock& block) {

        if (!this.args.general.visual_mode)
            return;

        PivotPoint start_pivot = block.start;
        int start_index = start_pivot.rate_index;
        datetime start_time = RatesUtils::get_rate_time(start_index);
        double start_price = MarketPivot::get_pivot_price(start_pivot, true);

        PivotPoint end_pivot = block.end;
        int end_index = end_pivot.rate_index;
        datetime end_time = RatesUtils::get_rate_time(end_index);
        double end_price = MarketPivot::get_pivot_price(end_pivot, true);

        string fibo_name = "fibo_name";
        int fibo_levels = ArraySize(FIBO_LEVELS);

        ChartUtils::create_chart_object(
            OBJ_FIBO, fibo_name,
            start_time, start_price,
            end_time, end_price);

        ObjectSetInteger(
            0, fibo_name,
            OBJPROP_LEVELS, fibo_levels);

        for (int i = 0; i < fibo_levels; i++) {

            double level_value = get_fibo_value(FIBO_LEVELS[i]);
            string level_text = DoubleToString((level_value * 100), 1);

            ObjectSetDouble(
                0, fibo_name,
                OBJPROP_LEVELVALUE, i, level_value);

            ObjectSetString(
                0, fibo_name,
                OBJPROP_LEVELTEXT, i, level_text);
        }
    }

    void check_trigger_conditions(StructureBlock& block) {

        bool pending_order = has_pending_orders();
        bool block_valid = are_block_limits_valid(block);
        bool block_traded = has_been_traded(block);
        bool block_merged = is_merged_block(block);

        // Order creation
        if (!pending_order && block_valid && !block_traded) {
            set_trigger_conditions(block);
            return;
        }

        // Order update
        if (pending_order && block_valid && block_merged) {
            log(StringFormat(
                "Merged block, cancelling pending order # %s",
                IntegerToString(this.pending_order_ticket)));
            delete_pending_order(this.pending_order_ticket);
            set_trigger_conditions(block);
            return;
        }

        // Order delete
        if (pending_order && !block_valid) {
            log(StringFormat(
                "Broken Limits, cancelling pending order # %s",
                IntegerToString(this.pending_order_ticket)));
            delete_pending_order(this.pending_order_ticket);
            return;
        }
    }

    void set_trigger_conditions(StructureBlock& block) {

        this.block_data.type = block.get_trend_type();
        this.block_data.start_time = RatesUtils::get_rate_time(block.start.rate_index);
        this.block_data.end_time = RatesUtils::get_rate_time(block.end.rate_index);

        ENUM_ORDER_TYPE order_type = block.is_bullish() ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

        double trigger_level = get_fibo_value(this.args.trend_follow_fibo.entry_level);
        double trigger_price = get_price_level(block, trigger_level);

        double sl_level = get_fibo_value(this.args.trend_follow_fibo.sl_level);
        double sl_price = get_price_level(block, sl_level);

        double tp_level = get_fibo_value(this.args.trend_follow_fibo.tp_level);
        double tp_price = get_price_level(block, tp_level);

        double volume = calculate_position_volume(trigger_price, sl_price);

        if ((trigger_price <= 0) || (sl_price <= 0) || (tp_price <= 0) || (volume <= 0)) {
            log(StringFormat(
                "Error with pending order values: Price %s SL %s TP %s VOL %s",
                DoubleToString(trigger_price, _Digits),
                DoubleToString(sl_price, _Digits),
                DoubleToString(tp_price, _Digits),
                DoubleToString(volume, _Digits))
                //
            );
            return;
        }

        double allowed_sl = calculate_risked_amount();
        if (allowed_sl > 0) {
            double order_sl = MathAbs(
                calculate_order_stop_loss(order_type, volume, trigger_price, sl_price));

            if (order_sl > (allowed_sl * 1.5)) {
                log(StringFormat(
                    "Error SL amount, Risked: %s > Expected: %s",
                    DoubleToString(order_sl, _Digits),
                    DoubleToString(allowed_sl, _Digits))
                    //
                );
                return;
            }
        }

        log(StringFormat(
            "Trade %s at %s SL %s TP %s VOL %s",
            EnumToString(order_type),
            DoubleToString(trigger_price, _Digits),
            DoubleToString(sl_price, _Digits),
            DoubleToString(tp_price, _Digits),
            DoubleToString(volume, _Digits))
            //
        );

        limit_order(order_type, volume, trigger_price, _Symbol,
                    sl_price, tp_price, ORDER_TIME_DAY);

        this.pending_order_ticket = get_last_pending_order();

        log(StringFormat(
            "%s, Ticket %s",
            ((this.pending_order_ticket > 0) ? "Success" : "Error"),
            IntegerToString(this.pending_order_ticket)));
    }

    double get_price_level(StructureBlock& block, double fibo_level) {

        double price_top = block.get_price_top();
        double price_bottom = block.get_price_bottom();

        double track_total = (MathAbs(price_top - price_bottom));
        double track_level = NormalizeDouble((track_total * fibo_level), _Digits);

        return block.is_bullish() ? (price_top - track_level) : (price_bottom + track_level);
    }

    bool are_block_limits_valid(StructureBlock& block) {

        int start = block.end.rate_index, end = 0;

        bool valid_top = RatesUtils::is_respected_price(
            start, end, block.get_price_top(),
            true, false, 0);

        bool valid_bottom = RatesUtils::is_respected_price(
            start, end, block.get_price_bottom(),
            false, false, 0);

        return (valid_top && valid_bottom);
    }

    bool has_been_traded(StructureBlock& block) {
        return is_same_block(block, true);
    }

    bool is_merged_block(StructureBlock& block) {
        return is_same_block(block, false);
    }

    bool is_same_block(StructureBlock& block, bool same_end_time) {

        TrendType type = block.get_trend_type();
        datetime start_time = RatesUtils::get_rate_time(block.start.rate_index);
        datetime end_time = RatesUtils::get_rate_time(block.end.rate_index);

        return ((this.block_data.type == type) &&
                (this.block_data.start_time == start_time)) &&
               (same_end_time
                    ? (this.block_data.end_time == end_time)
                    : (this.block_data.end_time != end_time));
    }

    void process_trading_time_change(bool trading_time) {
        if (!trading_time && has_pending_orders()) {
            log("Cancelling pending orders");
            delete_pending_orders();
        }
    }
};
