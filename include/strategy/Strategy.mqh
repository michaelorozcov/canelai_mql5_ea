enum StrategyType {
    TREND_FOLLOW,
    TREND_FOLLOW_HFT,
    TREND_RECOIL,
};

class Strategy {

  private:
    ulong calculate_magic_number() {
        string strategy_name = EnumToString(advisor_args.strategy);
        string session_name = EnumToString(advisor_args.session);
        string symbol_name = _Symbol;
        string period_name = IntegerToString(_Period);
        string base = strategy_name + "_" + session_name + "_" + symbol_name + "_" + period_name;
        ulong hash = 0;

        for (int i = 0; i < StringLen(base); i++)
            hash += (ulong)StringGetCharacter(base, i);

        return hash;
    }

  public:
    CTrade ctrade;
    ulong magic_number;

    Strategy() {
        this.magic_number = calculate_magic_number();
        ctrade.SetExpertMagicNumber(this.magic_number);
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
        return iTime(_Symbol, _Period, 1);
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
