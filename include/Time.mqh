class Time
{
private:
    string trading_time_start;
    string trading_time_end;

public:
    void init(string start, string end);
    void deinit();
    bool is_trading_time();
};

void Time::init(string start, string end)
{
    trading_time_start = start;
    trading_time_end = end;
}

void Time::deinit()
{
    trading_time_start = "00:00";
    trading_time_end = "00:00";
}

bool Time::is_trading_time()
{
    datetime current_time = TimeLocal();
    datetime start = StringToTime(trading_time_start);
    datetime end = StringToTime(trading_time_end);
    return (current_time >= start) && (current_time < end);
}
