class TrendFollowHFT : public NewRateBased {
  public:
    TrendFollowHFT(AdvisorArgs& advisor_args_data) {
        this.args = advisor_args_data.trend_follow_hft;
        visual_mode = advisor_args_data.visual_mode;
    }

    void on_timer() override {
        on_timer_process();
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
    TrendFollowHFTArgs args;
    bool visual_mode;
    StructureBlock last_block;

    void process_new_rate() {

        last_block.clear();

        delete_market_analysis();
        set_market_analysis();

        StructureBlock last_blocks[];
        MarketStructure::get_latest_blocks(last_blocks, 1);

        if (ArraySize(last_blocks) > 0)
            last_block = last_blocks[0];
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

    void on_timer_process() {
        check_open_positions();
        check_entry_conditions();
    }

    void check_open_positions() {

        ulong tickets[];
        MarketOrder::get_open_positions(tickets, this.magic_number);

        PositionSelect(_Symbol);
        for (int i = 0; i < ArraySize(tickets); i++) {

            ulong ticket = tickets[i];
            PositionSelectByTicket(ticket);

            double value = PositionGetDouble(POSITION_PROFIT);

            if (value > 0.0) {
                PrintFormat("Closing position %d with profit %f", ticket, value);
                // ctrade.PositionClose(ticket);
                double sl = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                ctrade.PositionModify(ticket, sl, 0);
            }
        }
    }

    void check_entry_conditions() {

        ulong tickets[];
        MarketOrder::get_open_positions(tickets, this.magic_number);
        if (ArraySize(tickets) >= args.trades_max_amount)
            return;

        if (!last_block.is_valid())
            return;

        bool bullish_block = last_block.is_bullish();

        PivotPoint top_pivot = bullish_block ? last_block.end : last_block.start;
        double top_price = MarketPivot::get_pivot_price(top_pivot, true);

        PivotPoint bottom_pivot = bullish_block ? last_block.start : last_block.end;
        double bottom_price = MarketPivot::get_pivot_price(bottom_pivot, true);

        bool top_break = !RatesUtils::is_respected_price(
            last_block.end.rate_index,
            args.last_rate_index,
            top_price,
            true, false, 0);

        bool bottom_break = !RatesUtils::is_respected_price(
            last_block.end.rate_index,
            args.last_rate_index,
            bottom_price,
            false, false, 0);

        double entry = bullish_block
                           ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                           : SymbolInfoDouble(_Symbol, SYMBOL_BID);

        Print(
            " Top break ", top_break,
            " Bottom break ", bottom_break);

        if (bottom_break && (entry < bottom_price))
            ctrade.Sell(0.01, _Symbol, entry, bottom_price, 0, "Sell");

        if (top_break && (entry > top_price))
            ctrade.Buy(0.01, _Symbol, entry, top_price, 0, "Buy");
    }
};
