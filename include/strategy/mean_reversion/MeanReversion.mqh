#include "../../../include/dto/AdvisorArgs.mqh"

#include "../../../include/indicators/BollingerBands.mqh"
#include "../../../include/indicators/RSI.mqh"

#include "../../../include/utils/ArrayUtils.mqh"
#include "../../../include/utils/RatesUtils.mqh"

#include "../../../include/market/MarketOrder.mqh"
#include "../../../include/market/MarketPivot.mqh"
#include "../../../include/market/MarketStructure.mqh"

#include "../Strategy.mqh"
#include "MeanReversionArgs.mqh"

class MeanReversion : public NewRateBased {

  public:
    MeanReversion(AdvisorArgs& advisor_args_data) {
        this.args = advisor_args_data;
        this.handler_rsi = INVALID_HANDLE;
        this.handler_bollinger = INVALID_HANDLE;
    }

    void on_init() {
        init();
    }

    void on_deinit() {
        deinit();
    }

    void on_new_rate() {
        process_new_rate();
    }

    void on_tick() {
        // TODO
    }

  protected:
    AdvisorArgs args;

    int handler_rsi;
    int handler_bollinger;

    StructureBlock latest_block;

    virtual void init() {
        init_indicator_rsi();
        init_indicator_bollinger();
    }

    virtual void deinit() {
        deinit_indicator_rsi();
        deinit_indicator_bollinger();
    }

    void init_indicator_rsi() {
        this.handler_rsi =
            RSI::get_rsi_handler(this.args.mean_reversion.rsi_ma_period);
    }

    void deinit_indicator_rsi() {
        if (this.handler_rsi != INVALID_HANDLE)
            IndicatorRelease(this.handler_rsi);
    }

    void init_indicator_bollinger() {
        this.handler_bollinger = iBands(
            _Symbol, _Period,
            this.args.mean_reversion.bollinger_period,
            0, 2.0, PRICE_CLOSE);
    }

    void deinit_indicator_bollinger() {
        if (this.handler_bollinger != INVALID_HANDLE)
            IndicatorRelease(this.handler_bollinger);
    }

    virtual void process_new_rate() {
        Print("----", "process_new_rate");

        delete_market_analysis();
        set_market_analysis();
    }

    void delete_market_analysis() {
        RatesUtils::delete_rates();
        MarketPivot::delete_pivot_points();
        MarketStructure::delete_market_structure();
    }

    void set_market_analysis() {
        // Rates
        RatesUtils::set_rates(
            this.args.mean_reversion.analysis_shift_minutes,
            this.args.mean_reversion.analysis_lowest_index,
            this.args.visual_mode);
        // Pivot Points
        MarketPivot::set_pivot_points(
            this.args.mean_reversion.analysis_lowest_index,
            this.args.visual_mode,
            this.args.mean_reversion.analysis_pivot_point_strength);
        // Market Structure
        MarketStructure::set_market_structure(
            this.args.mean_reversion.analysis_lowest_index,
            this.args.visual_mode);
    }

    void get_latest_block(StructureBlock& dest) {
        dest.clear();

        StructureBlock blocks[];
        MarketStructure::get_latest_blocks(blocks, 1);

        if (ArraySize(blocks) == 0)
            return;

        dest = blocks[0];
    }

    bool is_valid_level(StructureBlock& block) {

        MqlTick tick;
        SymbolInfoTick(_Symbol, tick);

        double price = (tick.ask + tick.ask) / 2;
        double level = get_price_level(block, price);

        return (level < this.args.mean_reversion.entry_level_max);
    }

    double get_price_level(StructureBlock& block, double price) {
        double base_line = block.is_bullish() ? block.get_top_price() : block.get_bottom_price();
        double track_partial = MathAbs(price - base_line);
        double track_total = MathAbs(block.get_top_price() - block.get_bottom_price());
        double price_level = (track_partial / track_total) * 100;
        return NormalizeDouble(price_level, _Digits);
    }

    bool is_bollinger_extension(datetime time, double price) {
        BollingerBandsValues bb_values;
        if (!get_bollinger_bands_values(time, bb_values))
            return false;

        bool ext_up = price > bb_values.upper_band;
        bool ext_low = price < bb_values.lower_band;
        bool ext_bb = (ext_up || ext_low);

        return ext_bb;
    }

    bool get_bollinger_bands_values(
        datetime time, BollingerBandsValues& out_values) {
        return BollingerBands::get_bollinger_bands_values(
            time,
            this.handler_bollinger,
            out_values);
    }

    bool is_rsi_extension(datetime time) {
        double rsi_value = 0.0;
        if (!get_rsi_value(time, rsi_value))
            return false;

        bool ext_top = rsi_value > this.args.mean_reversion.rsi_threshold_top;
        bool ext_bottom = rsi_value < this.args.mean_reversion.rsi_threshold_bottom;
        bool ext_rsi = (ext_top || ext_bottom);

        return ext_rsi;
    }

    bool get_rsi_value(datetime time, double& rsi_value) {
        return RSI::get_rsi_value(
            rsi_value, this.handler_rsi, time);
    }

    void place_order(StructureBlock& block) {

        Print("Placing order");

        MqlTick tick;
        SymbolInfoTick(_Symbol, tick);

        bool block_bullish = block.is_bullish();
        ENUM_ORDER_TYPE order = block_bullish ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
        double price = (order == ORDER_TYPE_BUY) ? tick.ask : tick.bid;
        double sl = block.get_end_price();
        double rr = this.args.mean_reversion.risk_reward_ratio;
        double volume = get_trade_volume(price, sl);
        double tp =
            MarketOrder::get_take_profit_price(order, sl, price, rr);

        this.trade(order, volume, price, sl, tp);

        this.latest_block = block;
    }

    double get_trade_volume(double entry_price, double stop_loss) {
        // TODO
        return 0.01;
    }
};

/*





        if (has_open_positions())
            return;

        Print("---- \t\t process_new_rate");

        delete_market_analysis();
        set_market_analysis();

        // TODO
        return;

        StructureBlock block;
        get_latest_block(block);

        if (!is_valid_block(block))
            return;

        if (is_valid_entry(block))
            place_order(block);
    }

    void delete_market_analysis() {
        RatesUtils::delete_rates();
        MarketPivot::delete_pivot_points();
        MarketStructure::delete_market_structure();
    }

    void set_market_analysis() {

        // Rates
        RatesUtils::set_rates(
            this.args.mean_reversion.analysis_shift_minutes,
            this.args.mean_reversion.analysis_lowest_index,
            this.args.visual_mode);

        // Pivot Points
        MarketPivot::set_pivot_points(
            this.args.mean_reversion.analysis_lowest_index,
            this.args.visual_mode,
            this.args.mean_reversion.analysis_pivot_point_strength);

        // Market Structure
        MarketStructure::set_market_structure(
            this.args.mean_reversion.analysis_lowest_index,
            this.args.visual_mode);
    }

    bool has_open_positions() {
        return MarketOrder::has_open_positions(this.magic_number);
    }

    void get_latest_block(StructureBlock& dest) {
        MarketStructure::get_latest_block(dest);
    }

    bool is_valid_block(StructureBlock& block) {
        datetime block_time = RatesUtils::get_rate_time(block.end.rate_index);
        if (block_time == this.lastest_reversion_time) {
            Print("Previously traded block");
            return false;
        }

        return true;
    }

    bool is_valid_entry(StructureBlock& block) {
        return is_valid_index(block) &&
               is_bollinger_ext(block) &&
               is_rsi_ext(block) &&
               is_valid_level(block);
    }

    bool is_bollinger_ext(StructureBlock& block) {

        return true;
        /*
        datetime block_time = RatesUtils::get_rate_time(block.end.rate_index);
        double bb_upper_band, bb_middle_band, bb_lower_band, bb_width_size, bb_width_pct;

        bool result = get_bollinger_bands_values(
            block_time,
            bb_upper_band, bb_middle_band, bb_lower_band,
            bb_width_size, bb_width_pct);

        if (!result)
            return false;

        bool block_bullish = block.is_bullish();
        bool block_bearish = block.is_bearish();
        double block_price = block.get_end_price();

        bool upper_ext = block_bullish && (block_price > bb_upper_band);
        bool lower_ext = block_bearish && (block_price < bb_lower_band);
        bool bollinger_ext = (upper_ext || lower_ext);

        Print(StringFormat(
            "%s \t\t %s - Bollinger [ %s - %s - %s ]",
            (string)bollinger_ext,
            DoubleToString(block_price, _Digits),
            DoubleToString(bb_upper_band, _Digits),
            DoubleToString(bb_middle_band, _Digits),
            DoubleToString(bb_lower_band, _Digits)));

        return bollinger_ext;
    }

    bool is_bollinger_ext(int rate_index) {

        datetime block_time = RatesUtils::get_rate_time(block.end.rate_index);
        double bb_upper_band, bb_middle_band, bb_lower_band, bb_width_size, bb_width_pct;

        // TODO
        /*
        bool result = get_bollinger_bands_values(
            block_time,
            bb_upper_band, bb_middle_band, bb_lower_band,
            bb_width_size, bb_width_pct);

        if (!result)
            return false;

        return true;
    }

    bool get_bollinger_bands_values(
        int in_rate_index, BollingerBandsValues& out_values) {
        return BollingerBands::get_bollinger_bands_values(
            RatesUtils::get_rate_time(in_rate_index),
            this.handler_bollinger,
            out_values);
    }

    bool is_rsi_ext(StructureBlock& block) {

        datetime block_time = RatesUtils::get_rate_time(block.end.rate_index);
        double rsi_threshold_top = this.args.mean_reversion.rsi_threshold_top;
        double rsi_threshold_bottom = this.args.mean_reversion.rsi_threshold_bottom;
        double rsi_value = 0.0;
        bool result = get_rsi_value(rsi_value, block_time);

        if (!result)
            return false;

        bool overbought = rsi_value > rsi_threshold_top;
        bool oversold = rsi_value < rsi_threshold_bottom;
        bool rsi_ext = (overbought || oversold);

        Print(StringFormat(
            "%s \t\t %s - RSI [ %s - %s ]",
            (string)rsi_ext,
            DoubleToString(rsi_value, _Digits),
            DoubleToString(rsi_threshold_top, _Digits),
            DoubleToString(rsi_threshold_bottom, _Digits)));

        return rsi_ext;
    }



    bool is_valid_level(StructureBlock& block) {

        MqlTick tick;
        SymbolInfoTick(_Symbol, tick);

        double price = NormalizeDouble(((tick.ask + tick.bid) / 2), _Digits);
        double price_level = get_price_level(block, price);

        double level_max = this.args.mean_reversion.entry_level_max;
        bool level_valid = (price_level < level_max);

        Print(StringFormat(
            "%s \t\t %s - Level [ < %s ]",
            (string)level_valid,
            DoubleToString(price_level, _Digits),
            DoubleToString(level_max, _Digits)));

        return level_valid;
    }



    bool is_valid_index(StructureBlock& block) {
        int max_index = this.args.mean_reversion.analysis_pivot_point_strength + 1;
        int block_index = block.end.rate_index;
        bool valid_index = (block_index <= max_index);

        /* TODO
        Print(StringFormat(
            "%s - Index [ %s ] - %s",
            (string)valid_index,
            IntegerToString(max_index),
            IntegerToString(block_index)));


        return valid_index;
    }

    void place_order(StructureBlock& block) {

        Print("Placing order");

        MqlTick tick;
        SymbolInfoTick(_Symbol, tick);

        bool block_bullish = block.is_bullish();
        ENUM_ORDER_TYPE order = block_bullish ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
        double price = (order == ORDER_TYPE_BUY) ? tick.ask : tick.bid;
        double sl = block.get_end_price();
        double rr = this.args.mean_reversion.risk_reward_ratio;
        double volume = get_trade_volume(price, sl);
        double tp =
            MarketOrder::get_take_profit_price(order, sl, price, rr);

        this.trade(order, volume, price, sl, tp);

        this.lastest_reversion_time = RatesUtils::get_rate_time(block.end.rate_index);
    }

    double get_trade_volume(double entry_price, double stop_loss) {
        // TODO
        return 0.01;
    }


    // ----------------------------

    void process_new_rate() {

        delete_market_analysis();
        set_market_analysis();

        // TODO
        return;

        set_bollinger_bands_values();

        if (MarketOrder::has_open_positions(this.magic_number)) {
            return;
        }

        int rate_index = this.args.mean_reversion.analysis_lowest_index;
        datetime prev_date = RatesUtils::get_rate_time(rate_index);

        if (this.last_date == prev_date)
            return;

        double prev_high = RatesUtils::get_rate_highest_price(rate_index, true);
        double prev_low = RatesUtils::get_rate_lowest_price(rate_index, true);

        bool upper_ext = (prev_high >= this.upper_band);
        bool lower_ext = (prev_low <= this.lower_band);

        if (!upper_ext && !lower_ext)
            return;

        ENUM_RSI_EXTENSION rsi_ext = RSI::get_rsi_extension(
            prev_date,
            this.args.mean_reversion.rsi_threshold_top,
            this.args.mean_reversion.rsi_threshold_bottom
            //
        );
        if (rsi_ext == RSI_NONE_EXT)
            return;

        MqlTick tick;
        SymbolInfoTick(_Symbol, tick);

        double volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

        ENUM_ORDER_TYPE order = upper_ext ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
        double price = upper_ext ? tick.bid : tick.ask;
        double sl = upper_ext ? prev_high : prev_low;
        double tp = upper_ext ? lower_band : upper_band;

        this.current_ticket = this.trade(order, volume, price, sl, tp);
        this.last_date = prev_date;
    }

    void set_tp_level() {
        if (this.current_ticket == 0 ||
            !PositionSelectByTicket(this.current_ticket))
            return;

        double open = PositionGetDouble(POSITION_PRICE_OPEN);
        double sl = PositionGetDouble(POSITION_SL);
        double tp = PositionGetDouble(POSITION_TP);
        double price = PositionGetDouble(POSITION_PRICE_CURRENT);
        double profit = PositionGetDouble(POSITION_PROFIT);

        if ((profit < 0) || (this.base_band == sl))
            return;

        bool buy = (price > open);
        bool buy_trailing = buy && (price > this.base_band);
        bool sell_trailing = !buy && (price < this.base_band);

        if (buy_trailing || sell_trailing)
            this.ctrade.PositionModify(this.current_ticket, this.base_band, tp);
    }

    void process_new_rate() {

        if (MarketOrder::has_open_positions(this.magic_number))
            return;

        double today_profit = MarketOrder::get_today_profit();
        Print("today_profit ", today_profit);
        if (today_profit >= 10)
            return;

        delete_market_analysis();
        set_market_analysis();

        PivotPoint pivot;
        MarketPivot::get_last_pivot(pivot, PIVOT_ORDER_1);

        int max_index = this.args.mean_reversion.analysis_lowest_index + 1;
        if (pivot.rate_index > max_index)
            return;

        datetime pivot_date = RatesUtils::get_rate_time(pivot.rate_index);
        double pivot_price = MarketPivot::get_pivot_price(pivot, true);

        ENUM_BOLLINGER_BANDS_EXT bb_ext =
            BollingerBands::get_bollinger_extension(pivot_date, pivot_price);
        if (bb_ext == BB_NONE_EXT)
            return;

        ENUM_RSI_EXTENSION rsi_ext = RSI::get_rsi_extension(
            pivot_date,
            this.args.mean_reversion.rsi_top_threshold,
            this.args.mean_reversion.rsi_bottom_threshold);
        if (rsi_ext == RSI_NONE_EXT)
            return;

        bool buy = ((bb_ext == BB_LOWER_BAND_EXT) && (rsi_ext == RSI_OVERSOLD_EXT));
        bool sell = ((bb_ext == BB_UPPER_BAND_EXT) && (rsi_ext == RSI_OVERBOUGHT_EXT));
        if (!buy && !sell)
            return;

        ENUM_ORDER_TYPE order = buy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
        double sl = pivot_price;

        trade(order, sl);
    }

    void trade(ENUM_ORDER_TYPE order, double sl) {

        MqlTick tick;
        SymbolInfoTick(_Symbol, tick);

        double volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

        bool buy = (order == ORDER_TYPE_BUY);
        double price = buy ? tick.ask : tick.bid;

        double rr = this.args.mean_reversion.risk_reward_ratio;
        double tp = MarketOrder::get_take_profit_price(
            order, sl, price, rr);

        if (buy)
            this.trade_buy(volume, price, sl, tp);
        else
            this.trade_sell(volume, price, sl, tp);
    }

    void get_structure_block_screenshot(
        StructureBlock& src, StructureBlockScreenshot& dest) {

        TrendType trend_type = src.get_trend_type();
        datetime start_date = RatesUtils::get_rate_time(src.start.rate_index);
        datetime end_date = RatesUtils::get_rate_time(src.end.rate_index);

        dest.trend_type = trend_type;
        dest.start_date = start_date;
        dest.end_date = end_date;
    }

    void set_last_block(StructureBlockScreenshot& new_block_screenshot) {
        this.last_block_screenshot = new_block_screenshot;
    }

    void process_new_block(StructureBlock& block) {

        Print("----");

        // RSI
        if (!has_rsi_extension(block))
            return;

        // Bollinger Bands
        double block_end_price = block.get_end_price();
        if (!has_bollinger_extension(block))
            return;

        MqlTick tick;
        SymbolInfoTick(_Symbol, tick);

        ENUM_ORDER_TYPE order = block.is_bullish() ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
        double entry_price = (order == ORDER_TYPE_BUY) ? tick.ask : tick.bid;

        // Entry level
        if (!is_entry_level(block, entry_price))
            return;

        double sl = block.get_end_price();
        trade(order, sl, entry_price);
    }

    bool has_rsi_extension(StructureBlock& block) {
        int rate_index = block.end.rate_index;
        datetime rsi_date = RatesUtils::get_rate_time(rate_index);
        double rsi_value = RSI::get_rsi_value(rsi_date);
        Print("rsi_value ", rsi_value, " at ", rsi_date);

        bool top_ext = (rsi_value >= this.args.mean_reversion.rsi_top_threshold);
        bool bottom_ext = (rsi_value <= this.args.mean_reversion.rsi_bottom_threshold);

        return (top_ext || bottom_ext);
    }

    bool has_bollinger_extension(StructureBlock& block) {
        int rate_index = block.end.rate_index;
        double block_end_price = block.get_end_price();

        datetime bb_date = RatesUtils::get_rate_time(rate_index);
        double upper_band, base_band, lower_band, width_band;

        BollingerBands::get_bollinger_bands_values(
            bb_date, upper_band, base_band, lower_band, width_band);

        bool upper_ext = block.is_bullish() && (block_end_price >= upper_band);
        bool lower_ext = block.is_bearish() && (block_end_price <= lower_band);
        Print("bb_upper_ext ", upper_ext, " bb_lower_ext ", lower_ext);

        return (upper_ext || lower_ext);
    }

    bool is_entry_level(StructureBlock& block, double entry_price) {
        double entry_level = get_entry_level(block, entry_price);
        Print("entry_price ", entry_price, " entry_level ", entry_level, " %");
        return (entry_level <= this.args.mean_reversion.entry_level_max);
    }



    void metodo() {

        Print("-----");

        if (MarketOrder::has_open_positions(this.magic_number))
            return;

        StructureBlock block;
        get_latest_valid_block(block);

        if (!block.is_valid()) {
            Print("No valid block");
            return;
        }

        int rate_index = block.end.rate_index;

        if (rate_index > 10) {
            Print("Old rate index ", rate_index);
            return;
        }

        bool bullish = block.is_bullish();
        double close = bullish
                           ? RatesUtils::get_rate_highest_price(rate_index, true)
                           : RatesUtils::get_rate_lowest_price(rate_index, true);

        bool traded = this.last_close_traded == close;
        Print("Close ", close, " traded ", traded);
        if (traded)
            return;

        double rsi = MathFloor(get_RSI(rate_index));
        bool over_buy = (rsi >= 65);
        bool over_sell = (rsi <= 25);

        Print("RSI: ", rsi, " over_buy ", over_buy, " over_sell ", over_sell);

        double upper_band, middle_band, lower_band;
        get_bollinger_bands(rate_index, upper_band, middle_band, lower_band);
        bool upper_ext = (close > upper_band);
        bool lower_ext = (close < lower_band);

        Print("Bollinger: upper_ext ", upper_ext, " lower_ext ", lower_ext);

        bool sell = bullish && over_buy; // && upper_ext;
        bool buy = !bullish && over_sell; // && lower_ext;

        Print("sell ", sell, " buy ", buy);

        if (!sell && !buy)
            return;

        Print("Trade!");

        ENUM_ORDER_TYPE order_type = sell ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
        trade(order_type, close);
    }

    void trade(ENUM_ORDER_TYPE order_type, double sl) {

        MqlTick tick;
        SymbolInfoTick(_Symbol, tick);

        double volume = 0.01;
        double entry = order_type == ORDER_TYPE_BUY ? tick.ask : tick.bid;
        double rr = 1.0;
        double tp = get_take_profit_price(order_type, entry, sl, rr);

        if (order_type == ORDER_TYPE_BUY)
            this.ctrade.Buy(volume, _Symbol, entry, sl, tp, "BUY");

        if (order_type == ORDER_TYPE_SELL)
            this.ctrade.Sell(volume, _Symbol, entry, sl, tp, "SELL");

        this.last_close_traded = sl;
    }

    void get_bollinger_bands(
        int rate_index,
        double& upper_band, double& middle_band, double& lower_band) {

        string symbol = _Symbol;
        ENUM_TIMEFRAMES period = _Period;
        int bands_period = 20;
        int bands_shift = 0;
        double deviation = 2.0;
        ENUM_APPLIED_PRICE applied_price = PRICE_CLOSE;

        int handler = iBands(symbol, period, bands_period, bands_shift, deviation, applied_price);

        double middle[];
        double upper[];
        double lower[];

        int const MIDDLE_BUFFER_NUMBER = 0;
        int const UPPER_BUFFER_NUMBER = 1;
        int const LOWER_BUFFER_NUMBER = 2;
        int const AMOUNT = 1;

        CopyBuffer(handler, MIDDLE_BUFFER_NUMBER, rate_index, AMOUNT, middle);
        CopyBuffer(handler, UPPER_BUFFER_NUMBER, rate_index, AMOUNT, upper);
        CopyBuffer(handler, LOWER_BUFFER_NUMBER, rate_index, AMOUNT, lower);

        upper_band = upper[0];
        middle_band = middle[0];
        lower_band = lower[0];
    }

    double get_RSI(int rate_index) {

        int ma_period = 14;
        ENUM_APPLIED_PRICE applied_price = PRICE_CLOSE;

        int handler = iRSI(
            _Symbol,
            _Period,
            ma_period,
            applied_price
            // asdas
        );

        double rsi[];
        int const AMOUNT = 1;
        int const RSI_BUFFER_NUMBER = 0;

        CopyBuffer(handler, RSI_BUFFER_NUMBER, rate_index, AMOUNT, rsi);

        return rsi[0];
    }

    double get_take_profit_price(
        ENUM_ORDER_TYPE order_type, double entry, double sl, double risk_reward_ratio) {

        if (entry == 0.0 || sl == 0.0)
            return 0.0;

        double distance = MathAbs(entry - sl);
        double tp_distance = distance * risk_reward_ratio;

        double tp = 0.0;

        if (order_type == ORDER_TYPE_BUY)
            tp = entry + tp_distance;

        else if (order_type == ORDER_TYPE_SELL)
            tp = entry - tp_distance;

        return NormalizeDouble(tp, _Digits);
    }

    void get_latest_valid_block(StructureBlock& dest) {
        dest.clear();

        StructureBlock blocks[];
        MarketStructure::get_latest_blocks(blocks, 1);

        if (!are_valid_blocks(blocks))
            return;

        ArrayUtils::get_last_item(dest, blocks);
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
        }

        return true;
    }

    -----------------------------------------

    void on_new_rate() {
        Print("Mean reversion");
        simulate_trade();
    }

    void on_timer() {

        ulong tickets[];
        MarketOrder::get_open_positions(tickets, this.magic_number);

        if (ArraySize(tickets) > 0) {
            Print("Tickets ", ArraySize(tickets));

            for (int i = 0; i < ArraySize(tickets); i++) {
                ulong ticket = tickets[i];
                PositionSelectByTicket(ticket);

                double profit = PositionGetDouble(POSITION_PROFIT);
                Print("ticket ", ticket, " Profit ", profit);

                if (profit > 0) {
                    this.ctrade.PositionClose(ticket);
                    profit_counter += profit;
                }
            }
        }
    }

        double profit_counter;

    void simulate_trade() {

        double risk = 20.0;

        if ((profit_counter) >= (risk * 3))
            return;

        if (MarketOrder::has_open_positions(this.magic_number))
            return;

        MqlTick tick;
        SymbolInfoTick(_Symbol, tick);

        ENUM_ORDER_TYPE action = ORDER_TYPE_BUY;
        double volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

        double price_open = ORDER_TYPE_BUY ? tick.ask : tick.bid;
        double price_close = 64311.88;
        double profit = 0.0;

        bool calc = OrderCalcProfit(
            action,
            _Symbol,
            volume,
            price_open,
            price_close,
            profit);

        double max_trades = 10;
        double potencial = MathFloor(MathAbs((risk / profit)));
        double trades = MathMin(max_trades, potencial);

        Print("Vol min: ", volume, " Profit ", profit, " Trades ", trades);

        for (int i = 1; i <= trades; i++) {
            ctrade.Sell(volume, _Symbol, price_open, price_close,
                        0, "Trade " + IntegerToString(i));
        }
    }

    -------------------------
        void hft_method() {

        if (MarketOrder::has_open_positions(this.magic_number))
            return;

        StructureBlock block;
        get_latest_valid_block(block);

        if (!block.is_valid())
            return;

        int rate_index = block.end.rate_index;

        bool bullish = block.is_bullish();
        double close = bullish
                           ? RatesUtils::get_rate_highest_price(rate_index, true)
                           : RatesUtils::get_rate_lowest_price(rate_index, true);

        ENUM_ORDER_TYPE order_type = bullish ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;

        trade(order_type, close);
    }

    void get_latest_valid_block(StructureBlock& dest) {
        dest.clear();

        StructureBlock blocks[];
        MarketStructure::get_latest_blocks(blocks, 1);

        TrendType bias = blocks[0].get_trend_type();
        for (int i = 0; i < ArraySize(blocks); i++) {
            if (blocks[i].get_trend_type() != bias)
                return;
        }

        ArrayUtils::get_last_item(dest, blocks);
    }

    void trade(ENUM_ORDER_TYPE order_type, double sl) {

        MqlTick tick;
        SymbolInfoTick(_Symbol, tick);

        double volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
        double entry = (order_type == ORDER_TYPE_BUY) ? tick.ask : tick.bid;
        int trades = get_trades_amount(order_type, volume, entry, sl);

        for (int i = 1; i <= trades; i++) {
            if (order_type == ORDER_TYPE_BUY)
                this.ctrade.Buy(volume, _Symbol, entry, sl, 0, StringFormat("Buy %d", i));
            else
                this.ctrade.Sell(volume, _Symbol, entry, sl, 0, StringFormat("Sell %d", i));
        }
    }

    int get_trades_amount(
        ENUM_ORDER_TYPE order_type, double volume, double entry, double sl) {

        double profit, risk = 10.0;
        ENUM_ORDER_TYPE action = (order_type == ORDER_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;

        bool calc = OrderCalcProfit(
            action, _Symbol, volume, entry, sl, profit);

        double max_trades = 10;
        double potencial = MathFloor(MathAbs((risk / profit)));

        return (int)MathMin(max_trades, potencial);
    }
*/
