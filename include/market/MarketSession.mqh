class MarketSession {

  private:
    static bool inside_work_day(MqlDateTime& date_struct) {
        int day = date_struct.day_of_week;
        return (day >= ENUM_DAY_OF_WEEK::MONDAY) && (day <= ENUM_DAY_OF_WEEK::FRIDAY);
    }

    static void set_session_detail(
        MqlDateTime& start, MqlDateTime& end, MarketSessionTime& session) {
        set_session_hour_min(start, session.start);
        set_session_hour_min(end, session.end);
    }

    static void set_session_hour_min(
        MqlDateTime& dest, string session_hour_min) {

        string hour_min[];
        StringSplit(session_hour_min, ':', hour_min);
        dest.hour = (int)StringToInteger(hour_min[0]);
        dest.min = (int)StringToInteger(hour_min[1]);
        dest.sec = 0;
    }

    static void subtract_minutes(datetime& date, int minutes) {
        int seconds_to_subtract = MathAbs(minutes * 60);
        date -= seconds_to_subtract;
    }

  public:
    // TODO: Include server validation SymbolInfoSessionTrade
    static bool is_trading_time(ENUM_MARKET_SESSION session) {

        datetime current_date = TimeGMT(); // UTC
        MqlDateTime struct_date;
        TimeToStruct(current_date, struct_date);

        if (!inside_work_day(struct_date))
            return false;

        MarketSessionTime session_time = MARKET_SESSIONS[session];
        MqlDateTime struct_start = struct_date, struct_end = struct_date;
        set_session_detail(struct_start, struct_end, session_time);

        datetime start_date = StructToTime(struct_start);
        datetime end_date = StructToTime(struct_end);

        subtract_minutes(end_date, MINUTES_BEFORE_SESSION_CLOSE);

        return (current_date >= start_date) && (current_date < end_date);
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
