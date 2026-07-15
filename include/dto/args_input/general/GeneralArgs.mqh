#include "./../../../../include/dto/args_input/strategy/StrategyType.mqh"
#include "./../../../../include/dto/Session.mqh"

struct GeneralArgs {
    StrategyType strategy;
    ENUM_MARKET_SESSION session;

    string symbol;
    int period;

    bool visual_mode;
    bool log_file;

    GeneralArgs() {
        strategy = TREND_FOLLOW;
        session = NEW_YORK;
        symbol = _Symbol;
        period = _Period;
        visual_mode = true;
        log_file = true;
    }
};
