class MarketOrder {
  public:
    static void get_open_positions(ulong& tickets[], ulong magic_number) {

        int total = PositionsTotal();
        if (total == 0)
            return;

        for (int i = 0; i < total; i++) {

            ulong ticket = PositionGetTicket(i);
            if (ticket == 0)
                continue;

            if (!PositionSelectByTicket(ticket))
                continue;

            if (PositionGetInteger(POSITION_MAGIC) == magic_number)
                ArrayUtils::add_item(tickets, ticket);
        }
    }

    static bool has_open_positions(ulong magic_number) {
        ulong tickets[];
        get_open_positions(tickets, magic_number);

        return (ArraySize(tickets) > 0);
    }

    static void close_open_positions(CTrade& ctrade, ulong magic_number) {
        ulong tickets[];
        get_open_positions(tickets, magic_number);

        for (int i = 0; i < ArraySize(tickets); i++)
            ctrade.PositionClose(tickets[i]);
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

    static ulong get_last_ticket() {
        ulong ticket = 0;
        int positions = PositionsTotal();

        if (positions > 0) {
            ticket = PositionGetTicket(positions - 1);
        }

        return ticket;
    }

    static double calculate_take_profit_price(
        ENUM_ORDER_TYPE order_type, double entry_price,
        double stop_loss, double risk_reward_ratio) {

        if (entry_price == 0.0 || stop_loss == 0.0 || risk_reward_ratio == 0.0)
            return 0.0;

        double distance = MathAbs(entry_price - stop_loss);
        double tp_distance = (distance * risk_reward_ratio);
        double factor = (order_type == ORDER_TYPE_BUY) ? 1 : -1;
        double tp = (entry_price + (tp_distance * factor));

        return NormalizeDouble(tp, _Digits);
    }
};
