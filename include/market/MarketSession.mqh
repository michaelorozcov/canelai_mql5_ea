#include "./../../include/dto/Session.mqh"

#include "./../../include/utils/Constants.mqh"

class MarketSession {

  public:
    // TODO: Include server validation SymbolInfoSessionTrade
    static bool is_trading_time(ENUM_MARKET_SESSION session) {

        datetime time = TimeGMT(); // UTC
        MqlDateTime time_struct;
        TimeToStruct(time, time_struct);

        MarketSessionTime session_time = MARKET_SESSIONS[session];

        int day_of_week = time_struct.day_of_week;
        bool in_session_days = ((day_of_week >= session_time.start_day) &&
                                (day_of_week <= session_time.end_day));

        if (!in_session_days)
            return false;

        if ((session == ENUM_MARKET_SESSION::ALL) &&
            (day_of_week != ENUM_DAY_OF_WEEK::FRIDAY))
            return true;

        datetime time_start = session_time.get_time_start(time);
        datetime time_end = session_time.get_time_end(time);
        subtract_minutes(time_end, MINUTES_BEFORE_SESSION_CLOSE);

        return ((time >= time_start) && (time < time_end));
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
    static void subtract_minutes(datetime& date, int minutes) {
        int seconds_to_subtract = MathAbs(minutes * 60);
        date -= seconds_to_subtract;
    }
};
