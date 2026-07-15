#include "../../../include/utils/LogUtils.mqh"

class TrendFollow : public NewRateBased {

  public:
    TrendFollow(AdvisorArgs& advisor_args_data) {
        this.args = advisor_args_data.trend_follow;
        this.visual_mode = advisor_args_data.visual_mode;
        this.log_file = advisor_args_data.log_file;
    }

    void on_init() {
        process_new_rate();
    }

    void on_tick() override {
        process_new_tick();
    }

    void on_trading_time_change(bool trading_time) override {
        process_trading_time_change(trading_time);
    }

  private:
    TrendFollowArgs args;
    bool visual_mode;
    bool log_file;

    void log(string message) {
        if (this.log_file)
            LogUtils::log(this.advisor_id, message);
        Print(message);
    }

    void process_trading_time_change(bool trading_time) {
        if (trading_time) {
            process_new_rate();
        } else {
            delete_market_analysis();
            close_open_positions();
        }
    }

    void close_open_positions() {
        MarketOrder::close_open_positions(this.ctrade, this.magic_number);
    }

    void process_new_tick() {

        if (has_open_positions()) {
            apply_breakeven();
            return;
        }

        if (!is_new_rate())
            return;

        process_new_rate();
    }

    bool has_open_positions() {
        return MarketOrder::has_open_positions(this.magic_number);
    }

    void apply_breakeven() {

        if (args.breakeven_value <= 0.0)
            return;

        for (int i = PositionsTotal() - 1; i >= 0; i--) {

            ulong ticket = PositionGetTicket(i);
            if (!PositionSelectByTicket(ticket))
                continue;

            if (PositionGetString(POSITION_SYMBOL) != _Symbol)
                continue;

            double entry = PositionGetDouble(POSITION_PRICE_OPEN);
            double sl = PositionGetDouble(POSITION_SL);
            double tp = PositionGetDouble(POSITION_TP);
            ENUM_POSITION_TYPE type =
                (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

            if (sl == 0.0)
                continue;

            // Already at breakeven or better
            if (type == POSITION_TYPE_BUY && sl >= entry)
                continue;
            if (type == POSITION_TYPE_SELL && sl <= entry)
                continue;

            double risk = MathAbs(entry - sl);
            double trigger_distance = risk * args.breakeven_value;

            double current_price;
            bool triggered = false;

            if (type == POSITION_TYPE_BUY) {
                current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                triggered = (current_price >= entry + trigger_distance);

            } else if (type == POSITION_TYPE_SELL) {
                current_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                triggered = (current_price <= entry - trigger_distance);
            }

            if (!triggered)
                continue;

            this.ctrade.PositionModify(ticket, entry, tp);
        }
    }

    void process_new_rate() {

        log("_____ Processing new rate _____");

        if (has_open_positions()) {
            log("It has open positions");
            return;
        }

        delete_market_analysis();

        if (has_reached_limits()) {
            log("It has reached limits");
            return;
        }

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

        if (this.visual_mode)
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
            args.analysis_shift_minutes,
            args.analysis_lowest_index,
            this.visual_mode); // TODO check access

        // Pivot Points
        MarketPivot::set_pivot_points(
            args.analysis_lowest_index,
            this.visual_mode); // TODO check access

        // Market Structure
        MarketStructure::set_market_structure(
            args.analysis_lowest_index,
            this.visual_mode); // TODO check access
    }

    void get_latest_valid_block(StructureBlock& dest) {
        dest.clear();

        StructureBlock blocks[];
        MarketStructure::get_latest_blocks(blocks, args.structure_blocks_shift);

        if (!are_valid_blocks(blocks))
            return;

        ArrayUtils::get_last_item(dest, blocks);

        if ((args.structure_blocks_distance_max > 0) &&
            (dest.end.rate_index > args.structure_blocks_distance_max))
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

            if (args.structure_blocks_distance_max <= 0)
                continue;

            int blocks_distance = (blocks[i - 1].end.rate_index - block.start.rate_index);
            if (blocks_distance > args.structure_blocks_distance_max)
                return false;
        }

        return true;
    }

    bool has_valid_strength(StructureBlock& block) {

        double avg_range = RatesUtils::get_average_range(
            block.start.rate_index, block.end.rate_index);
        double range_strength = avg_range * args.structure_blocks_strength_min;

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

        double size_min = NormalizeDouble((avg_size * args.breakout_size_factor_min), 1);
        double size_max = NormalizeDouble((avg_size * args.breakout_size_factor_max), 1);

        double break_size = NormalizeDouble(
            RatesUtils::get_rate_size(args.breakout_rate_index), 1);

        string msg_size_log = StringFormat(
            "Size min-max: [%s - %s] | Break size: %s",
            DoubleToString(size_min, _Digits),
            DoubleToString(size_max, _Digits),
            DoubleToString(break_size, _Digits));
        log(msg_size_log);

        return (break_size >= size_min) && (break_size <= size_max);
    }

    bool has_valid_breakout_volume(Zone& zone) {
        if (!args.breakout_volume_check)
            return true;

        double breakout_volume = get_rate_volume(args.breakout_rate_index);
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

        int rate_index = args.breakout_rate_index;

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

        double delta = args.breakout_delta_check ? zone.treshold : 0.0;
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
            market_bias, entry, sl, args.risk_reward_ratio);
        double lot_size = get_lot_size(entry, sl, args.risk_percentage);

        if (entry == 0.0 || sl == 0.0 || tp == 0.0 || lot_size == 0.0)
            return;

        string comment = (market_bias == TREND_BULLISH) ? "TRADE Buy" : "TRADE Sell";

        string msg_trade_log = StringFormat(
            "%s | Entry: %s | SL: %s | TP: %s | Lots: %s",
            comment,
            DoubleToString(entry, _Digits),
            DoubleToString(sl, _Digits),
            DoubleToString(tp, _Digits),
            DoubleToString(lot_size, _Digits));
        log(msg_trade_log);

        ENUM_ORDER_TYPE order =
            (market_bias == TREND_BULLISH)
                ? ORDER_TYPE_BUY
                : ORDER_TYPE_SELL;

        ulong ticket = market_order(order, lot_size, _Symbol, entry, sl, 0.0, comment);

        if (ticket == 0) {
            log("Error placing order");
            return;
        }

        if (!update_tp(order, ticket)) {
            log("Error updating trade TP: " + IntegerToString(ticket));
            return;
        }

        /*
        if (market_bias == TREND_BULLISH)
            ctrade.Buy(lot_size, _Symbol, entry, sl, tp, comment);

        else if (market_bias == TREND_BEARISH)
            ctrade.Sell(lot_size, _Symbol, entry, sl, tp, comment);
        */
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

    // TODO: consider lot_size based on risk factor, if is over it, discard the trade
    // if min lot size is over the risk factor, consider not trading
    double get_lot_size(double entry, double sl, double risk_percentage) {
        if (entry <= 0.0 || sl <= 0.0 || risk_percentage <= 0.0)
            return 0.0;

        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double risk_amount = balance * (risk_percentage / 100.0);

        double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

        double volume_min = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
        double volume_max = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
        double volume_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

        double price_distance = MathAbs(entry - sl);

        if (price_distance <= 0 || tick_value <= 0 || tick_size <= 0)
            return 0.0;

        double ticks = price_distance / tick_size;
        double loss_per_lot = ticks * tick_value;

        double lot_size = risk_amount / loss_per_lot;
        lot_size = MathFloor(lot_size / volume_step) * volume_step;
        lot_size = MathMax(
            volume_min, MathMin(volume_max, lot_size));

        return NormalizeDouble(lot_size, 2);
    }

    bool update_tp(ENUM_ORDER_TYPE order_type, ulong ticket) {

        if (!PositionSelectByTicket(ticket))
            return false;

        double entry_price = PositionGetDouble(POSITION_PRICE_OPEN);
        double stop_loss = PositionGetDouble(POSITION_SL);
        double risk_reward_ratio = this.args.risk_reward_ratio;

        double tp = MarketOrder::calculate_take_profit_price(
            order_type, entry_price, stop_loss, risk_reward_ratio);

        return set_position(ticket, stop_loss, tp);
    }

    bool has_reached_daily_limit() {

        if (args.daily_limit_losses == 0 && args.daily_limit_wins == 0)
            return false;

        datetime today_init = MarketSession::get_today_init_time();
        datetime today_end = MarketSession::get_today_end_time();

        HistorySelect(today_init, today_end);

        int today_deals = HistoryDealsTotal();
        int today_losses = 0;
        int today_wins = 0;

        for (int i = 0; i <= today_deals; i++) {

            ulong deal_ticket = HistoryDealGetTicket(i);
            if (deal_ticket == 0)
                continue;

            ENUM_DEAL_TYPE deal_type = (ENUM_DEAL_TYPE)HistoryDealGetInteger(deal_ticket, DEAL_TYPE);
            if ((deal_type != DEAL_TYPE_BUY) && (deal_type != DEAL_TYPE_SELL))
                continue;

            double deal_profit = HistoryDealGetDouble(deal_ticket, DEAL_PROFIT);

            string msg_deal_log = StringFormat(
                "Deal: %s | Ticket: %s | Profit: %s",
                IntegerToString(i),
                IntegerToString(deal_ticket),
                DoubleToString(deal_profit, _Digits));
            log(msg_deal_log);

            if (deal_profit < 0)
                today_losses++;

            if (deal_profit > 0)
                today_wins++;
        }

        string msg_total_log = StringFormat(
            "Deals today: %s | Wins: %s | Losses: %s",
            IntegerToString(today_deals),
            IntegerToString(today_wins),
            IntegerToString(today_losses));
        log(msg_total_log);

        if (args.daily_limit_losses > 0 && (today_losses >= args.daily_limit_losses))
            return true;

        if (args.daily_limit_wins > 0 && (today_wins >= args.daily_limit_wins))
            return true;

        return false;
    }

    bool has_reached_monthly_win_limit() {

        if (args.monthly_limit_percentage <= 0.0)
            return false;

        double month_profit = MarketOrder::get_month_profit();

        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double profit_percentage = (month_profit / balance) * 100.0;

        return profit_percentage >= args.monthly_limit_percentage;
    }

    bool has_reached_limits() {
        return has_reached_daily_limit() || has_reached_monthly_win_limit();
    }
};
