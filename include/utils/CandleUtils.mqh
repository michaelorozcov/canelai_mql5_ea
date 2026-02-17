#include "DataTransferObjects.mqh"

class CandleUtils
{
private:
    static double cached_open[];
    static double cached_high[];
    static double cached_low[];
    static double cached_close[];
    static datetime cached_time[];
    static int cached_size;

public:
    static void load_cache(AdvisorData &data)
    {
        int count = data.candle_range_left_index;
        ArrayResize(cached_open, count);
        ArrayResize(cached_high, count);
        ArrayResize(cached_low, count);
        ArrayResize(cached_close, count);
        ArrayResize(cached_time, count);

        CopyOpen(_Symbol, _Period, 0, count, cached_open);
        CopyHigh(_Symbol, _Period, 0, count, cached_high);
        CopyLow(_Symbol, _Period, 0, count, cached_low);
        CopyClose(_Symbol, _Period, 0, count, cached_close);
        CopyTime(_Symbol, _Period, 0, count, cached_time);

        cached_size = count;
    }

    static void clear_cache()
    {
        ArrayFree(cached_open);
        ArrayFree(cached_high);
        ArrayFree(cached_low);
        ArrayFree(cached_close);
        ArrayFree(cached_time);
        cached_size = 0;
    }

    static Candle get_candle_data_by_index(int candle_index, bool from_cache = false)
    {
        Candle record = {0.0, 0.0, 0.0, 0.0, 0};

        if (!from_cache)
        {
            record.open = iOpen(_Symbol, _Period, candle_index);
            record.high = iHigh(_Symbol, _Period, candle_index);
            record.low = iLow(_Symbol, _Period, candle_index);
            record.close = iClose(_Symbol, _Period, candle_index);
            record.time = iTime(_Symbol, _Period, candle_index);
        }
        else if (cached_size > 0)
        {
            record.open = cached_open[candle_index];
            record.high = cached_high[candle_index];
            record.low = cached_low[candle_index];
            record.close = cached_close[candle_index];
            record.time = cached_time[candle_index];
        }

        return record;
    }
};

static double CandleUtils::cached_open[];
static double CandleUtils::cached_high[];
static double CandleUtils::cached_low[];
static double CandleUtils::cached_close[];
static datetime CandleUtils::cached_time[];
static int CandleUtils::cached_size = 0;
