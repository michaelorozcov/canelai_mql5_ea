#include "MarketSession.mqh"

class MarketOrder {
  public:
    static void get_current_price(double& ask, double& bid) {
        MqlTick tick;
        SymbolInfoTick(_Symbol, tick);

        ask = tick.ask;
        bid = tick.bid;
    }

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

    static void get_month_profit(
        double& month_profit, int& month_wins, int& month_losses) {
        get_profit_based_on_date(
            MarketSession::get_month_init_time(),
            MarketSession::get_month_end_time(),
            month_profit, month_wins, month_losses);
    }

    static void get_today_profit(
        double& today_profit, int& today_wins, int& today_losses) {
        get_profit_based_on_date(
            MarketSession::get_today_init_time(),
            MarketSession::get_today_end_time(),
            today_profit, today_wins, today_losses);
    }

    static void get_profit_based_on_date(
        datetime time_start, datetime time_end,
        double& total_profit, int& total_wins, int& total_losses) {

        total_profit = 0;
        total_losses = 0;
        total_wins = 0;

        HistorySelect(time_start, time_end);

        int total_deals = HistoryDealsTotal();

        for (int i = 0; i <= total_deals; i++) {

            ulong deal_ticket = HistoryDealGetTicket(i);
            if (deal_ticket == 0)
                continue;

            ENUM_DEAL_TYPE deal_type = (ENUM_DEAL_TYPE)HistoryDealGetInteger(deal_ticket, DEAL_TYPE);
            if ((deal_type != DEAL_TYPE_BUY) && (deal_type != DEAL_TYPE_SELL))
                continue;

            double deal_profit = HistoryDealGetDouble(deal_ticket, DEAL_PROFIT);

            total_profit += deal_profit;

            if (deal_profit < 0)
                total_losses++;

            if (deal_profit > 0)
                total_wins++;
        }
    }

    static double get_trade_volume(
        double price, double stop_loss, double risk_percentage) {

        double sl_distance = MathAbs(price - stop_loss);
        if (sl_distance <= 0)
            return 0.0;

        double risk_amount = get_balance_percentage(risk_percentage);

        double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
        double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        double value_per_price_unit = tick_value / tick_size;

        double loss_per_lot = (sl_distance * value_per_price_unit);
        double lots = (risk_amount / loss_per_lot);

        double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
        double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
        double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

        lots = MathFloor(lots / lot_step) * lot_step;
        lots = MathMax(min_lot, MathMin(max_lot, lots));

        return NormalizeDouble(lots, 2);
    }

    static double get_balance_percentage(double percentage) {
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double result = (balance * (percentage / 100.0));
        return NormalizeDouble(result, _Digits);
    }

    static double calculate_take_profit_price(
        ENUM_ORDER_TYPE order_type, double stop_loss, double entry_price, double risk_reward_ratio) {

        if (entry_price == 0.0 || stop_loss == 0.0 || risk_reward_ratio == 0.0)
            return 0.0;

        bool is_buy = (order_type == ORDER_TYPE_BUY);
        bool is_sell = (order_type == ORDER_TYPE_SELL);

        if ((is_buy && (stop_loss >= entry_price)) ||
            (is_sell && (stop_loss <= entry_price)))
            return 0.0;

        double distance = MathAbs(entry_price - stop_loss);
        double tp_distance = (distance * risk_reward_ratio);
        double tp = entry_price + (is_buy ? tp_distance : -tp_distance);

        return NormalizeDouble(tp, _Digits);
    }

    static ulong get_last_ticket() {
        ulong ticket = 0;
        int positions = PositionsTotal();

        if (positions > 0) {
            ticket = PositionGetTicket(positions - 1);
        }

        return ticket;
    }
};
