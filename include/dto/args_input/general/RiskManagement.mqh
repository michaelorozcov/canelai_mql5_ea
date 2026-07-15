enum ENUM_DAILY_LIMIT_TYPE {
    DAILY_LIMIT_NONE,
    DAILY_LIMIT_PCT,
    DAILY_LIMIT_AMOUNT,
    DAILY_LIMIT_TRADES,
};

enum ENUM_TRADE_RISK_TYPE {
    TRADE_RISK_PCT,
    TRADE_RISK_AMOUNT,
    TRADE_RISK_VOLUME,
};

struct DailyLimit {
    ENUM_DAILY_LIMIT_TYPE type;
    double value;
};

struct TradeRisk {
    ENUM_TRADE_RISK_TYPE type;
    double value;
};

struct RiskManagement {

    TradeRisk trade_risk;

    double reward_ratio;
    double breakeven;
    double trailing_stop;

    DailyLimit daily_limit_won;
    DailyLimit daily_limit_lost;

    RiskManagement() {
        reward_ratio = 0.0;
        breakeven = 0.0;
        trailing_stop = 0.0;
    }
};
