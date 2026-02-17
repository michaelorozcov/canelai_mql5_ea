class Candle
{
public:
    static int get_shift_candles(int hours)
    {
        int seconds = hours * 60 * 60;
        int shift = seconds / PeriodSeconds(PERIOD_CURRENT);
        return shift;
    }

    static bool is_bearish_candle(int index)
    {
        double open = iOpen(_Symbol, _Period, index);
        double close = iClose(_Symbol, _Period, index);
        return open > close;
    }

    static bool is_bullish_candle(int index)
    {
        double open = iOpen(_Symbol, _Period, index);
        double close = iClose(_Symbol, _Period, index);
        return open < close;
    }
};
