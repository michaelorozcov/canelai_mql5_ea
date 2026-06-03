#include "../include/dto/AdvisorStatus.mqh"

#include "../include/utils/LogUtils.mqh"

#include "../include/strategy/trend_follow/TrendFollow.mqh"

class Advisor {
  public:
    static void on_init(AdvisorArgs& params) {
        process_init(params);
    }

    static void on_deinit() {
        process_deinit();
    }

    static void on_tick() {
        process_tick();
    }

    static void on_timer() {
        process_timer();
    }

    static void on_trade_transaction(
        const MqlTradeTransaction& trans,
        const MqlTradeRequest& request,
        const MqlTradeResult& result) {
        process_trade_transaction(trans, request, result);
    }

  private:
    static AdvisorArgs args;
    static AdvisorStatus status;
    static Strategy* strategy;

    static void log(bool print, string message) {
        if (args.log_file)
            LogUtils::log(status.advisor_id, message);

        if (print)
            Print(message);
    }

    static void process_init(AdvisorArgs& params) {

        args = params;
        init_advisor_status();
        log(true, "INIT");

        set_strategy_instance();
        update_status_board();

        if (is_advisor_ready())
            strategy.on_init();
    }

    static void init_advisor_status() {
        string strategy_name = EnumToString(args.strategy);
        string session_name = EnumToString(args.session);
        string symbol_name = _Symbol;

        string period_name = EnumToString((ENUM_TIMEFRAMES)_Period);
        StringReplace(period_name, "PERIOD_", "");

        status.advisor_id = (strategy_name + "_" + session_name + "_" + symbol_name + "_" + period_name);
        status.strategy_name = strategy_name;
        status.visual_mode = args.visual_mode;
        status.trading_time = is_trading_time();
        set_active_by_trading_time();
    }

    static void set_active_by_trading_time() {
        status.active = status.trading_time;
        status.reason = status.trading_time ? ON_BY_SESSION : OFF_BY_SESSION;
    }

    static void set_strategy_instance() {

        delete_strategy_instance();

        if (args.strategy == TREND_FOLLOW)
            strategy = new TrendFollow(args);

        if (has_strategy_instance())
            strategy.set_advisor_id(status.advisor_id);
    }

    static void process_deinit() {
        if (has_strategy_instance()) {
            strategy.on_deinit();
            delete_strategy_instance();
        }

        log(true, "DEINIT");
    }

    static void process_tick() {
        if (is_advisor_ready())
            strategy.base_on_tick();
    }

    static void process_timer() {

        bool new_value = is_trading_time();

        if (status.trading_time != new_value) {
            status.trading_time = new_value;
            set_active_by_trading_time();
            update_status_board();
            log(true, EnumToString(status.reason));

            strategy.base_on_trading_time_change(status.trading_time);
        }

        if (is_advisor_ready())
            strategy.base_on_timer();
    }

    static void process_trade_transaction(
        const MqlTradeTransaction& trans,
        const MqlTradeRequest& request,
        const MqlTradeResult& result) {

        if (has_strategy_instance())
            strategy.base_on_trade_transaction(trans, request, result);
    }

    static bool has_strategy_instance() {
        return (CheckPointer(strategy) == POINTER_DYNAMIC);
    }

    static bool is_advisor_ready() {
        return (status.active && has_strategy_instance());
    }

    static bool is_trading_time() {
        return MarketSession::is_trading_time(args.session);
    }

    static void update_status_board() {
        if (status.visual_mode)
            StatusBoard::update(status);
    }

    static void delete_strategy_instance() {
        if (has_strategy_instance()) {
            delete strategy;
            strategy = NULL;
        }
    }
};

static AdvisorArgs Advisor::args;
static AdvisorStatus Advisor::status;
static Strategy* Advisor::strategy;
