class MarketSession {

  private:
    static bool inside_work_day(datetime date) {
        MqlDateTime date_struct;
        TimeToStruct(date, date_struct);
        int day = date_struct.day_of_week;
        return (day >= ENUM_DAY_OF_WEEK::MONDAY) && (day <= ENUM_DAY_OF_WEEK::FRIDAY);
    }

  public:
    // TODO: Include server validation SymbolInfoSessionTrade
    static bool is_trading_time(MarketSessionEnum session) {

        datetime current_date = TimeGMT(); // UTC
        if (!inside_work_day(current_date))
            return false;

        MarketSessionTime session_time = MARKET_SESSIONS[session];
        datetime session_start = StringToTime(session_time.start);
        datetime session_end = StringToTime(session_time.end);

        return (current_date >= session_start) && (current_date < session_end);
    }

    static datetime get_today_init_time() {
        datetime current_date = TimeGMT(); // UTC
        MqlDateTime date_struct;
        TimeToStruct(current_date, date_struct);
        date_struct.hour = 0;
        date_struct.min = 0;
        date_struct.sec = 0;
        return StructToTime(date_struct);
    }

    static datetime get_today_end_time() {
        datetime current_date = TimeGMT(); // UTC
        MqlDateTime date_struct;
        TimeToStruct(current_date, date_struct);
        date_struct.hour = 23;
        date_struct.min = 59;
        date_struct.sec = 59;
        return StructToTime(date_struct);
    }

    static datetime get_month_init_time() {
        datetime current_date = TimeGMT(); // UTC
        MqlDateTime date_struct;
        TimeToStruct(current_date, date_struct);
        date_struct.day = 1;
        date_struct.hour = 0;
        date_struct.min = 0;
        date_struct.sec = 0;
        return StructToTime(date_struct);
    }

    static datetime get_month_end_time() {
        datetime current_date = TimeGMT(); // UTC
        MqlDateTime date_struct;
        TimeToStruct(current_date, date_struct);
        date_struct.day = 30;
        date_struct.hour = 23;
        date_struct.min = 59;
        date_struct.sec = 59;
        return StructToTime(date_struct);
    }
};
