enum ENUM_MARKET_SESSION {
    ALL,
    TOKYO,
    LONDON,
    NEW_YORK,
};

struct MarketSessionTime {

  public:
    ENUM_MARKET_SESSION session;
    ENUM_DAY_OF_WEEK start_day;
    string start_time;
    ENUM_DAY_OF_WEEK end_day;
    string end_time;

    datetime get_time_start(datetime time) {
        return get_time_based(time, this.start_time);
    }

    datetime get_time_end(datetime time) {
        return get_time_based(time, this.end_time);
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
    {
        //
        ALL,
        ENUM_DAY_OF_WEEK::MONDAY, "00:00",
        ENUM_DAY_OF_WEEK::FRIDAY, "21:00"
        //
    },
    {
        TOKYO,
        ENUM_DAY_OF_WEEK::SUNDAY, "00:00",
        ENUM_DAY_OF_WEEK::THURSDAY, "09:00"
        //
    },
    {
        LONDON,
        ENUM_DAY_OF_WEEK::MONDAY, "07:00",
        ENUM_DAY_OF_WEEK::FRIDAY, "16:00"
        //
    },
    {
        NEW_YORK,
        ENUM_DAY_OF_WEEK::MONDAY, "12:00",
        ENUM_DAY_OF_WEEK::FRIDAY, "21:00"
        //
    },
};
