#include "./../../../../../Include/Trade/Trade.mqh"

#include "./../../include/dto/args_input/AdvisorArgs.mqh"

#include "./../../include/utils/LogUtils.mqh"

#include "./../../include/market/MarketOrder.mqh"

class Strategy {

  public:
    Strategy(AdvisorArgs& param_args, string param_advisor_id) {
        this.args = param_args;
        this.advisor_id = param_advisor_id;
        set_magic_number();
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

  protected:
    AdvisorArgs args;
    string advisor_id;
    ulong magic_number;
    CTrade ctrade;

    void set_magic_number() {
        this.magic_number = this.calculate_magic_number(this.advisor_id);
        this.ctrade.SetExpertMagicNumber(this.magic_number);
    }

    ulong calculate_magic_number(string hash_base) {
        ulong hash = 0;
        for (int i = 0; i < StringLen(hash_base); i++)
            hash += (ulong)StringGetCharacter(hash_base, i);
        return hash;
    }

    void log(string message) {
        if (args.general.log_file)
            LogUtils::log(this.advisor_id, message);
        Print(message);
    }

    bool has_open_positions() {
        return MarketOrder::has_open_positions(this.magic_number);
    }

    void close_open_positions() {
        ulong tickets[];
        MarketOrder::get_open_positions(tickets, this.magic_number);

        for (int i = 0; i < ArraySize(tickets); i++)
            this.ctrade.PositionClose(tickets[i]);
    }

    ulong market_order_delayed_tp(
        ENUM_ORDER_TYPE order, double volume, string symbol,
        double price, double sl, double reward_ratio, string comment = "") {

        ulong ticket = market_order(order, volume, symbol, price, sl, 0.0, comment);
        if (ticket == 0) {
            log("Error placing order");
            return ticket;
        }

        if (!update_position_tp(order, ticket, reward_ratio)) {
            log(StringFormat(
                "Error updating position TP %s",
                IntegerToString(ticket)));
        }

        return ticket;
    }

    bool update_position_tp(ENUM_ORDER_TYPE order_type, ulong ticket, double reward_ratio) {

        if (!PositionSelectByTicket(ticket)) {
            log(StringFormat(
                "update_position_tp: Error selecting ticket %s",
                IntegerToString(ticket)));
            return false;
        }

        double entry_price = PositionGetDouble(POSITION_PRICE_OPEN);
        double stop_loss = PositionGetDouble(POSITION_SL);

        double tp = MarketOrder::calculate_take_profit_price(
            order_type, entry_price, stop_loss, reward_ratio);

        return set_position(ticket, stop_loss, tp);
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
};
