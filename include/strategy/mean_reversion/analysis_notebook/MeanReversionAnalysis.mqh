#include "../../../dto/Structure.mqh"

#include "../../../indicators/RSI.mqh"

#include "../../../utils/ArrayUtils.mqh"
#include "../../../utils/ChartUtils.mqh"
#include "../../../utils/RatesUtils.mqh"

#include "../../../market/MarketPivot.mqh"
#include "../../../market/MarketStructure.mqh"

struct EntryInfo {
    datetime time;
    double price;
    double level;
    double sl;
    ENUM_ORDER_TYPE type;

    double max_rr_value;
    datetime max_rr_time;

    bool hit_sl_value;
    datetime hit_sl_time;

    EntryInfo() {
        time = 0;
        price = 0;
        level = 0;
        sl = 0;
        max_rr_value = 0;
        max_rr_time = 0;
        hit_sl_value = false;
        hit_sl_time = 0;
    }
};

class MeanReversionAnalysis : public MeanReversion {

  public:
    MeanReversionAnalysis(AdvisorArgs& args_data)
        : MeanReversion(args_data) {
        this.handler_log = INVALID_HANDLE;
        this.log_filename_base = "mean_reversion_%s.csv";
    }

  protected:
    string log_filename_base;
    string log_header;

    int handler_log;

    StructureBlock last_block;

    void init() override {
        MeanReversion::init();
        set_log_header();
        open_log();
        // TODO
        // clear_last_screenshot();
    }

    void deinit() override {
        MeanReversion::deinit();
        close_log();
    }

    void set_log_header() {
        this.log_header =

            // General
            "symbol;"
            "timeframe;"
            "setup_time;"
            "session;"

            // Current block
            "current_block_pivot_strength;"
            "current_block_type;"
            "current_block_start_price;"
            "current_block_end_price;"

            // Bollinger
            "bb_period;"
            "bb_upper_band;"
            "bb_middle_band;"
            "bb_lower_band;"
            "bb_width_size;"
            "bb_width_pct;"
            "bb_break_size;"
            "bb_break_pct;"
            "bb_extension;"

            // RSI
            "rsi_ma_period;"
            "rsi_threshold_top;"
            "rsi_threshold_bottom;"
            "rsi_value;"
            "rsi_extension;"

            // Entry
            "entry_date;"
            "entry_delay;"
            "entry_type;"
            "entry_price;"
            "entry_level;"
            "entry_sl;"
            "entry_rr_max;"
            "entry_hit_sl"
            //
            ;
    }

    void open_log() {
        // Append = FILE_READ | FILE_WRITE | FILE_CSV | FILE_COMMON);
        // Overwrite = FILE_WRITE | FILE_CSV | FILE_COMMON);
        this.handler_log = FileOpen(
            this.get_log_filename(),
            FILE_WRITE | FILE_CSV | FILE_COMMON);
        write_log(this.log_header);
    }

    void write_log(string log_msg) {
        if (this.handler_log != INVALID_HANDLE) {
            FileSeek(this.handler_log, 0, SEEK_END);
            FileWrite(this.handler_log, log_msg);
        }
    }

    void close_log() {
        if (this.handler_log != INVALID_HANDLE)
            FileClose(this.handler_log);
    }

    string get_log_filename() {
        string file_template = StringFormat(
            "m%s_ps%s_rd%s_bb%s_rsi%s",
            IntegerToString(_Period),
            IntegerToString(this.args.mean_reversion.analysis_pivot_point_strength),
            IntegerToString(this.args.mean_reversion.analysis_rate_delay),
            IntegerToString(this.args.mean_reversion.bollinger_period),
            IntegerToString(this.args.mean_reversion.rsi_ma_period)
            //
        );
        return StringFormat(this.log_filename_base, file_template);
    }

    void process_new_rate() override {

        delete_market_analysis();
        set_market_analysis();

        StructureBlock new_block;
        if (!get_block_for_analysis(new_block) || !new_block.is_valid()) {
            Print("Not valid new block");
            return;
        }

        if (new_block.is_equal(this.last_block)) {
            Print("Already analyzed block");
            return;
        }

        analyze_block(new_block);
        this.last_block = new_block;
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

    bool get_block_for_analysis(StructureBlock& dest) {
        dest.clear();

        StructureBlock blocks[];
        MarketStructure::get_latest_blocks(
            blocks, this.args.mean_reversion.analysis_block_amount);

        if (ArraySize(blocks) == 0)
            return false;

        dest = blocks[0];
        return true;
    }

    void analyze_block(StructureBlock& block) {

        if (!block.is_valid())
            return;

        Print("Analyzing new block");

        datetime setup_time = block.end.rate_time;
        double setup_price = block.end.rate_price;

        int analysis_start_index = 0;
        int analysis_end_index = 0;
        get_analysis_indexes(setup_time, analysis_start_index, analysis_end_index);

        MqlRates entry_rate;
        RatesUtils::get_rate(entry_rate, analysis_start_index);

        // Entry
        EntryInfo entry_info;
        entry_info.time = RatesUtils::get_rate_time(analysis_start_index);
        entry_info.price = entry_rate.open;
        entry_info.sl = setup_price;
        entry_info.type = block.is_bullish() ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;

        set_entry_level(block, entry_info);
        set_outcome(analysis_start_index, analysis_end_index, entry_info);

        // Bollinger
        BollingerBandsValues bb_values;
        get_bollinger_bands_values(setup_time, bb_values);
        bool bb_extension = is_bollinger_extension(setup_time, setup_price);

        // RSI
        double rsi_value = 0.0;
        get_rsi_value(setup_time, rsi_value);
        bool rsi_extension = is_rsi_extension(setup_time);

        // ----
        ChartUtils::create_chart_object(OBJ_VLINE, "block", setup_time);

        ChartUtils::create_chart_object(OBJ_VLINE, "start", RatesUtils::get_rate_time(analysis_start_index));
        ObjectSetInteger(0, "start", OBJPROP_COLOR, clrBlue);

        ChartUtils::create_chart_object(OBJ_VLINE, "end", RatesUtils::get_rate_time(analysis_end_index));
        ObjectSetInteger(0, "end", OBJPROP_COLOR, clrBlue);

        ChartUtils::create_chart_object(OBJ_VLINE, "RR", entry_info.max_rr_time);
        ObjectSetInteger(0, "RR", OBJPROP_COLOR, clrDarkCyan);

        ChartUtils::create_chart_object(OBJ_VLINE, "SL", entry_info.hit_sl_time);
        ObjectSetInteger(0, "SL", OBJPROP_COLOR, clrDarkCyan);

        // ---- Log Info
        string log_msg = this.log_header;
        log_general_info(log_msg, setup_time);
        log_block_info(log_msg, block);
        log_bb_bands_info(log_msg, bb_values, bb_extension);
        log_rsi_info(log_msg, rsi_value, rsi_extension);
        log_entry_info(log_msg, entry_info);

        write_log(log_msg);
    }

    void get_analysis_indexes(
        datetime time,
        int& analysis_start_index, int& analysis_end_index) {

        analysis_start_index = 0;
        analysis_end_index = 0;

        int block_index = iBarShift(_Symbol, _Period, time);
        int rate_delay = this.args.mean_reversion.analysis_rate_delay + 1;

        // int start_index = block_index - this.args.mean_reversion.analysis_pivot_point_strength - rate_delay;
        int start_index = block_index - rate_delay;
        int end_index = this.args.mean_reversion.analysis_lowest_index;

        analysis_start_index = start_index;
        analysis_end_index = end_index;

        // TODO
        /*
        double top = block.get_top_price();
        double bottom = block.get_bottom_price();

        int top_break = get_top_break_index(top, start_index, end_index);
        int bottom_break = get_bottom_break_index(bottom, start_index, end_index);

        if ((top_break < 0) && (bottom_break < 0)) {
            Print("IT HAS NOT BREAK");
            return;
        }

        analysis_start_index = start_index;

        if (top_break > 0 && bottom_break > 0)
            analysis_end_index = (top_break > bottom_break) ? top_break : bottom_break;
        else
            analysis_end_index = top_break > 0 ? top_break : bottom_break;
        */
    }

    void set_entry_level(StructureBlock& block, EntryInfo& entry_info) {
        if (entry_info.price != 0)
            entry_info.level = get_price_level(block, entry_info.price);
    }

    void set_outcome(
        int analysis_start_index, int analysis_end_index, EntryInfo& entry_info) {

        MqlRates rate;
        for (int i = analysis_start_index; i >= analysis_end_index; i--) {

            RatesUtils::get_rate(rate, i);
            double prices[] = {rate.open, rate.high, rate.low, rate.close};

            for (int j = 0; j < ArraySize(prices); j++) {

                datetime time = RatesUtils::get_rate_time(i);
                double price = prices[j];

                if (hit_sl(entry_info, price)) {
                    entry_info.hit_sl_value = true;
                    entry_info.hit_sl_time = time;
                    return;
                }

                double reached_rr = get_reached_rr(entry_info, price);
                if (reached_rr > entry_info.max_rr_value) {
                    entry_info.max_rr_value = reached_rr;
                    entry_info.max_rr_time = time;
                }
            }
        }
    }

    bool hit_sl(EntryInfo& entry_info, double price) {
        ENUM_ORDER_TYPE type = entry_info.type;
        double sl = entry_info.sl;

        if ((type == ORDER_TYPE_BUY) && (price <= sl))
            return true;

        if ((type == ORDER_TYPE_SELL) && (price >= sl))
            return true;

        return false;
    }

    double get_reached_rr(EntryInfo& entry_info, double price) {
        ENUM_ORDER_TYPE type = entry_info.type;
        double entry = entry_info.price;
        double sl = entry_info.sl;

        bool favor_buy = ((type == ORDER_TYPE_BUY) && (price > entry));
        bool favor_sell = ((type == ORDER_TYPE_SELL) && (price < entry));

        if (!favor_buy && !favor_sell)
            return 0.0;

        double rr_unit = MathAbs(entry - sl);
        double rr_partial = MathAbs(entry - price);
        double rr_total = (rr_partial / rr_unit);

        return NormalizeDouble(rr_total, _Digits);
    }

    void log_general_info(string& log_msg, datetime time) {
        StringReplace(log_msg, "symbol", _Symbol);
        StringReplace(log_msg, "timeframe", _Period);
        StringReplace(log_msg, "setup_time", time);

        ENUM_MARKET_SESSION session = MarketSession::get_session_by_time(time);
        StringReplace(log_msg, "session", EnumToString(session));
    }

    void log_block_info(
        string& log_msg, StructureBlock& block) {

        StringReplace(
            log_msg, "current_block_pivot_strength",
            IntegerToString(this.args.mean_reversion.analysis_pivot_point_strength));

        StringReplace(
            log_msg, "current_block_type",
            block.is_bullish() ? "BULLISH" : "BEARISH");

        StringReplace(
            log_msg, "current_block_start_price",
            DoubleToString(block.get_start_price(), _Digits));

        StringReplace(
            log_msg, "current_block_end_price",
            DoubleToString(block.get_end_price(), _Digits));
    }

    void log_entry_info(
        string& log_msg, EntryInfo& entry_info) {

        StringReplace(
            log_msg, "entry_date", entry_info.time);

        StringReplace(
            log_msg, "entry_delay",
            IntegerToString(this.args.mean_reversion.analysis_rate_delay));

        StringReplace(
            log_msg, "entry_type",
            EnumToString(entry_info.type));

        StringReplace(
            log_msg, "entry_price",
            DoubleToString(entry_info.price, _Digits));

        StringReplace(
            log_msg, "entry_level",
            DoubleToString(entry_info.level, _Digits));

        StringReplace(
            log_msg, "entry_sl",
            DoubleToString(entry_info.sl, _Digits));

        StringReplace(
            log_msg, "entry_rr_max",
            DoubleToString(entry_info.max_rr_value, _Digits));

        StringReplace(
            log_msg, "entry_hit_sl",
            (entry_info.hit_sl_value ? "true" : "false"));
    }

    void log_bb_bands_info(
        string& log_msg, BollingerBandsValues& bb_values, bool bb_extension) {
        StringReplace(
            log_msg, "bb_period",
            IntegerToString(this.args.mean_reversion.bollinger_period));
        StringReplace(
            log_msg, "bb_upper_band",
            DoubleToString(bb_values.upper_band, _Digits));
        StringReplace(
            log_msg, "bb_middle_band",
            DoubleToString(bb_values.middle_band, _Digits));
        StringReplace(
            log_msg, "bb_lower_band",
            DoubleToString(bb_values.lower_band, _Digits));
        StringReplace(
            log_msg, "bb_width_size",
            DoubleToString(bb_values.band_width_size, _Digits));
        StringReplace(
            log_msg, "bb_width_pct",
            DoubleToString(bb_values.band_width_pct, _Digits));
        StringReplace(
            log_msg, "bb_extension",
            (bb_extension ? "true" : "false"));

        /* TODO
        StringReplace(
            log_msg, "bb_break_size",
            DoubleToString(bb_break_size, _Digits));
        StringReplace(
            log_msg, "bb_break_pct",
            DoubleToString(bb_break_pct, _Digits));
        */
    }

    void log_rsi_info(
        string& log_msg, double rsi_value, bool rsi_extension) {
        StringReplace(
            log_msg, "rsi_ma_period",
            IntegerToString(this.args.mean_reversion.rsi_ma_period));
        StringReplace(
            log_msg, "rsi_threshold_top",
            DoubleToString(this.args.mean_reversion.rsi_threshold_top, _Digits));
        StringReplace(
            log_msg, "rsi_threshold_bottom",
            DoubleToString(this.args.mean_reversion.rsi_threshold_bottom, _Digits));
        StringReplace(
            log_msg, "rsi_value",
            DoubleToString(rsi_value, _Digits));
        StringReplace(
            log_msg, "rsi_extension",
            (rsi_extension ? "true" : "false"));
    }
};

/*
class MeanReversionAnalysis : public MeanReversion {





    StructureBlockScreenshot blocks_screenshot[];









    void clear_last_screenshot() {
        ArrayUtils::clear(this.blocks_screenshot);
    }

    void process_new_rate() override {



        StructureBlockScreenshot new_screenshot[];
        get_screenshot(latest_blocks, new_screenshot);

        bool same_screenshot = is_same_screenshot(
            this.blocks_screenshot, new_screenshot);
        // Print("same_screenshot ", same_screenshot);

        if (same_screenshot) {
            return;
        }

        analyze_screenshot(new_screenshot);
        ArrayUtils::copy(this.blocks_screenshot, new_screenshot);
    }

    int get_top_break_index(double top, int start_index, int end_index) {
        for (int i = start_index; i >= end_index; i--) {
            bool respected = RatesUtils::is_respected_price(
                start_index, i, top, true, true, 0);

            if (!respected)
                return i;
        }

        return -1;
    }

    int get_bottom_break_index(double bottom, int start_index, int end_index) {
        for (int i = start_index; i >= end_index; i--) {
            bool respected = RatesUtils::is_respected_price(
                start_index, i, bottom, false, true, 0);

            if (!respected)
                return i;
        }

        return -1;
    }

    void get_screenshot(StructureBlock& src[], StructureBlockScreenshot& dest[]) {
        ArrayUtils::clear(dest);

        for (int i = 0; i < ArraySize(src); i++) {
            StructureBlock block = src[i];
            StructureBlockScreenshot item = StructureBlockScreenshot(block);
            ArrayUtils::add_item(dest, item);
        }
    }

    bool is_same_screenshot(
        StructureBlockScreenshot& compare_A[], StructureBlockScreenshot& compare_B[]) {

        int size_a = ArraySize(compare_A);
        int size_b = ArraySize(compare_B);

        if (size_a != size_b)
            return false;

        for (int i = 0; i < size_a; i++) {
            StructureBlockScreenshot screen_A = compare_A[i];
            StructureBlockScreenshot screen_B = compare_B[i];

            if (!(screen_A.is_equal(screen_B)))
                return false;
        }

        return true;
    }

    void analyze_screenshot(StructureBlockScreenshot& new_screenshot[]) {

        if (ArraySize(new_screenshot) == 0)
            return;

        StructureBlockScreenshot screenshot = new_screenshot[0];
        datetime setup_time = screenshot.end_date;

        // TODO
        // ---- Bollinger Extension
        double bb_upper_band, bb_middle_band, bb_lower_band, bb_width_size, bb_width_pct;
        bool bb_result = BollingerBands::get_bollinger_bands_values(
            setup_time, INVALID_HANDLE,
            bb_upper_band, bb_middle_band, bb_lower_band,
            bb_width_size, bb_width_pct);

        bool block_bullish = screenshot.bullish;
        bool block_bearish = screenshot.bearish;
        double block_price = screenshot.end_price;

        bool upper_ext = block_bullish && (block_price >= bb_upper_band);
        bool lower_ext = block_bearish && (block_price <= bb_lower_band);

        double bb_break_size = upper_ext ? (block_price - bb_upper_band) : (bb_lower_band - block_price);
        double bb_break_pct = NormalizeDouble((bb_break_size / bb_width_size) * 100, _Digits);

        if (!upper_ext && !lower_ext)
            return;

        // TODO
        // ---- RSI Extension
        int rsi_ma_period = this.args.mean_reversion.rsi_ma_period;
        double rsi_threshold_top = this.args.mean_reversion.rsi_threshold_top;
        double rsi_threshold_bottom = this.args.mean_reversion.rsi_threshold_bottom;
        double rsi_value = 0.0;
        bool rsi_result = RSI::get_rsi_value(
            rsi_value, INVALID_HANDLE, setup_time);

        bool overbought = rsi_value >= rsi_threshold_top;
        bool oversold = rsi_value <= rsi_threshold_bottom;

        if (!overbought && !oversold)
            return;

        // ---- Entry
        int analysis_start_index = 0;
        int analysis_end_index = 0;
        get_analysis_indexes(screenshot, analysis_start_index, analysis_end_index);

        MqlRates entry_rate;
        RatesUtils::get_rate(entry_rate, analysis_start_index);

        datetime entry_date = RatesUtils::get_rate_time(analysis_start_index);
        ENUM_ORDER_TYPE entry_type = screenshot.bullish ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
        double entry_price = entry_rate.open;
        double entry_level = get_entry_level(screenshot, entry_price);
        double entry_sl = screenshot.end_price;

        // ---- Outcome
        double outcome_rr_max = 0;
        bool outcome_sl_hit = false;

        get_possible_outcome(
            analysis_start_index, analysis_end_index,
            entry_type, entry_price, entry_sl,
            outcome_rr_max, outcome_sl_hit);

        datetime time_start = RatesUtils::get_rate_time(analysis_start_index);
        datetime time_end = RatesUtils::get_rate_time(analysis_end_index);
        ChartUtils::create_chart_object(OBJ_VLINE, "block_start", screenshot.start_date, 0);
        ChartUtils::create_chart_object(OBJ_VLINE, "block_end", screenshot.end_date, 0);
        ChartUtils::create_chart_object(OBJ_VLINE, "analysis_start", time_start);
        ChartUtils::create_chart_object(OBJ_VLINE, "analysis_end", time_end);
        ObjectSetInteger(0, "analysis_start", OBJPROP_COLOR, clrBlue);
        ObjectSetInteger(0, "analysis_end", OBJPROP_COLOR, clrBlue);


    }



    double get_entry_level(StructureBlockScreenshot& screenshot, double entry_price) {
        double base_line = screenshot.bullish ? screenshot.get_top_price() : screenshot.get_bottom_price();
        double entry = MathAbs(entry_price - base_line);
        double block = screenshot.get_size();
        double level = (entry / block) * 100;
        return NormalizeDouble(level, _Digits);
    }








    void log_rsi_info(
        string& log_msg, int rsi_ma_period,
        double rsi_threshold_top, double rsi_threshold_bottom, double rsi_value) {

        StringReplace(
            log_msg, "rsi_ma_period",
            IntegerToString(rsi_ma_period, _Digits));
        StringReplace(
            log_msg, "rsi_threshold_top",
            DoubleToString(rsi_threshold_top, _Digits));
        StringReplace(
            log_msg, "rsi_threshold_bottom",
            DoubleToString(rsi_threshold_bottom, _Digits));
        StringReplace(
            log_msg, "rsi_value",
            DoubleToString(rsi_value, _Digits));
    }



    void log_outcome_info(
        string& log_msg, double outcome_rr_max, bool outcome_sl_hit) {

        StringReplace(
            log_msg, "outcome_rr_max",
            DoubleToString(outcome_rr_max, _Digits));
        StringReplace(
            log_msg, "outcome_sl_hit",
            outcome_sl_hit);
    }
};
*/