#include <Trade\Trade.mqh>

class TrendFollow {

  private:
    static TrendFollowArgs args;
    static bool visual_mode;

    static void get_latest_valid_block(StructureBlock& dest) {
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

    static bool are_valid_blocks(StructureBlock& blocks[]) {
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

    static bool has_valid_strength(StructureBlock& block) {

        double avg_range = RatesUtils::get_average_range(
            block.start.rate_index, block.end.rate_index);
        double range_strength = avg_range * args.structure_blocks_strength_min;

        double block_strength = MarketStructure::get_block_strength(block);

        return (block_strength >= range_strength);
    }

    static bool is_upheld_block(StructureBlock& block) {
        return RatesUtils::is_respected_price(
            block.start.rate_index, ANALYSIS_LIMIT_LOWEST_INDEX,
            MarketPivot::get_pivot_price(block.start, true),
            block.is_bearish(), false, 0);
    }

    static double get_rate_volume(int rate_index) {
        return NormalizeDouble(RatesUtils::get_rate_volume(rate_index), 1);
    }

    static double get_rates_average_volume(int start_index, int end_index) {
        return NormalizeDouble(RatesUtils::get_average_volume(start_index, end_index), 1);
    }

    static bool is_upheld_zone(Zone& zone) {
        bool resistance = zone.type == RESISTANCE;
        return RatesUtils::is_respected_price(
            zone.rate_index, ANALYSIS_LIMIT_LOWEST_INDEX,
            resistance ? zone.get_top_price() : zone.get_bottom_price(),
            resistance, false, zone.treshold);
    }

    static bool has_valid_breakout_size(Zone& zone) {

        double avg_size_raw = RatesUtils::get_average_size(
            zone.rate_index, ANALYSIS_LIMIT_LOWEST_INDEX);
        double avg_size = NormalizeDouble(avg_size_raw, 1);

        double size_min = NormalizeDouble((avg_size * args.breakout_size_factor_min), 1);
        double size_max = NormalizeDouble((avg_size * args.breakout_size_factor_max), 1);

        double break_size = NormalizeDouble(
            RatesUtils::get_rate_size(args.breakout_rate_index), 1);

        Print("---- break_size: ", break_size, " | size_min: ", size_min, " | size_max: ", size_max);

        return (break_size >= size_min) && (break_size <= size_max);
    }

    static bool has_valid_breakout_volume(Zone& zone) {
        if (!args.breakout_volume_check)
            return true;

        double breakout_volume = get_rate_volume(args.breakout_rate_index);
        double zone_volume = get_rates_average_volume(
            zone.rate_index, ANALYSIS_LIMIT_LOWEST_INDEX);

        Print("---- Break Vol: ", breakout_volume, " | Zone Vol: ", zone_volume);

        return (breakout_volume >= zone_volume);
    }

    static bool is_valid_breakout(Zone& zone, StructureBlock& block) {

        int rate_index = args.breakout_rate_index;
        double delta = args.breakout_delta_check ? zone.treshold : 0.0;

        bool broken_zone = MarketZone::is_broken_by_rate(zone, rate_index, delta);
        if (!broken_zone)
            return false;

        Print("------------------------------------");

        if (!has_valid_breakout_size(zone))
            return false;

        if (!has_valid_breakout_volume(zone))
            return false;

        return true;
    }

    static void make_trade(StructureBlock& block, Zone& zone) {

        TrendType market_bias = block.get_trend_type();

        double entry = get_entry_price(market_bias);
        double sl = get_stop_loss_price(market_bias, zone);
        double tp = get_take_profit_price(
            market_bias, entry, sl, args.risk_reward_ratio);
        double lot_size = get_lot_size(entry, sl, args.risk_percentage);

        if (entry == 0.0 || sl == 0.0 || tp == 0.0 || lot_size == 0.0)
            return;

        CTrade ctrade;
        string comment = (market_bias == TREND_BULLISH) ? "TRADE Buy" : "TRADE Sell";

        Print("---- ", comment,
              " | Entry: ", entry, " | SL: ", sl, " | TP: ", tp,
              " | Lotsize: ", lot_size);

        if (market_bias == TREND_BULLISH)
            ctrade.Buy(lot_size, _Symbol, entry, sl, tp, comment);

        else if (market_bias == TREND_BEARISH)
            ctrade.Sell(lot_size, _Symbol, entry, sl, tp, comment);
    }

    static double get_entry_price(TrendType market_bias) {

        if (market_bias == TREND_BULLISH)
            return SymbolInfoDouble(_Symbol, SYMBOL_ASK);

        else if (market_bias == TREND_BEARISH)
            return SymbolInfoDouble(_Symbol, SYMBOL_BID);

        return 0.0;
    }

    static double get_stop_loss_price(TrendType market_bias, Zone& zone) {
        bool bullish_entry = (market_bias == TREND_BULLISH);
        double factor = bullish_entry ? -1.0 : 1.0;
        double zone_margin = MathAbs(zone.get_top_price() - zone.get_bottom_price());
        double zone_ref = bullish_entry ? zone.get_bottom_price() : zone.get_top_price();
        return (zone_ref + (factor * zone_margin));
    }

    static double get_take_profit_price(
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

    static double get_lot_size(double entry, double sl, double risk_percentage) {
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

    static void apply_breakeven() {

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

            CTrade ctrade;
            ctrade.PositionModify(ticket, entry, tp);
        }
    }

  public:
    static void set_args(AdvisorArgs& advisor_args) {
        args = advisor_args.trend_follow;
        visual_mode = advisor_args.visual_mode;
    }

    static void check_open_positions() {
        if (args.breakeven_value > 0.0)
            apply_breakeven();
    }

    static bool has_reached_daily_limit() {

        if (args.daily_limit_losses == 0 && args.daily_limit_wins == 0)
            return false;

        datetime today_init = MarketSession::get_today_init_time();
        datetime today_end = MarketSession::get_today_end_time();

        HistorySelect(today_init, today_end);

        int today_deals = HistoryDealsTotal();
        int today_losses = 0;
        int today_wins = 0;

        for (int i = 0; i < today_deals; i++) {

            ulong deal = HistoryDealGetTicket(i);
            HistoryDealSelect(deal);

            ulong order = HistoryDealGetInteger(deal, DEAL_ORDER);

            if (order == 0)
                continue;

            double profit = HistoryDealGetDouble(deal, DEAL_PROFIT);

            if (profit < 0)
                today_losses++;

            else if (profit > 0)
                today_wins++;
        }

        if (args.daily_limit_losses > 0 && (today_losses >= args.daily_limit_losses))
            return true;

        if (args.daily_limit_wins > 0 && (today_wins >= args.daily_limit_wins))
            return true;

        return false;
    }

    static bool has_reached_monthly_win_limit() {

        if (args.monthly_limit_percentage <= 0.0)
            return false;

        double month_profit = MarketOrder::get_month_profit();

        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double profit_percentage = (month_profit / balance) * 100.0;

        return profit_percentage >= args.monthly_limit_percentage;
    }

    static void process_new_rate() {

        bool open_positions = MarketOrder::has_open_positions();
        if (open_positions)
            return;

        bool daily_limit = has_reached_daily_limit();
        if (daily_limit)
            return;

        bool monthly_limit = has_reached_monthly_win_limit();
        if (monthly_limit)
            return;

        StructureBlock last_block;
        get_latest_valid_block(last_block);
        if (!last_block.is_valid())
            return;

        bool upheld_block = is_upheld_block(last_block);
        if (!upheld_block)
            return;

        Zone zone;
        MarketZone::get_zone_from_block(zone, last_block, false);

        bool upheld_zone = is_upheld_zone(zone);
        if (!upheld_zone)
            return;

        if (visual_mode)
            MarketZone::draw_zone(zone);

        bool valid_breakout = is_valid_breakout(zone, last_block);
        if (!valid_breakout)
            return;

        make_trade(last_block, zone);

        Print("------------------------------------");
    }
};

static TrendFollowArgs TrendFollow::args;
static bool TrendFollow::visual_mode = false;
