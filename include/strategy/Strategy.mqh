#include "../../include/dto/AdvisorArgs.mqh"

#include "../../include/market/MarketOrder.mqh"

enum StrategyType {
    TREND_FOLLOW,
    TREND_FOLLOW_HFT,
    TREND_RECOIL,
};

class Strategy {

  private:
    ulong calculate_magic_number(string hash_base) {
        ulong hash = 0;
        for (int i = 0; i < StringLen(hash_base); i++)
            hash += (ulong)StringGetCharacter(hash_base, i);
        return hash;
    }

  public:
    CTrade ctrade;
    string advisor_id;
    ulong magic_number;

    void set_advisor_id(string param_advisor_id) {
        this.advisor_id = param_advisor_id;
        this.magic_number = this.calculate_magic_number(this.advisor_id);
        this.ctrade.SetExpertMagicNumber(this.magic_number);
    }

    ulong market_order(
        ENUM_ORDER_TYPE order, double volume, string symbol,
        double price = 0.0, double sl = 0.0, double tp = 0.0, string comment = "") {

        ulong ticket = 0;
        bool success = false;

        if (order == ORDER_TYPE_BUY)
            success = market_order_buy(volume, symbol, price, sl, tp, comment);

        if (order == ORDER_TYPE_SELL)
            success = market_order_sell(volume, symbol, price, sl, tp, comment);

        if (success)
            ticket = MarketOrder::get_last_ticket();

        return ticket;
    }

    bool market_order_buy(
        double volume, string symbol,
        double price = 0.0, double sl = 0.0, double tp = 0.0, string comment = "") {
        return this.ctrade.Buy(volume, symbol, price, sl, tp, comment);
    }

    bool market_order_sell(
        double volume, string symbol,
        double price = 0.0, double sl = 0.0, double tp = 0.0, string comment = "") {
        return this.ctrade.Sell(volume, symbol, price, sl, tp, comment);
    }

    bool set_position(ulong ticket, double sl, double tp) {
        return this.ctrade.PositionModify(ticket, sl, tp);
    }

    virtual void on_init() {
        // to be implemented by specific strategies
    }

    virtual void on_deinit() {
        // to be implemented by specific strategies
    }

    virtual void base_on_tick() {
        on_tick();
    }

    virtual void on_tick() {
        // to be implemented by specific strategies
    }

    virtual void base_on_timer() {
        on_timer();
    }

    virtual void on_timer() {
        // to be implemented by specific strategies
    }

    virtual void base_on_trading_time_change(bool trading_time) {
        on_trading_time_change(trading_time);
    }

    virtual void on_trading_time_change(bool trading_time) {
        // to be implemented by specific strategies
    }

    virtual void base_on_trade_transaction(
        const MqlTradeTransaction& trans,
        const MqlTradeRequest& request,
        const MqlTradeResult& result) {
        on_trade_transaction(trans, request, result);
    }

    virtual void on_trade_transaction(
        const MqlTradeTransaction& trans,
        const MqlTradeRequest& request,
        const MqlTradeResult& result) {
        // to be implemented by specific strategies
    }
};

class NewRateBased : public Strategy {
  public:
    MqlDateTime last_rate_time;

    NewRateBased() {
        get_last_rate_time(this.last_rate_time);
    }

    void get_last_rate_time(MqlDateTime& dest) {
        datetime time = iTime(_Symbol, _Period, 1);
        TimeToStruct(time, dest);
    }

    bool is_new_rate() {

        MqlDateTime new_value;
        get_last_rate_time(new_value);

        bool diff_day = this.last_rate_time.day_of_year != new_value.day_of_year;
        bool diff_hour = this.last_rate_time.hour != new_value.hour;
        bool diff_min = this.last_rate_time.min != new_value.min;

        if (diff_day || diff_hour || diff_min) {
            this.last_rate_time = new_value;
            return true;
        }

        return false;
    }

    void base_on_timer() override {
        on_timer();

        if (is_new_rate())
            on_new_rate();
    }

    virtual void on_new_rate() {
        // to be implemented by specific strategies
    }
};
