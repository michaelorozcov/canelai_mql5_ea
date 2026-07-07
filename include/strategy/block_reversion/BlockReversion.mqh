#include "../../../include/utils/LogUtils.mqh"
#include "../../../include/utils/RatesUtils.mqh"

#include "../../../include/indicators/BollingerBands.mqh"
#include "../../../include/indicators/RSI.mqh"

#include "../../../include/market/MarketPivot.mqh"
#include "../../../include/market/MarketStructure.mqh"

struct PriceRef {
    int index;
    datetime time;
    double price;
    ENUM_BOLLINGER_BANDS_EXT bb_ext;
    ENUM_RSI_EXTENSION rsi_ext;
};

class BlockReversion : public NewRateBased {

  public:
    BlockReversion(AdvisorArgs& advisor_args_data) {
        this.args = advisor_args_data;
        init();
    }

    ~BlockReversion() {
        deinit();
    }

    void on_new_rate() {
        process_new_rate();
    }

  protected:
    AdvisorArgs args;
    PriceRef last_price_ref;

    int handler_rsi;
    int handler_bollinger;

    void log(string message) {

        Print("LOG: ", this.advisor_id);

        if (this.args.log_file)
            LogUtils::log(this.advisor_id, message);
        Print(message);
    }

    void init() {
        log("BlockReversion: init");
        init_indicator_rsi();
        init_indicator_bollinger();
    }

    void deinit() {
        log("BlockReversion: deinit");
        deinit_indicator_rsi();
        deinit_indicator_bollinger();
    }

    void init_indicator_rsi() {
        this.handler_rsi =
            RSI::get_rsi_handler(this.args.block_reversion.rsi_period);
        string success = (string)(this.handler_rsi != INVALID_HANDLE);
        log(StringFormat("RSI: Init %s", success));
    }

    void deinit_indicator_rsi() {
        if (this.handler_rsi != INVALID_HANDLE)
            IndicatorRelease(this.handler_rsi);
    }

    void init_indicator_bollinger() {
        this.handler_bollinger = iBands(
            _Symbol, _Period,
            this.args.block_reversion.bollinger_period,
            0, 2.0, PRICE_CLOSE);
        string success = (string)(this.handler_bollinger != INVALID_HANDLE);
        log(StringFormat("Bollinger: Init %s", success));
    }

    void deinit_indicator_bollinger() {
        if (this.handler_bollinger != INVALID_HANDLE)
            IndicatorRelease(this.handler_bollinger);
    }

    void process_new_rate() {

        log("---- \n Processing new rate");

        if (has_open_positions()) {
            log("There are open positions");
            return;
        }

        if (has_reached_limit()) {
            delete_market_analysis();
            return;
        }

        if (check_last_block()) {
            delete_market_analysis();
            set_market_analysis();
        }

        if (is_valid_entry()) {
            place_order();
        }
    }

    bool has_open_positions() {
        return MarketOrder::has_open_positions(this.magic_number);
    }

    bool has_reached_limit() {

        double today_profit = 0;
        int today_wins = 0;
        int today_losses = 0;
        MarketOrder::get_today_profit(today_profit, today_wins, today_losses);

        bool limit_won = has_reached_limit_won(today_profit);
        bool limit_lost = has_reached_limit_lost(today_profit);

        if (limit_won || limit_lost) {
            log(StringFormat(
                "It has reached trading limit: %s",
                DoubleToString(today_profit, _Digits)));
            return true;
        }

        return false;
    }

    bool has_reached_limit_won(double today_profit) {

        double limit_daily_pct_won = this.args.block_reversion.limit_daily_pct_won;
        if (limit_daily_pct_won == 0.0)
            return false;

        if (today_profit < 0)
            return false;

        double max_won =
            MarketOrder::get_balance_percentage(limit_daily_pct_won);

        return (MathAbs(today_profit) >= max_won);
    }

    bool has_reached_limit_lost(double today_profit) {

        double limit_daily_pct_lost = this.args.block_reversion.limit_daily_pct_lost;
        if (limit_daily_pct_lost == 0.0)
            return false;

        if (today_profit > 0)
            return false;

        double max_lost =
            MarketOrder::get_balance_percentage(limit_daily_pct_lost);

        return (MathAbs(today_profit) >= max_lost);
    }

    void delete_market_analysis() {
        RatesUtils::delete_rates();
        MarketPivot::delete_pivot_points();
        MarketStructure::delete_market_structure();
    }

    void set_market_analysis() {
        RatesUtils::set_rates(
            this.args.block_reversion.analysis_shift_minutes,
            this.args.block_reversion.analysis_lowest_index,
            this.args.visual_mode);
        MarketPivot::set_pivot_points(
            this.args.block_reversion.analysis_lowest_index,
            this.args.visual_mode,
            this.args.block_reversion.pivot_point_strength);
        MarketStructure::set_market_structure(
            this.args.block_reversion.analysis_lowest_index,
            this.args.visual_mode);
    }

    bool is_valid_entry() {

        PriceRef price_ref;
        price_ref.index = (this.args.block_reversion.pivot_point_strength + 1);

        if (check_last_block()) {

            StructureBlock block;
            get_latest_block(block);

            if (!block.is_valid()) {
                log("Not valid block");
                return false;
            }

            if (check_valid_level()) {
                bool valid_level = is_valid_level(block);
                log(StringFormat(
                    "Valid level: ",
                    to_string(valid_level)));

                if (!valid_level)
                    return false;
            }

            price_ref.index = block.end.rate_index;
        }

        if (has_passed_index(price_ref.index)) {
            log("Passed index");
            return false;
        }

        price_ref.time = RatesUtils::get_rate_time(price_ref.index);
        if (has_been_traded(price_ref.time)) {
            log("Already traded block");
            return false;
        }

        if (check_bollinger_extension()) {
            bool bb_ext = is_bollinger_extension(block);
            log(StringFormat(
                "Bollinger Ext: ",
                to_string(bb_ext)));

            if (!bb_ext)
                return false;
        }

        if (check_rsi_extension()) {
            bool rsi_ext = is_rsi_extension(block);
            log(StringFormat(
                "RSI Ext: ",
                to_string(rsi_ext)));

            if (!rsi_ext)
                return false;
        }

        return true;
    }

    string to_string(bool value) {
        return value ? "true" : "false";
    }

    void get_latest_block(StructureBlock& block) {
        block.clear();
        MarketStructure::get_latest_block(block);
    }

    bool has_been_traded(datetime time_ref) {
        return (this.last_price_ref.time == time_ref);
    }

    bool has_passed_index(int rate_index) {
        int max_index = (this.args.block_reversion.pivot_point_strength + 1);
        return (rate_index > max_index);
    }

    bool check_last_block() {
        return (this.args.block_reversion.pivot_point_strength > 0);
    }

    bool check_valid_level() {
        return (this.args.block_reversion.entry_level_max > 0);
    }

    bool is_valid_level(StructureBlock& block) {

        double price = get_current_price();
        double level = get_price_level(block, price);
        double max = this.args.block_reversion.entry_level_max;

        draw_block_levels(block);

        log(StringFormat(
            "Level: %s - Max: %s",
            DoubleToString(level, _Digits),
            DoubleToString(max, _Digits)));

        return (level < max);
    }

    double get_price_level(StructureBlock& block, double price) {
        double base_line = block.is_bullish() ? block.get_top_price() : block.get_bottom_price();
        double track_partial = MathAbs(price - base_line);
        double track_total = MathAbs(block.get_top_price() - block.get_bottom_price());
        double price_level = (track_partial / track_total) * 100;
        return NormalizeDouble(price_level, _Digits);
    }

    void draw_block_levels(StructureBlock& block) {
        if (!this.args.visual_mode)
            return;

        double block_top = block.get_top_price();
        double block_bottom = block.get_bottom_price();
        double step = ((MathAbs(block_top - block_bottom)) / 100);
        double distance = (step * this.args.block_reversion.entry_level_max);

        double block_price =
            block.is_bullish()
                ? block_top - distance
                : block_bottom + distance;
        datetime block_time = RatesUtils::get_rate_time(block.end.rate_index);

        ChartUtils::create_chart_object(
            OBJ_ARROWED_LINE, "max_level",
            block_time, block_price,
            RatesUtils::get_rate_time(0),
            block_price);
    }

    bool check_bollinger_extension() {
        return (BB_PERIOD_0 != this.args.block_reversion.bollinger_period);
    }

    /*
    bool is_bollinger_extension(StructureBlock& block) {
        datetime block_time = RatesUtils::get_rate_time(block.end.rate_index);
        double block_price = MarketPivot::get_pivot_price(block.end, true);
        return is_bollinger_extension(block_time, block_price);
    }
    */



    bool get_bollinger_bands_values(
        datetime time, BollingerBandsValues& out_values) {
        return BollingerBands::get_bollinger_bands_values(
            time,
            this.handler_bollinger,
            out_values);
    }

    bool check_rsi_extension() {
        return (RSI_PERIOD_0 != this.args.block_reversion.rsi_period);
    }

    /*
    bool is_rsi_extension(StructureBlock& block) {
        datetime block_time = RatesUtils::get_rate_time(block.end.rate_index);
        return is_rsi_extension(block_time);
    }
    */

    bool is_rsi_extension(datetime time) {
        double rsi_value = 0.0;
        if (!get_rsi_value(time, rsi_value))
            return false;

        bool ext_top = (rsi_value > this.args.block_reversion.rsi_threshold_top);
        bool ext_bottom = (rsi_value < this.args.block_reversion.rsi_threshold_bottom);
        bool ext_rsi = (ext_top || ext_bottom);

        return ext_rsi;
    }

    bool get_rsi_value(datetime time, double& rsi_value) {
        return RSI::get_rsi_value(
            rsi_value, this.handler_rsi, time);
    }

    void place_order() {
        if (ticket != 0) {
            // this.traded_block_time = RatesUtils::get_rate_time(block.end.rate_index);
            this.last_traded_time = time_ref;
        }

        ENUM_ORDER_TYPE order = this.price_ref;
        dpi

            double sl;
        place_order();
    }

    ulong place_order(ENUM_ORDER_TYPE order, double sl) {

        // ENUM_ORDER_TYPE order, double sl,
        // bool is_bullish = block.is_bullish();
        // ENUM_ORDER_TYPE order = is_bullish ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
        // double sl = is_bullish ? block.get_top_price() : block.get_bottom_price();
        double price = get_entry_price(order);
        double rr = this.args.block_reversion.risk_reward_ratio;
        double tp = MarketOrder::calculate_take_profit_price(
            order, sl, price, rr);
        double risk = this.args.block_reversion.risk_percentage;
        double volume = get_trade_volume(price, sl, risk);

        log(StringFormat(
            "%s | Entry: %s | SL: %s | TP: %s | Volume: %s",
            "Trade: " + ((order == ORDER_TYPE_BUY) ? "Buy" : "Sell"),
            DoubleToString(price, _Digits),
            DoubleToString(sl, _Digits),
            DoubleToString(tp, _Digits),
            DoubleToString(volume, _Digits)));

        return trade(order, volume, price, sl, tp);
    }

    double get_current_price() {
        double ask, bid;
        MarketOrder::get_current_price(ask, bid);

        return ((ask + bid) / 2);
    }

    double get_entry_price(ENUM_ORDER_TYPE order) {
        double ask, bid;
        MarketOrder::get_current_price(ask, bid);

        return (order == ORDER_TYPE_BUY) ? ask : bid;
    }

    double get_trade_volume(
        double price, double stop_loss, double risk_percentage) {

        double fixed = this.args.block_reversion.fixed_volume;
        if (fixed > 0)
            return fixed;

        return MarketOrder::get_trade_volume(price, stop_loss, risk_percentage);
    }
};
