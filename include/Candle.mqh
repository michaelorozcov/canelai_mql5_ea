class Candle
{
private:
    datetime last_candle_datetime;

public:
    void init();
    void deinit();
    bool is_new_candle();
    int get_shift_candles(int hours);
};

void Candle::init()
{
    last_candle_datetime = 0;
}

void Candle::deinit()
{
    last_candle_datetime = 0;
}

bool Candle::is_new_candle()
{
    datetime current_candle_datetime = iTime(_Symbol, PERIOD_CURRENT, 0);
    if (current_candle_datetime != last_candle_datetime)
    {
        last_candle_datetime = current_candle_datetime;
        return true;
    }
    return false;
}

int Candle::get_shift_candles(int hours)
{
    int seconds = hours * 60 * 60;
    int shift = seconds / PeriodSeconds(PERIOD_CURRENT);
    return shift;
}
