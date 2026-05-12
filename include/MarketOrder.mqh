class MarketOrder {
  public:
    // TODO: include magic number to differ setups
    static bool has_open_positions() {
        return (PositionsTotal() > 0);
    }

    static double get_month_profit() {
        double profit = 0.0;

        datetime month_init = MarketSession::get_month_init_time();
        datetime month_end = MarketSession::get_month_end_time();

        HistorySelect(month_init, month_end);

        int month_deals = HistoryDealsTotal();

        for (int i = 0; i < month_deals; i++) {

            ulong deal = HistoryDealGetTicket(i);
            HistoryDealSelect(deal);

            ulong order = HistoryDealGetInteger(deal, DEAL_ORDER);

            if (order == 0)
                continue;

            profit += HistoryDealGetDouble(deal, DEAL_PROFIT);
        }

        return profit;
    }
};
