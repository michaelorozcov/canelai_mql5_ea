#include "./../../include/dto/args_input/AdvisorArgs.mqh"

#include "./../../include/utils/Constants.mqh"

#include "./../../include/strategy/Strategy.mqh"

#include "./../../include/Advisor.mqh"

class RiskManaged : public Strategy {
  public:
    RiskManaged(AdvisorArgs& param_args, string param_advisor_id)
        : Strategy(param_args, param_advisor_id) {
        this.breakeven_applied = false;
        this.trailing_stop_unit = 0.0;
    }

    void base_on_init() override {
        process_on_init();
    }

    void base_on_trading_time_change(bool trading_time) override {
        process_on_trading_time_change(trading_time);
    }

    void base_on_trade_transaction(
        const MqlTradeTransaction& trans,
        const MqlTradeRequest& request,
        const MqlTradeResult& result) override {
        process_on_trade_transaction(trans, request, result);
    }

    void base_on_tick() override {
        process_on_tick();
    }

  protected:
    bool breakeven_applied;
    double trailing_stop_unit;

    void process_on_init() {
        if (has_reached_limit()) {
            turn_off_by_limits();
        } else {
            on_init();
        }
    }

    void process_on_trading_time_change(bool trading_time) {

        if (!trading_time && has_open_positions()) {
            log("Closing open positions by session ending");
            close_open_positions();
        }

        on_trading_time_change(trading_time);
    }

    void process_on_trade_transaction(
        const MqlTradeTransaction& trans,
        const MqlTradeRequest& request,
        const MqlTradeResult& result) {

        if (is_close_transaction(trans) && has_reached_limit()) {
            turn_off_by_limits();
        }

        on_trade_transaction(trans, request, result);
    }

    bool is_close_transaction(const MqlTradeTransaction& trans) {

        if (trans.type != TRADE_TRANSACTION_DEAL_ADD)
            return false;

        ulong deal = trans.deal;

        if (!HistoryDealSelect(deal)) {
            log(StringFormat(
                "is_close_transaction: Error selecting deal %s",
                IntegerToString(deal)));
            return false;
        }

        long deal_entry = HistoryDealGetInteger(deal, DEAL_ENTRY);
        long deal_reason = HistoryDealGetInteger(deal, DEAL_REASON);

        bool is_entry_out = (deal_entry == DEAL_ENTRY_OUT);
        bool is_sl = (deal_reason == DEAL_REASON_SL);
        bool is_tp = (deal_reason == DEAL_REASON_TP);

        return (is_entry_out && (is_sl || is_tp));
    }

    bool has_reached_limit() {
        return has_reached_limit_daily();
    }

    bool has_reached_limit_daily() {

        double today_profit, today_won_trades, today_lost_trades;

        MarketOrder::get_today_balance(
            today_profit, today_won_trades, today_lost_trades);

        log(StringFormat(
            "Today [ Profit: %s | Wins: %s | Losses: %s ]",
            DoubleToString(today_profit, _Digits),
            DoubleToString(today_won_trades, 0),
            DoubleToString(today_lost_trades, 0)));

        bool daily_limit_won = has_reached_limit_daily_won(
            today_profit, today_won_trades);

        bool daily_limit_lost = has_reached_limit_daily_lost(
            today_profit, today_lost_trades);

        return (daily_limit_won || daily_limit_lost);
    }

    bool has_reached_limit_daily_won(double today_profit, double today_trades) {

        DailyLimit daily_limit = this.args.risk.daily_limit_won;

        if (is_amount_limit(daily_limit) && (today_profit < 0)) {
            return false;
        }

        return has_reached_limit_daily_value(daily_limit, today_profit, today_trades);
    }

    bool has_reached_limit_daily_lost(double today_profit, double today_trades) {

        DailyLimit daily_limit = this.args.risk.daily_limit_lost;

        if (is_amount_limit(daily_limit) && (today_profit > 0)) {
            return false;
        }

        return has_reached_limit_daily_value(daily_limit, today_profit, today_trades);
    }

    bool is_amount_limit(DailyLimit& daily_limit) {
        return ((DAILY_LIMIT_AMOUNT == daily_limit.type) ||
                (DAILY_LIMIT_PCT == daily_limit.type));
    }

    bool has_reached_limit_daily_value(
        DailyLimit& daily_limit, double today_profit, double today_trades) {

        ENUM_DAILY_LIMIT_TYPE type = daily_limit.type;
        double value = daily_limit.value;

        if ((DAILY_LIMIT_NONE == type) || (value <= 0))
            return false;

        if (DAILY_LIMIT_TRADES == type)
            return (today_trades >= value);

        if (DAILY_LIMIT_AMOUNT == type)
            return (MathAbs(today_profit) >= value);

        if (DAILY_LIMIT_PCT == type) {
            double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
            double profit_balance = MathAbs((today_profit / account_balance) * 100);
            return (profit_balance >= value);
        }

        return false;
    }

    void turn_off_by_limits() {
        log("It has reached trading limits");
        Advisor::set_active_status(false, OFF_BY_LIMITS);
    }

    void process_on_tick() {

        if (this.args.risk.breakeven > 0) {
            check_positions_breakeven();

        } else if (this.args.risk.trailing_stop > 0) {
            check_positions_trailing_stop();
        }

        on_tick();
    }

    void check_positions_breakeven() {

        if (this.breakeven_applied)
            return;

        for (int i = 0; i < PositionsTotal(); i++) {
            // TODO: check several positions path
            if (check_position_breakeven(PositionGetTicket(i))) {
                this.breakeven_applied = true;
            }
        }
    }

    void check_positions_trailing_stop() {
        for (int i = 0; i < PositionsTotal(); i++) {
            // TODO: check several positions path
            check_positions_trailing_stop(PositionGetTicket(i));
        }
    }

    bool check_position_breakeven(ulong ticket) {

        if (!PositionSelectByTicket(ticket)) {
            log(StringFormat(
                "Breakeven: Error selecting ticket %s",
                IntegerToString(ticket)));
            return false;
        }

        string ticket_symbol = PositionGetString(POSITION_SYMBOL);
        if (ticket_symbol != _Symbol) {
            log(StringFormat(
                "Breakeven: Error checking ticket symbol [ %s - %s ] != %s",
                IntegerToString(ticket),
                ticket_symbol, _Symbol));
            return false;
        }

        double entry = PositionGetDouble(POSITION_PRICE_OPEN);
        double sl = PositionGetDouble(POSITION_SL);
        double tp = PositionGetDouble(POSITION_TP);
        ENUM_POSITION_TYPE type =
            (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

        if ((sl == 0.0) ||
            ((type == POSITION_TYPE_BUY) && (sl >= entry)) ||
            ((type == POSITION_TYPE_SELL) && (sl <= entry)))
            return false;

        double r_unit = MathAbs(entry - sl);
        double trigger_distance = (r_unit * this.args.risk.breakeven);

        double current_price = 0.0;
        bool triggered = false;

        if (type == POSITION_TYPE_BUY) {
            current_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            triggered = (current_price >= (entry + trigger_distance));
        }

        if (type == POSITION_TYPE_SELL) {
            current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            triggered = (current_price <= (entry - trigger_distance));
        }

        if (!triggered)
            return false;

        return set_position(ticket, entry, tp);
    }

    bool check_positions_trailing_stop(ulong ticket) {

        if (!PositionSelectByTicket(ticket)) {
            log(StringFormat(
                "TrailingStop: Error selecting ticket %s",
                IntegerToString(ticket)));
            return false;
        }

        string ticket_symbol = PositionGetString(POSITION_SYMBOL);
        if (ticket_symbol != _Symbol) {
            log(StringFormat(
                "TrailingStop: Error checking ticket symbol [ %s - %s ] != %s",
                IntegerToString(ticket),
                ticket_symbol, _Symbol));
            return false;
        }

        double entry = PositionGetDouble(POSITION_PRICE_OPEN);
        double sl = PositionGetDouble(POSITION_SL);
        double tp = PositionGetDouble(POSITION_TP);
        ENUM_POSITION_TYPE type =
            (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

        if (sl == 0.0) {
            log(StringFormat(
                "TrailingStop: Not valid SL %s",
                DoubleToString(sl, _Digits)));
            return false;
        }

        if (this.trailing_stop_unit == 0.0) {
            this.trailing_stop_unit = (MathAbs(entry - sl) * this.args.risk.trailing_stop);
        }

        double current_price = 0.0;
        double new_sl = 0.0;

        if (type == POSITION_TYPE_BUY) {
            current_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            new_sl = (current_price - this.trailing_stop_unit);

            if (new_sl > sl)
                return set_position(ticket, new_sl, tp);
        }

        if (type == POSITION_TYPE_SELL) {
            current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            new_sl = (current_price + this.trailing_stop_unit);

            if (new_sl < sl)
                return set_position(ticket, new_sl, tp);
        }

        return false;
    }

    double calculate_position_volume(double entry, double sl) {

        double ref_value = this.args.risk.trade_risk.value;

        switch (this.args.risk.trade_risk.type) {

        case TRADE_RISK_PCT: {
            return calculate_position_volume_by_pct(entry, sl, ref_value);
            break;
        }

        case TRADE_RISK_AMOUNT: {
            return calculate_position_volume_by_amount(entry, sl, ref_value);
            break;
        }

        case TRADE_RISK_VOLUME: {
            return normalize_volume(ref_value);
            break;
        }

        default:
            return 0.0;
            break;
        }
    }

    double calculate_position_volume_by_pct(double entry, double sl, double pct) {

        if (pct <= 0.0)
            return 0.0;

        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double amount = (balance * (pct / 100.0));

        return calculate_position_volume_by_amount(entry, sl, amount);
    }

    double calculate_position_volume_by_amount(double entry, double sl, double amount) {

        double distance = MathAbs(entry - sl);
        double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

        if ((amount <= 0.0) || (distance <= 0.0) || (tick_size <= 0.0) || (tick_value <= 0.0))
            return 0.0;

        double ticks = (distance / tick_size);
        double risk_per_lot = (ticks * tick_value);
        double volume = (amount / risk_per_lot);

        return normalize_volume(volume);
    }

    double normalize_volume(double volume) {

        double min_value = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
        double max_value = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
        double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

        if (step <= 0.0)
            return 0.0;

        if (volume <= min_value)
            return min_value;

        if (volume >= max_value)
            return max_value;

        // Prevent floating-point precision errors (e.g. 0.03 stored as 0.029999999999999998).
        volume = min_value + MathFloor(((volume - min_value) / step) + VOLUME_EPSILON) * step;

        // TODO: check if required in other stocks
        int digits = (int)MathRound(-MathLog10(step));
        return NormalizeDouble(volume, digits);
    }

    double calculate_risked_amount() {

        if (this.args.risk.trade_risk.type == TRADE_RISK_AMOUNT)
            return this.args.risk.trade_risk.value;

        if (this.args.risk.trade_risk.type == TRADE_RISK_PCT) {
            double pct = this.args.risk.trade_risk.value;
            double balance = AccountInfoDouble(ACCOUNT_BALANCE);
            double amount = (balance * (pct / 100.0));
            return NormalizeDouble(amount, _Digits);
        }

        return 0;
    }

    double calculate_order_stop_loss(
        ENUM_ORDER_TYPE order_type, double volume, double entry_price, double sl_price) {

        double calculated_sl = 0;
        bool success = OrderCalcProfit(order_type, _Symbol, volume, entry_price, sl_price, calculated_sl);

        return calculated_sl;
    }
};
