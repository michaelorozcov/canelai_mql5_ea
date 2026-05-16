class TrendRecoil : public NewRateBased {
  public:
    TrendRecoil(AdvisorArgs& advisor_args_data) {
        this.args = advisor_args_data.trend_recoil;
        visual_mode = advisor_args_data.visual_mode;

        position_ticket = 0;
    }

    void on_tick() override {
        // Print("on_tick ", SymbolInfoDouble(_Symbol, SYMBOL_ASK));
    }

    void on_timer() override {
        // Print("on_timer ", ctrade.RequestPosition());
    }

    void on_trading_time_change(bool trading_time) override {
        // TODO: Close open positions if we are out of trading time (advisor_trading_time)
    }

    void on_new_rate() override {
        process_new_rate();
    }

    void on_trade_transaction(
        const MqlTradeTransaction& trans,
        const MqlTradeRequest& request,
        const MqlTradeResult& result) override {
        // Print("on_trade_transaction");
    }

  private:
    TrendRecoilArgs args;
    bool visual_mode;

    ulong position_ticket;

    void process_new_rate() {
        delete_market_analysis();
        set_market_analysis();

        if (!check_open_positions()) {
            check_entry_conditions();
        }
    }

    void delete_market_analysis() {
        RatesUtils::delete_rates();
        MarketPivot::delete_pivot_points();
        MarketStructure::delete_market_structure();
    }

    void set_market_analysis() {

        // Rates
        RatesUtils::set_rates(
            args.analysis_shift_minutes,
            args.analysis_lowest_index,
            this.visual_mode); // TODO check access

        // Pivot Points
        MarketPivot::set_pivot_points(
            args.analysis_lowest_index,
            this.visual_mode); // TODO check access

        // Market Structure
        MarketStructure::set_market_structure(
            args.analysis_lowest_index,
            this.visual_mode); // TODO check access
    }

    // TODO
    bool check_open_positions() {

        if (position_ticket == 0)
            return false;

        PositionSelect(_Symbol);
        PositionSelectByTicket(position_ticket);

        double value = PositionGetDouble(POSITION_PROFIT);
        if (value < 0)
            return true;

        if (value > 0)
            ctrade.PositionClose(position_ticket);

        return false;

        // ctrade.PositionModify(position_ticket, middle_price, 0);

        /*
        ulong open_positions[];
        MarketOrder::get_open_positions(open_positions, this.magic_number);

        if (ArraySize(open_positions) == 0)
            return false;

        for (int i = 0; i < ArraySize(open_positions); i++) {
            ulong ticket = open_positions[i];
            PositionSelectByTicket(ticket);
            double value = PositionGetDouble(POSITION_PROFIT);

            if (value > 0.0) {
                PrintFormat("Closing position %d with profit %f", ticket, value);
                ctrade.PositionClose(ticket);
            }
        }*/
    }

    void check_entry_conditions() {

        StructureBlock last_blocks[];
        MarketStructure::get_latest_blocks(last_blocks, 1);

        if (ArraySize(last_blocks) == 0)
            return;

        StructureBlock last_block = last_blocks[0];

        if (last_block.end.rate_index > 6)
            return;

        bool bullish_block = last_block.is_bullish();
        bool bearish_block = last_block.is_bearish();
        double start = MarketPivot::get_pivot_price(last_block.start, true);
        double end = MarketPivot::get_pivot_price(last_block.end, true);

        double middle = bullish_block
                            ? (((end - start) / 2) + start)
                            : (((start - end) / 2) + end);

        ChartUtils::create_chart_object(
            OBJ_HLINE, "middle_line", 0, middle);

        double entry = bullish_block
                           ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                           : SymbolInfoDouble(_Symbol, SYMBOL_ASK);

        bool valid_buy = bearish_block && (entry < middle);
        bool valid_sell = bullish_block && (entry > middle);

        if (!valid_buy && !valid_sell) {
            position_ticket = 0;
            return;
        }

        if (valid_buy)
            ctrade.Buy(0.01, _Symbol, entry, end, start, "Buy");

        if (valid_sell)
            ctrade.Sell(0.01, _Symbol, entry, end, start, "Sell");

        PositionSelect(_Symbol);
        position_ticket = PositionGetTicket(0);
    }
};
