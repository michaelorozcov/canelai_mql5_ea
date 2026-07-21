#include "./../../../include/dto/Structure.mqh"

#include "./../../../include/dto/args_input/AdvisorArgs.mqh"

#include "./../../../include/utils/Constants.mqh"
#include "./../../../include/utils/LogUtils.mqh"
#include "./../../../include/utils/RatesUtils.mqh"

#include "./../../../include/indicators/BollingerBands.mqh"
#include "./../../../include/indicators/RSI.mqh"

#include "./../../../include/market/MarketPivot.mqh"
#include "./../../../include/market/MarketStructure.mqh"

#include "./../../../include/strategy/block_reversion/BlockReversion.mqh"

struct ExcursionInfo {

    double price;
    double distance;
    int bars;

    ExcursionInfo() {
        price = 0.0;
        distance = 0.0;
        bars = 0;
    }
};

enum ExcursionType {
    MAE,
    MFE
};

struct EntryInfo {

    double price;
    double blocks;
    ENUM_ORDER_TYPE order;

    ExcursionInfo mfe; // Max. Favorable Excursion
    ExcursionInfo mae; // Max. Adverse Excursion

    EntryInfo() {
        price = 0.0;
        blocks = 0.0;
    }
};

const ENUM_RSI_PERIOD rsi_periods[] = {
    RSI_PERIOD_7,
    RSI_PERIOD_14,
    RSI_PERIOD_20,
};
struct IndicatorRSI {
    ENUM_RSI_PERIOD period;
    int handler;
};

const ENUM_BOLLINGER_PERIOD bb_periods[] = {
    BB_PERIOD_7,
    BB_PERIOD_14,
    BB_PERIOD_20,
};
struct IndicatorBB {
    ENUM_BOLLINGER_PERIOD period;
    int handler;
};

// Strategy: Data Analyzer
class BlockReversionAnalysis : public BlockReversion {

  public:
    BlockReversionAnalysis(AdvisorArgs& param_args, string param_advisor_id)
        : BlockReversion(param_args, param_advisor_id) {

        this.analysis_blocks = 3;
        this.csv_filename = get_csv_filename();
        this.csv_handler = get_csv_handler();
        this.csv_header = get_csv_header();

        init_indicator_rsi();
        init_indicator_bb();

        open_csv_file();
    }

    ~BlockReversionAnalysis() {

        deinit_indicator_rsi();
        deinit_indicator_bb();

        close_csv_file();
    }

  protected:
    void on_new_rate() override {
        process_new_rate();
    }

  private:
    int analysis_blocks;

    int csv_handler;
    string csv_filename;
    string csv_header;

    IndicatorRSI indicator_rsi[];
    IndicatorBB indicator_bb[];

    void open_csv_file() {
        write_csv_record(this.csv_header);
    }

    void write_csv_record(string log_msg) {
        if (this.csv_handler == INVALID_HANDLE) {
            Print("write_csv_record: Not valid handler");
            return;
        }

        FileSeek(this.csv_handler, 0, SEEK_END);
        FileWrite(this.csv_handler, log_msg);
    }

    void close_csv_file() {
        if (this.csv_handler != INVALID_HANDLE)
            FileClose(this.csv_handler);
    }

    string get_csv_filename() {
        return (StringFormat(
            "csv_files/%s_%s_%s_pivot_%s_rsi_%s_bollinger_%s.csv",
            get_str_strategy(),
            get_str_symbol(),
            get_str_period(),
            get_str_pivot_strength(),
            get_str_rsi(),
            get_str_bollinger()
            //
            ));
    }

    string get_str_strategy() {
        return EnumToString(this.args.general.strategy);
    }

    string get_str_symbol() {
        return _Symbol;
    }

    string get_str_period() {
        string base = EnumToString(_Period);
        int index = StringFind(base, "_") + 1;
        return StringSubstr(base, index);
    }

    string get_str_pivot_strength() {
        return IntegerToString(this.args.block_reversion.pivot_point_strength);
    }

    string get_str_bollinger() {
        string base = EnumToString((ENUM_BOLLINGER_PERIOD)this.args.block_reversion.bollinger_period);
        int index = StringFind(base, "_", 5) + 1;
        return StringSubstr(base, index);
    }

    string get_str_rsi() {
        string base = EnumToString((ENUM_RSI_PERIOD)this.args.block_reversion.rsi_period);
        int index = StringFind(base, "_", 5) + 1;
        return StringSubstr(base, index);
    }

    int get_csv_handler() {
        // Append = FILE_READ | FILE_WRITE | FILE_CSV | FILE_COMMON);
        // Overwrite = FILE_WRITE | FILE_CSV | FILE_COMMON);
        return FileOpen(
            this.csv_filename,
            (FILE_WRITE | FILE_CSV | FILE_COMMON | FILE_ANSI),
            ';', CP_UTF8);
    }

    string get_csv_header() {

        string base_header =
            // General
            "gral_symbol;"
            "gral_period;"
            "gral_session;"
            "gral_setup_time;"

            "|;"

            // Block
            "block_pivot_strength;"
            "block_type;"
            "block_size;"

            "|;"

            // Entry
            "entry_price;"
            "entry_order;"
            "entry_blocks;"

            "|;"

            // Max. Adverse Excursion
            "mae_price;"
            "mae_distance;"
            "mae_bars;"

            "|;"

            // Max. Favorable Excursion
            "mfe_price;"
            "mfe_distance;"
            "mfe_bars;"

            "|;"

            // RSI Indicator
            "rsi_value;"

            "|;"

            // Bollinger Indicator
            "bb_value;"

            // Close
            "|";

        // RSI header
        string rsi_value = "";
        for (int i = 0; i < ArraySize(rsi_periods); i++) {
            rsi_value += (EnumToString(rsi_periods[i]) + ";");
        }
        StringReplace(base_header, "rsi_value;", rsi_value);

        // BB header
        string bb_value = "";
        for (int i = 0; i < ArraySize(bb_periods); i++) {
            bb_value += (EnumToString(bb_periods[i]) + ";");
        }
        StringReplace(base_header, "bb_value;", bb_value);

        return base_header;
    }

    void init_indicator_rsi() {
        ArrayUtils::clear(this.indicator_rsi);
        for (int i = 0; i < ArraySize(rsi_periods); i++) {
            ENUM_RSI_PERIOD period = rsi_periods[i];
            IndicatorRSI new_rsi = {
                period,
                RSI::get_rsi_handler(period)};
            ArrayUtils::add_item(this.indicator_rsi, new_rsi);
        }
    }

    void deinit_indicator_rsi() {
        for (int i = 0; i < ArraySize(this.indicator_rsi); i++) {
            int handler = this.indicator_rsi[i].handler;
            if (handler != INVALID_HANDLE)
                IndicatorRelease(handler);
        }
        ArrayUtils::clear(this.indicator_rsi);
    }

    void init_indicator_bb() {
        ArrayUtils::clear(this.indicator_bb);
        for (int i = 0; i < ArraySize(bb_periods); i++) {
            ENUM_BOLLINGER_PERIOD period = bb_periods[i];
            IndicatorBB new_bb = {
                period,
                BollingerBands::get_bollinger_handler(period)};
            ArrayUtils::add_item(this.indicator_bb, new_bb);
        }
    }

    void deinit_indicator_bb() {
        for (int i = 0; i < ArraySize(this.indicator_bb); i++) {
            int handler = this.indicator_bb[i].handler;
            if (handler != INVALID_HANDLE)
                IndicatorRelease(handler);
        }
        ArrayUtils::clear(this.indicator_bb);
    }

    void process_new_rate() {
        delete_market_analysis();
        set_market_analysis();
        analyze_blocks();
    }

    void analyze_blocks() {

        StructureBlock blocks[];
        MarketStructure::get_latest_blocks(blocks, this.analysis_blocks);

        if (ArraySize(blocks) != this.analysis_blocks) {
            log("Not valid analysis_blocks amount");
            return;
        }

        StructureBlock block;
        block = blocks[0];

        if (!block.is_valid()) {
            log("Not valid block to analysis");
            return;
        }

        if (has_been_traded(block)) {
            return;
        }

        set_block_data(block);

        int start_index, end_index;
        get_analysis_indexes(blocks, start_index, end_index);

        EntryInfo entry_info;
        set_entry_info(entry_info, block, start_index);
        set_mfe_info(entry_info, start_index, end_index);
        set_mae_info(entry_info, start_index, (start_index - entry_info.mfe.bars));

        string log_msg = this.csv_header;
        log_gral_info(log_msg);
        log_block_info(log_msg);
        log_entry_info(log_msg, entry_info);
        log_mae_info(log_msg, entry_info);
        log_mfe_info(log_msg, entry_info);
        log_rsi_info(log_msg);
        log_bollinger_info(log_msg);

        Print(log_msg);

        write_csv_record(log_msg);

        // ---- TODO ----

        if (this.args.general.visual_mode) {
            datetime start_time, end_time;
            start_time = RatesUtils::get_rate_time(start_index);
            end_time = RatesUtils::get_rate_time(end_index);

            ChartUtils::create_chart_object(OBJ_VLINE, "start", start_time);
            ObjectSetInteger(0, "start", OBJPROP_COLOR, clrBlack);
            ChartUtils::create_chart_object(OBJ_VLINE, "end", end_time);
            ObjectSetInteger(0, "end", OBJPROP_COLOR, clrBlack);

            ChartUtils::create_chart_object(OBJ_TEXT, "entry", start_time, entry_info.price);
            ObjectSetString(0, "entry", OBJPROP_TEXT, DoubleToString(entry_info.blocks));

            ChartUtils::create_chart_object(OBJ_HLINE, "MFE", 0, entry_info.mfe.price);
            ObjectSetInteger(0, "MFE", OBJPROP_COLOR, clrGreen);

            ChartUtils::create_chart_object(OBJ_HLINE, "MAE", 0, entry_info.mae.price);
            ObjectSetInteger(0, "MAE", OBJPROP_COLOR, clrRed);
        }
    }

    void get_analysis_indexes(
        StructureBlock& blocks[], int& start_index, int& end_index) {

        start_index = (this.last_block_data.end_index -
                       get_pivot_strength_delay());
        end_index = 0;

        StructureBlock latest;
        ArrayUtils::get_last_item(latest, blocks);

        if (latest.is_valid()) {
            end_index = latest.end.rate_index;
        }

        if (has_same_block_type(blocks[0], blocks[1])) {
            end_index = blocks[1].end.rate_index;
        }
    }

    int get_pivot_strength_delay() {
        return (this.args.block_reversion.pivot_point_strength + 1);
    }

    bool has_same_block_type(StructureBlock& block_A, StructureBlock& block_B) {
        return (block_A.get_trend_type() == block_B.get_trend_type());
    }

    void set_entry_info(
        EntryInfo& entry_info, StructureBlock& block, int rate_index) {

        MqlRates rate;
        RatesUtils::get_rate(rate, rate_index);
        entry_info.price = rate.open;
        entry_info.order = this.last_block_data.order;
        entry_info.blocks = get_price_blocks(block, entry_info.price);
    }

    void set_mfe_info(EntryInfo& entry_info, int start_index, int end_index) {
        set_maximum_excursion(
            entry_info.mfe, MFE,
            entry_info.order, entry_info.price,
            start_index, end_index);
    }

    void set_mae_info(EntryInfo& entry_info, int start_index, int end_index) {
        set_maximum_excursion(
            entry_info.mae, MAE,
            entry_info.order, entry_info.price,
            start_index, end_index);
    }

    void set_maximum_excursion(
        ExcursionInfo& excursion, ExcursionType type,
        ENUM_ORDER_TYPE order, double price,
        int start_index, int end_index) {

        const bool is_buy = (order == ORDER_TYPE_BUY);
        const bool use_high = (type == MFE) ? is_buy : !is_buy;
        const bool search_max = (type == MFE) ? is_buy : !is_buy;

        double extreme_price = price;
        int extreme_bars = 0;

        MqlRates rate;

        for (int i = start_index; i >= end_index; --i) {
            RatesUtils::get_rate(rate, i);

            double value = use_high ? rate.high : rate.low;
            bool is_new_extreme = search_max ? (value > extreme_price)
                                             : (value < extreme_price);

            if (is_new_extreme) {
                extreme_price = value;
                extreme_bars = start_index - i;
            }
        }

        excursion.price = extreme_price;
        excursion.distance = MathAbs(extreme_price - price);
        excursion.bars = extreme_bars;
    }

    void log_gral_info(string& log_msg) {
        StringReplace(log_msg, "gral_symbol", get_str_symbol());
        StringReplace(log_msg, "gral_period", get_str_period());

        datetime time = this.last_block_data.end_time;
        ENUM_MARKET_SESSION session = MarketSession::get_session_by_time(time);
        StringReplace(log_msg, "gral_session", EnumToString(session));

        StringReplace(log_msg, "gral_setup_time", time);
    }

    void log_block_info(string& log_msg) {

        StringReplace(
            log_msg,
            "block_pivot_strength",
            get_str_pivot_strength());

        string block_type = this.last_block_data.type == TREND_BULLISH ? "BULLISH" : "BEARISH";
        StringReplace(
            log_msg,
            "block_type",
            block_type);

        StringReplace(
            log_msg,
            "block_size",
            get_str_double(this.last_block_data.block_size));
    }

    void log_entry_info(string& log_msg, EntryInfo& entry_info) {

        StringReplace(
            log_msg,
            "entry_price",
            get_str_double(entry_info.price));

        StringReplace(
            log_msg,
            "entry_order",
            EnumToString(entry_info.order));

        StringReplace(
            log_msg,
            "entry_blocks",
            get_str_double(entry_info.blocks));
    }

    void log_mae_info(string& log_msg, EntryInfo& entry_info) {

        StringReplace(
            log_msg,
            "mae_price",
            get_str_double(entry_info.mae.price));

        StringReplace(
            log_msg,
            "mae_distance",
            get_str_double(entry_info.mae.distance));

        StringReplace(
            log_msg,
            "mae_bars",
            IntegerToString(entry_info.mae.bars));
    }

    void log_mfe_info(string& log_msg, EntryInfo& entry_info) {

        StringReplace(
            log_msg,
            "mfe_price",
            get_str_double(entry_info.mfe.price));

        StringReplace(
            log_msg,
            "mfe_distance",
            get_str_double(entry_info.mfe.distance));

        StringReplace(
            log_msg,
            "mfe_bars",
            IntegerToString(entry_info.mfe.bars));
    }

    string get_str_double(double value) {
        return DoubleToString(value, _Digits);
    }

    void log_rsi_info(string& log_msg) {

        double rsi_value = 0;
        IndicatorRSI rsi_period;
        datetime time = this.last_block_data.end_time;

        for (int i = 0; i < ArraySize(this.indicator_rsi); i++) {

            rsi_period = this.indicator_rsi[i];
            bool success = RSI::get_rsi_value(
                rsi_value, rsi_period.handler, time);

            if (success) {
                StringReplace(
                    log_msg,
                    EnumToString(rsi_period.period),
                    get_str_double(rsi_value));
            }
        }
    }

    void log_bollinger_info(string& log_msg) {

        double bb_value = 0;
        IndicatorBB bb_period;
        datetime time = this.last_block_data.end_time;
        double price = this.last_block_data.end_price;

        for (int i = 0; i < ArraySize(this.indicator_bb); i++) {

            bb_period = this.indicator_bb[i];
            bool success = BollingerBands::get_bollinger_extension(
                bb_value, bb_period.handler, time, price);

            if (success) {
                StringReplace(
                    log_msg,
                    EnumToString(bb_period.period),
                    get_str_double(bb_value));
            }
        }
    }
};
