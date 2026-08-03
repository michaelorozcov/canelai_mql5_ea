#include "./../include/dto/args_input/AdvisorArgs.mqh"
#include "./../include/dto/args_input/general/GeneralArgs.mqh"
#include "./../include/dto/AdvisorStatus.mqh"

#include "./../include/utils/LogUtils.mqh"
#include "./../include/utils/StatusBoard.mqh"

#include "./../include/market/MarketSession.mqh"
#include "./../include/market/MarketOrder.mqh"

#include "./../include/strategy/Strategy.mqh"
#include "./../include/strategy/trend_follow/TrendFollow.mqh"

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

    static void set_active_status(bool active, ENUM_STATUS_ACTIVE_REASON reason) {
        status.active = active;
        status.reason = reason;
        update_status_board();
        log(EnumToString(status.reason));
    }

  private:
    static AdvisorArgs args;
    static AdvisorStatus status;
    static Strategy* strategy;

    static void log(string message) {
        message = ("Advisor: " + message);
        if (args.general.log_file)
            LogUtils::log(status.advisor_id, message);
        Print(message);
    }

    static void process_init(AdvisorArgs& params) {

        args = params;
        init_advisor_status();
        log("on_init");

        set_strategy_instance();
        set_active_status_by_trading_time();

        if (is_advisor_ready())
            strategy.base_on_init();
    }

    static void init_advisor_status() {
        status.advisor_id = get_advisor_id(args.general);
        status.strategy_name = EnumToString(args.general.strategy);
        status.visual_mode = args.general.visual_mode;
        status.trading_time = is_trading_time();
    }

    static string get_advisor_id(GeneralArgs& general_args) {

        string strategy_name = EnumToString(general_args.strategy);
        string session_name = EnumToString(general_args.session);
        string symbol_name = general_args.symbol;

        string period_name = EnumToString((ENUM_TIMEFRAMES)general_args.period);
        StringReplace(period_name, "PERIOD_", "");

        return (strategy_name + "_" + session_name + "_" + symbol_name + "_" + period_name);
    }

    static void set_active_status_by_trading_time() {
        set_active_status(
            status.trading_time,
            status.trading_time ? ON_BY_SESSION : OFF_BY_SESSION);
    }

    static void set_strategy_instance() {

        delete_strategy_instance();

        if (args.general.strategy == TREND_FOLLOW)
            strategy = new TrendFollow(args, status.advisor_id);
    }

    static void process_deinit() {
        if (has_strategy_instance()) {
            strategy.base_on_deinit();
            delete_strategy_instance();
        }

        log("on_deinit");
    }

    static void process_tick() {
        if (is_advisor_ready())
            strategy.base_on_tick();
    }

    static void process_timer() {

        bool new_value = is_trading_time();

        if (status.trading_time != new_value) {
            status.trading_time = new_value;

            set_active_status_by_trading_time();

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
        return MarketSession::is_trading_time(args.general.session);
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
