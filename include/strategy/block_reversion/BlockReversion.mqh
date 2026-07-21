#include "./../../../include/dto/PivotPoint.mqh"
#include "./../../../include/dto/Structure.mqh"
#include "./../../../include/dto/args_input/AdvisorArgs.mqh"

#include "./../../../include/utils/Constants.mqh"
#include "./../../../include/utils/LogUtils.mqh"
#include "./../../../include/utils/RatesUtils.mqh"

#include "./../../../include/indicators/BollingerBands.mqh"
#include "./../../../include/indicators/RSI.mqh"
#include "./../../../include/indicators/ATR.mqh"

#include "./../../../include/market/MarketOrder.mqh"
#include "./../../../include/market/MarketPivot.mqh"
#include "./../../../include/market/MarketStructure.mqh"

#include "./../../../include/strategy/NewRateBased.mqh"

struct BlockData {
    int end_index;
    datetime end_time;
    double end_price;
    double block_size;
    TrendType type;
    ENUM_ORDER_TYPE order;

    BlockData() {
        this.end_index = 0;
        this.end_time = 0;
        this.end_price = 0.0;
        this.block_size = 0.0;
        this.type = TREND_RANGING;
        this.order = ORDER_TYPE_BUY;
    }
};

// Strategy: Expert Advisor
class BlockReversion : public NewRateBased {

  public:
    BlockReversion(AdvisorArgs& param_args, string param_advisor_id)
        : NewRateBased(param_args, param_advisor_id) {
        // init();
    }

    ~BlockReversion() {
        // deinit();
    }

    void on_init() override {
        process_on_init();
    }

  protected:
    int handler_rsi;
    int handler_bollinger;
    int handler_atr;

    StructureBlock last_block;
    BlockData last_block_data;

    void init() {
        log("BlockReversion: init");
        init_indicator_rsi();
        init_indicator_bollinger();
        init_indicator_atr();
    }

    void deinit() {
        log("BlockReversion: deinit");
        deinit_indicator_rsi();
        deinit_indicator_bollinger();
        deinit_indicator_atr();
    }

    void init_indicator_rsi() {
        this.handler_rsi =
            RSI::get_rsi_handler(this.args.block_reversion.rsi_period);
        log(StringFormat(
            "RSI: Init %s",
            to_string((this.handler_rsi != INVALID_HANDLE))));
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
        log(StringFormat(
            "Bollinger: Init %s",
            to_string((this.handler_bollinger != INVALID_HANDLE))));
    }

    void deinit_indicator_bollinger() {
        if (this.handler_bollinger != INVALID_HANDLE)
            IndicatorRelease(this.handler_bollinger);
    }

    void init_indicator_atr() {
        this.handler_atr =
            ATR::get_atr_handler(this.args.block_reversion.atr_period);
        log(StringFormat(
            "ATR: Init %s",
            to_string((this.handler_atr != INVALID_HANDLE))));
    }

    void deinit_indicator_atr() {
        if (this.handler_atr != INVALID_HANDLE)
            IndicatorRelease(this.handler_atr);
    }

    string to_string(bool value) {
        return value ? "true" : "false";
    }

    void process_on_init() {
        process_new_rate();
    }

    void on_new_rate() override {
        process_new_rate();
    }

    void process_new_rate() {

        delete_market_analysis();
        set_market_analysis();

        if (has_open_positions()) {
            return;
        }

        StructureBlock block;
        get_latest_block(block);

        if (is_valid_entry(block)) {
            place_order(block);
        }
    }

    bool is_valid_entry(StructureBlock& block) {

        if (!block.is_valid()) {
            return false;
        }

        if (has_been_traded(block)) {
            return false;
        }

        if (has_passed_index(block.end.rate_index)) {
            return false;
        }

        return true;
    }

    void place_order(StructureBlock& block) {
        set_block_data(block);

        MqlTick tick;
        SymbolInfoTick(_Symbol, tick);

        ENUM_ORDER_TYPE order = this.last_block_data.order;
        double entry = (order == ORDER_TYPE_BUY) ? tick.ask : tick.bid;
        double sl = get_sl_price(entry);
        double volume = calculate_position_volume(entry, sl);
        double rr = this.args.risk.reward_ratio;

        Print(StringFormat(
            "Entry %s SL %s Vol %s RR %s",
            DoubleToString(entry, _Digits),
            DoubleToString(sl, _Digits),
            DoubleToString(volume, _Digits),
            DoubleToString(rr, _Digits)));

        market_order_delayed_tp(order, volume, _Symbol, entry, sl, rr);
    }

    double get_sl_price(double entry) {
        double sl = this.last_block_data.end_price;

        if (this.args.block_reversion.sl_blocks > 0) {
            double factor = (this.last_block_data.order == ORDER_TYPE_BUY) ? -1 : 1;
            double size = this.last_block_data.block_size;
            sl = (entry + (size * this.args.block_reversion.sl_blocks * factor));
        }

        return sl;
    }

    /*
    bool is_valid_entry() {

        log(StringFormat(
            "Last block end [ Time: %s | Price: %s | Order: %s ]",
            TimeToString(data.time),
            DoubleToString(data.price, _Digits),
            EnumToString(data.order)
            //
            ));

        if (has_been_traded(block)) {
            log(StringFormat(
                "Already traded block: %s",
                TimeToString(data.time)));
            return false;
        }

        if (has_passed_index(data.index)) {
            log(StringFormat(
                "Passed index: %s",
                IntegerToString(data.index)));
            return false;
        }

        if (check_bollinger_extension()) {
            log(StringFormat(
                "Bollinger Ext: %s",
                EnumToString(data.bb_ext)));

            if (BB_NONE_EXT == data.bb_ext)
                return false;
        }

        if (check_rsi_extension()) {
            log(StringFormat(
                "RSI Ext: %s",
                EnumToString(data.rsi_ext)));

            if (RSI_NONE_EXT == data.rsi_ext)
                return false;
        }

        if (check_level()) {
            bool valid_level = is_valid_level(block);
            log(StringFormat(
                "Level valid: %s",
                to_string(valid_level)));

            if (!valid_level)
                return false;
        }

        this.last_block_data = data;
        this.last_block = block;

        return true;
    }

    bool check_bollinger_extension() {
        return (BB_PERIOD_0 != this.args.block_reversion.bollinger_period);
    }

    bool check_rsi_extension() {
        return (RSI_PERIOD_0 != this.args.block_reversion.rsi_period);
    }

    void place_order() {

        double ask, bid, price;
        MarketOrder::get_current_price(_Symbol, ask, bid, price);
        price = (this.last_block_data.order == ORDER_TYPE_BUY) ? ask : bid;

        double sl = get_sl_price(price);
        double volume = calculate_position_volume(price, sl);

        log(StringFormat(
            "%s | Entry: %s | SL: %s | TP: %s | Vol: %s",
            EnumToString(this.last_block_data.order),
            DoubleToString(price, _Digits),
            DoubleToString(sl, _Digits),
            DoubleToString(0.0, _Digits),
            DoubleToString(volume, _Digits)));

        ulong ticket = market_order_delayed_tp(
            this.last_block_data.order,
            volume, _Symbol, price, sl,
            this.args.risk.reward_ratio);

        if (ticket == 0) {
            log("Error placing order");
        }
    }

    double get_sl_price(double entry_price) {
        double sl = this.last_block_data.price;

        if (this.args.block_reversion.sl_blocks > 0) {
            double factor = (this.last_block_data.order == ORDER_TYPE_BUY) ? -1 : 1;
            double size = this.last_block.get_size();
            sl = (entry_price + (size * this.args.block_reversion.sl_blocks * factor));
        }

        return sl;
    }

    /*
    void get_anticipated_block(StructureBlock& latest_block, StructureBlock& anticipated) {

        anticipated.clear();

        double latest_block_top = latest_block.get_top_price();
        double latest_block_bottom = latest_block.get_bottom_price();

        int previous_index = 1;
        double previous_high = RatesUtils::get_rate_highest_price(previous_index, false);
        double previous_low = RatesUtils::get_rate_lowest_price(previous_index, false);

        double atr_value = get_atr_value(iTime(_Symbol, _Period, previous_index));
        double threshold = (atr_value * 0.3); // TODO

        bool higher_high = (previous_high > (latest_block_top + threshold));
        bool lower_low = (previous_low < (latest_block_bottom - threshold));

        if (!higher_high && !lower_low) {
            return;
        }

        int strength = this.args.block_reversion.pivot_point_strength;
        bool is_top_break = (higher_high && is_left_high_pivot(previous_index, strength));
        bool is_bottom_break = (lower_low && is_left_low_pivot(previous_index, strength));

        if (!is_top_break && !is_bottom_break) {
            return;
        }

        PivotPoint end_pivot;
        end_pivot.order = PIVOT_ORDER_1; // TODO
        end_pivot.rate_index = previous_index;
        end_pivot.type = is_top_break ? PIVOT_TYPE_HIGH : PIVOT_TYPE_LOW;

        PivotPoint start_pivot;
        MarketPivot::get_previous_opposite_pivot(start_pivot, end_pivot);

        anticipated.start = start_pivot;
        anticipated.end = end_pivot;
    }

    bool is_left_high_pivot(int rate_index, int strength) {

        int start = rate_index;
        int end = (rate_index + strength);
        double price = RatesUtils::get_rate_highest_price(rate_index, true);

        for (int i = start; i <= end; i++) {
            double compare = RatesUtils::get_rate_highest_price(i, true);

            if (price < compare)
                return false;
        }

        return true;
    }

    bool is_left_low_pivot(int rate_index, int strength) {

        int start = rate_index;
        int end = (rate_index + strength);
        double price = RatesUtils::get_rate_lowest_price(rate_index, true);

        for (int i = start; i <= end; i++) {
            double compare = RatesUtils::get_rate_lowest_price(i, true);

            if (price > compare)
                return false;
        }

        return true;
    }

    bool check_level() {
        return (this.args.block_reversion.entry_level_max > 0);
    }

    bool is_valid_level(StructureBlock& block) {

        double ask, bid, price;
        MarketOrder::get_current_price(_Symbol, ask, bid, price);

        double level = get_price_level(block, price);
        double max = this.args.block_reversion.entry_level_max;

        draw_block_levels(block);

        log(StringFormat(
            "Level: %s - Max: %s",
            DoubleToString(level, _Digits),
            DoubleToString(max, _Digits)));

        return (level < max);
    }



    void draw_block_levels(StructureBlock& block) {

        if (!this.args.general.visual_mode)
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

    */

    // ------------------------------------------------------------------------
    // UTILS
    // ------------------------------------------------------------------------

    void delete_market_analysis() {
        RatesUtils::delete_rates();
        MarketPivot::delete_pivot_points();
        MarketStructure::delete_market_structure();
    }

    void set_market_analysis() {
        RatesUtils::set_rates(
            this.args.block_reversion.analysis_shift_minutes,
            this.args.block_reversion.analysis_lowest_index,
            this.args.general.visual_mode);
        MarketPivot::set_pivot_points(
            this.args.block_reversion.analysis_lowest_index,
            this.args.general.visual_mode,
            this.args.block_reversion.pivot_point_strength);
        MarketStructure::set_market_structure(
            this.args.block_reversion.analysis_lowest_index,
            this.args.general.visual_mode);
    }

    bool has_been_traded(StructureBlock& block) {
        datetime time = RatesUtils::get_rate_time(block.end.rate_index);
        return (this.last_block_data.end_time == time);
    }

    bool has_passed_index(int rate_index) {
        int max_index = (this.args.block_reversion.pivot_point_strength + 1);
        return (rate_index > max_index);
    }

    void set_block_data(StructureBlock& block) {
        this.last_block_data.end_index = block.end.rate_index;
        this.last_block_data.end_time = RatesUtils::get_rate_time(block.end.rate_index);
        this.last_block_data.end_price = MarketPivot::get_pivot_price(block.end, true);
        this.last_block_data.order = block.is_bullish() ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
        this.last_block_data.block_size = block.get_size();
    }

    double get_price_blocks(StructureBlock& block, double price) {
        double base_line = block.is_bullish() ? block.get_top_price() : block.get_bottom_price();
        double track_partial = MathAbs(price - base_line);
        double track_total = block.get_size();
        double price_level = (track_partial / track_total);
        return NormalizeDouble(price_level, _Digits);
    }

    void get_latest_block(StructureBlock& latest_block, int shift = 1) {

        latest_block.clear();

        StructureBlock blocks[];
        MarketStructure::get_latest_blocks(blocks, shift);

        int amount = ArraySize(blocks);

        if (amount != shift) {
            log(StringFormat(
                "Error Blocks retrieved %s - Expected %s",
                IntegerToString(amount),
                IntegerToString(shift)));
            return;
        }

        latest_block = blocks[0];
    }

    /*
    double get_atr_value(datetime time) {
        double atr_value = 0.0;
        ATR::get_atr_value(atr_value, this.handler_atr, time);
        return atr_value;
    }

    ENUM_BOLLINGER_BANDS_EXT get_bollinger_extension(datetime time, double price) {

        if (!has_valid_bollinger_config())
            return BB_NONE_EXT;

        return BollingerBands::get_bollinger_extension(
            time, price, this.handler_bollinger);
    }

    bool has_valid_bollinger_config() {
        return ((this.handler_bollinger != INVALID_HANDLE) &&
                (this.args.block_reversion.bollinger_period != BB_PERIOD_0));
    }

    ENUM_RSI_EXTENSION get_rsi_extension(datetime time) {

        if (!has_valid_rsi_config())
            return RSI_NONE_EXT;

        return RSI::get_rsi_extension(
            this.handler_rsi, time,
            this.args.block_reversion.rsi_threshold_top,
            this.args.block_reversion.rsi_threshold_bottom);
    }

    bool has_valid_rsi_config() {
        return ((this.handler_rsi != INVALID_HANDLE) &&
                this.args.block_reversion.rsi_period != RSI_PERIOD_0);
    }
    */
};
