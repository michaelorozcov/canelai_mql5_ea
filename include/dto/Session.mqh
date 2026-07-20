enum ENUM_MARKET_SESSION {
    ALL,
    TOKYO,
    LONDON,
    NEW_YORK,
};

struct MarketSessionTime {

  public:
    ENUM_MARKET_SESSION session;
    string start;
    string end;

    datetime get_time_start(datetime time) {
        return get_time_based(time, this.start);
    }

    datetime get_time_end(datetime time) {
        return get_time_based(time, this.end);
    }

  private:
    datetime get_time_based(datetime time, string base) {
        MqlDateTime time_struct;
        TimeToStruct(time, time_struct);
        set_session_hour_min(time_struct, base);
        return StructToTime(time_struct);
    }

    void set_session_hour_min(
        MqlDateTime& dest, string session_hour_min) {

        string hour_min[];
        StringSplit(session_hour_min, ':', hour_min);
        dest.hour = (int)StringToInteger(hour_min[0]);
        dest.min = (int)StringToInteger(hour_min[1]);
        dest.sec = 0;
    }
};

// UTC 24hrs
const MarketSessionTime MARKET_SESSIONS[] = {
    {ALL, "00:00", "23:59"},
    {TOKYO, "00:00", "09:00"},
    {LONDON, "07:00", "16:00"},
    {NEW_YORK, "12:00", "21:00"},
};
