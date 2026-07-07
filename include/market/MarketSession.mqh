class MarketSession {

  public:
    // TODO: Include server validation SymbolInfoSessionTrade
    static bool is_trading_time(ENUM_MARKET_SESSION session) {

        datetime time = TimeGMT(); // UTC
        MqlDateTime time_struct;
        TimeToStruct(time, time_struct);

        if (!is_inside_work_day(time_struct))
            return false;

        return is_inside_session(time, session, MINUTES_BEFORE_SESSION_CLOSE);
    }

    static ENUM_MARKET_SESSION get_session_by_time(datetime time) {
        ENUM_MARKET_SESSION result = ALL;

        for (int i = 0; i < ArraySize(MARKET_SESSIONS); i++) {
            MarketSessionTime session_time = MARKET_SESSIONS[i];
            if (is_inside_session_time(time, session_time))
                result = session_time.session;
        }

        return result;
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

  private:
    static bool is_inside_work_day(MqlDateTime& date_struct) {
        int day = date_struct.day_of_week;
        return (day >= ENUM_DAY_OF_WEEK::MONDAY) && (day <= ENUM_DAY_OF_WEEK::FRIDAY);
    }

    static bool is_inside_session(
        datetime time, ENUM_MARKET_SESSION session, int shift_minutes = 0) {

        MarketSessionTime session_time;
        get_market_session_time(session, session_time);

        return is_inside_session_time(time, session_time, shift_minutes);
    }

    static void get_market_session_time(
        ENUM_MARKET_SESSION session,
        MarketSessionTime& session_time) {
        session_time = MARKET_SESSIONS[session];
    }

    static bool is_inside_session_time(
        datetime time, MarketSessionTime& session_time, int shift_minutes = 0) {

        datetime session_time_start = session_time.get_time_start(time);
        datetime session_time_end = session_time.get_time_end(time);

        if (shift_minutes > 0)
            subtract_minutes(session_time_end, shift_minutes);

        return (time >= session_time_start) && (time < session_time_end);
    }

    static void subtract_minutes(datetime& date, int minutes) {
        int seconds_to_subtract = MathAbs(minutes * 60);
        date -= seconds_to_subtract;
    }
};
