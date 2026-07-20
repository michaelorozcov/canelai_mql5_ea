#include "./../../../include/strategy/NewRateBased.mqh"

#include "./../../../include/dto/Structure.mqh"
#include "./../../../include/dto/Trend.mqh"
#include "./../../../include/dto/Zone.mqh"

#include "./../../../include/dto/args_input/strategy/TrendFollowArgs.mqh"

#include "./../../../include/utils/ArrayUtils.mqh"
#include "./../../../include/utils/RatesUtils.mqh"

#include "./../../../include/market/MarketOrder.mqh"
#include "./../../../include/market/MarketPivot.mqh"
#include "./../../../include/market/MarketStructure.mqh"
#include "./../../../include/market/MarketZone.mqh"

class TrendFollow : public NewRateBased {

  public:
    TrendFollow(AdvisorArgs& param_args, string param_advisor_id)
        : NewRateBased(param_args, param_advisor_id) {
        // Empty body
    }

    void on_init() override {
        process_new_rate();
    }

    void on_tick() override {
        process_new_tick();
    }

    void on_trading_time_change(bool trading_time) override {
        process_trading_time_change(trading_time);
    }

  private:
    void process_trading_time_change(bool trading_time) {
        if (trading_time) {
            process_new_rate();
        } else {
            delete_market_analysis();
            close_open_positions();
        }
    }

    void process_new_tick() {

        if (has_open_positions()) {
            return;
        }

        if (!is_new_rate())
            return;

        process_new_rate();
    }

    void process_new_rate() {

        log("_____ Processing new rate _____");

        if (has_open_positions()) {
            log("It has open positions");
            return;
        }

        delete_market_analysis();
        set_market_analysis();

        StructureBlock last_block;
        get_latest_valid_block(last_block);
        if (!last_block.is_valid()) {
            log("Last_block not valid");
            return;
        }

        bool upheld_block = is_upheld_block(last_block);
        if (!upheld_block) {
            log("Last block limit not upheld");
            return;
        }

        Zone zone;
        MarketZone::get_zone_from_block(
            zone, last_block, false, TF_ANALYSIS_LOWEST_INDEX);

        bool upheld_zone = is_upheld_zone(zone);
        if (!upheld_zone) {
            log("Zone limit not upheld");
            return;
        }

        if (this.args.general.visual_mode)
            MarketZone::draw_zone(zone, TF_ANALYSIS_LOWEST_INDEX);

        bool valid_breakout = is_valid_breakout(zone, last_block);
        if (!valid_breakout) {
            log("Breakout not valid");
            return;
        }

        log("Proceed to trade");
        make_trade(last_block, zone);
    }

    void delete_market_analysis() {
        RatesUtils::delete_rates();
        MarketPivot::delete_pivot_points();
        MarketStructure::delete_market_structure();
        MarketZone::delete_zones();
    }

    void set_market_analysis() {

        // Rates
        RatesUtils::set_rates(
            this.args.trend_follow.analysis_shift_minutes,
            this.args.trend_follow.analysis_lowest_index,
            this.args.general.visual_mode);

        // Pivot Points
        MarketPivot::set_pivot_points(
            this.args.trend_follow.analysis_lowest_index,
            this.args.general.visual_mode);

        // Market Structure
        MarketStructure::set_market_structure(
            this.args.trend_follow.analysis_lowest_index,
            this.args.general.visual_mode);
    }

    void get_latest_valid_block(StructureBlock& dest) {
        dest.clear();

        StructureBlock blocks[];
        MarketStructure::get_latest_blocks(blocks, this.args.trend_follow.structure_blocks_shift);

        if (!are_valid_blocks(blocks))
            return;

        ArrayUtils::get_last_item(dest, blocks);

        if ((this.args.trend_follow.structure_blocks_distance_max > 0) &&
            (dest.end.rate_index > this.args.trend_follow.structure_blocks_distance_max))
            dest.clear();
    }

    bool are_valid_blocks(StructureBlock& blocks[]) {
        if (ArraySize(blocks) == 0)
            return false;

        TrendType trend_type = blocks[0].get_trend_type();

        for (int i = 0; i < ArraySize(blocks); i++) {

            StructureBlock block = blocks[i];

            if (!block.is_valid())
                return false;

            if (block.get_trend_type() != trend_type)
                return false;

            if (!has_valid_strength(block))
                return false;

            if (i == 0)
                continue;

            if (this.args.trend_follow.structure_blocks_distance_max <= 0)
                continue;

            int blocks_distance = (blocks[i - 1].end.rate_index - block.start.rate_index);
            if (blocks_distance > this.args.trend_follow.structure_blocks_distance_max)
                return false;
        }

        return true;
    }

    bool has_valid_strength(StructureBlock& block) {

        double avg_range = RatesUtils::get_average_range(
            block.start.rate_index, block.end.rate_index);
        double range_strength = avg_range * this.args.trend_follow.structure_blocks_strength_min;

        double block_strength = MarketStructure::get_block_strength(block);

        return (block_strength >= range_strength);
    }

    bool is_upheld_block(StructureBlock& block) {
        return RatesUtils::is_respected_price(
            block.start.rate_index, TF_ANALYSIS_LOWEST_INDEX,
            MarketPivot::get_pivot_price(block.start, true),
            block.is_bearish(), false, 0);
    }

    double get_rate_volume(int rate_index) {
        return NormalizeDouble(RatesUtils::get_rate_volume(rate_index), 1);
    }

    double get_rates_average_volume(int start_index, int end_index) {
        return NormalizeDouble(RatesUtils::get_average_volume(start_index, end_index), 1);
    }

    bool is_upheld_zone(Zone& zone) {
        bool resistance = zone.type == RESISTANCE;
        return RatesUtils::is_respected_price(
            zone.rate_index, TF_ANALYSIS_LOWEST_INDEX,
            resistance ? zone.get_top_price() : zone.get_bottom_price(),
            resistance, false, zone.treshold);
    }

    bool has_valid_breakout_size(Zone& zone) {

        double avg_size_raw = RatesUtils::get_average_size(
            zone.rate_index, TF_ANALYSIS_LOWEST_INDEX);
        double avg_size = NormalizeDouble(avg_size_raw, 1);

        double size_min = NormalizeDouble((avg_size * this.args.trend_follow.breakout_size_factor_min), 1);
        double size_max = NormalizeDouble((avg_size * this.args.trend_follow.breakout_size_factor_max), 1);

        double break_size = NormalizeDouble(
            RatesUtils::get_rate_size(this.args.trend_follow.breakout_rate_index), 1);

        string msg_size_log = StringFormat(
            "Size min-max: [%s - %s] | Break size: %s",
            DoubleToString(size_min, _Digits),
            DoubleToString(size_max, _Digits),
            DoubleToString(break_size, _Digits));
        log(msg_size_log);

        return (break_size >= size_min) && (break_size <= size_max);
    }

    bool has_valid_breakout_volume(Zone& zone) {
        if (!this.args.trend_follow.breakout_volume_check)
            return true;

        double breakout_volume = get_rate_volume(this.args.trend_follow.breakout_rate_index);
        double zone_volume = get_rates_average_volume(
            zone.rate_index, TF_ANALYSIS_LOWEST_INDEX);

        string msg_volume_log = StringFormat(
            "Zone Vol: %s | Break Vol: %s",
            DoubleToString(zone_volume, _Digits),
            DoubleToString(breakout_volume, _Digits));
        log(msg_volume_log);

        return (breakout_volume >= zone_volume);
    }

    bool is_valid_breakout(Zone& zone, StructureBlock& block) {

        int rate_index = this.args.trend_follow.breakout_rate_index;

        datetime breakout_time = RatesUtils::get_rate_time(rate_index);
        datetime current_time = TimeGMT();
        int diff_minutes = (int)((current_time - breakout_time) / 60);
        int shift_rates = RatesUtils::get_shift_rates(diff_minutes);

        if (shift_rates != rate_index) {
            string msg_index_log = StringFormat(
                "Breakout index not consistent: shift_rates %s | rate_index %s",
                IntegerToString(shift_rates),
                IntegerToString(rate_index));
            log(msg_index_log);
            return false;
        }

        double delta = this.args.trend_follow.breakout_delta_check ? zone.treshold : 0.0;
        bool broken_zone = MarketZone::is_broken_by_rate(zone, rate_index, delta);
        if (!broken_zone) {
            string msg_delta_log = StringFormat(
                "Breakout does not break zone: delta %s | zone [%s - %s]",
                DoubleToString(delta, _Digits),
                DoubleToString(zone.get_top_price(), _Digits),
                DoubleToString(zone.get_bottom_price(), _Digits));
            log(msg_delta_log);
            return false;
        }

        if (!has_valid_breakout_size(zone))
            return false;

        if (!has_valid_breakout_volume(zone))
            return false;

        return true;
    }

    void make_trade(StructureBlock& block, Zone& zone) {

        TrendType market_bias = block.get_trend_type();

        double entry = get_entry_price(market_bias);
        double sl = get_stop_loss_price(market_bias, zone);
        double tp = get_take_profit_price(
            market_bias, entry, sl, this.args.risk.reward_ratio);
        double lot_size = calculate_position_volume(entry, sl);

        string comment = (market_bias == TREND_BULLISH) ? "TRADE Buy" : "TRADE Sell";

        log(StringFormat(
            "%s | Entry: %s | SL: %s | TP: %s | Lots: %s",
            comment,
            DoubleToString(entry, _Digits),
            DoubleToString(sl, _Digits),
            DoubleToString(tp, _Digits),
            DoubleToString(lot_size, _Digits)));

        if (entry == 0.0 || sl == 0.0 || tp == 0.0 || lot_size == 0.0) {
            log("Error with trade values");
            return;
        }

        ENUM_ORDER_TYPE order =
            (market_bias == TREND_BULLISH)
                ? ORDER_TYPE_BUY
                : ORDER_TYPE_SELL;
        double reward_ratio = this.args.risk.reward_ratio;

        market_order_delayed_tp(
            order, lot_size, _Symbol, entry, sl, reward_ratio, comment);
    }

    double get_entry_price(TrendType market_bias) {

        if (market_bias == TREND_BULLISH)
            return SymbolInfoDouble(_Symbol, SYMBOL_ASK);

        else if (market_bias == TREND_BEARISH)
            return SymbolInfoDouble(_Symbol, SYMBOL_BID);

        return 0.0;
    }

    // TODO: consider SL based on risk factor, if is over it, discard the trade
    double get_stop_loss_price(TrendType market_bias, Zone& zone) {
        bool bullish_entry = (market_bias == TREND_BULLISH);
        double factor = bullish_entry ? -1.0 : 1.0;
        double zone_margin = MathAbs(zone.get_top_price() - zone.get_bottom_price());
        double zone_ref = bullish_entry ? zone.get_bottom_price() : zone.get_top_price();
        double sl = (zone_ref + (factor * zone_margin));
        return NormalizeDouble(sl, _Digits);
    }

    double get_take_profit_price(
        TrendType market_bias, double entry, double sl, double risk_reward_ratio) {

        if (entry == 0.0 || sl == 0.0)
            return 0.0;

        double distance = MathAbs(entry - sl);
        double tp_distance = distance * risk_reward_ratio;

        double tp = 0.0;

        if (market_bias == TREND_BULLISH)
            tp = entry + tp_distance;

        else if (market_bias == TREND_BEARISH)
            tp = entry - tp_distance;

        return NormalizeDouble(tp, _Digits);
    }
};
