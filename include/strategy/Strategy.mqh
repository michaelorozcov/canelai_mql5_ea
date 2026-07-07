#include "../../include/dto/AdvisorArgs.mqh"

#include "../../include/market/MarketOrder.mqh"

enum StrategyType {
    BLOCK_REVERSION,
    TREND_FOLLOW,
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

    ulong trade(
        ENUM_ORDER_TYPE order, double volume, double price,
        double sl, double tp, string comment = "") {

        ulong ticket = 0;
        bool success = false;

        if (order == ORDER_TYPE_BUY)
            success = trade_buy(volume, price, sl, tp, comment);

        if (order == ORDER_TYPE_SELL)
            success = trade_sell(volume, price, sl, tp, comment);

        if (success)
            ticket = MarketOrder::get_last_ticket();

        return ticket;
    }

    bool trade_buy(double volume, double price, double sl, double tp, string comment = "") {
        return this.ctrade.Buy(volume, _Symbol, price, sl, tp, comment);
    }

    bool trade_sell(double volume, double price, double sl, double tp, string comment = "") {
        return this.ctrade.Sell(volume, _Symbol, price, sl, tp, comment);
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
    datetime last_rate_time;

    NewRateBased() {
        last_rate_time = get_last_rate_time();
    }

    datetime get_last_rate_time() {
        return iTime(_Symbol, _Period, 0);
    }

    bool is_new_rate() {
        datetime new_value = get_last_rate_time();
        if (last_rate_time != new_value) {
            last_rate_time = new_value;
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
