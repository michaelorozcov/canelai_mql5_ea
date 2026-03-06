#include "utils/CandleUtils.mqh"
#include "utils/ChartUtils.mqh"
#include "utils/DataTransferObjects.mqh"

const string RANGE_NAME_L = "range_name_l";
const string RANGE_NAME_R = "range_name_r";
const color RANGE_COLOR = clrPaleGoldenrod;
const ENUM_LINE_STYLE RANGE_STYLE = STYLE_DASH;

class CandleRange
{
private:
    static void draw_vertical_line(string name, datetime time)
    {
        ChartUtils::create_chart_object(OBJ_VLINE, name, time);
        ObjectSetInteger(0, name, OBJPROP_COLOR, RANGE_COLOR);
        ObjectSetInteger(0, name, OBJPROP_STYLE, RANGE_STYLE);
    }

    static void draw_candle_range(AdvisorData &data)
    {
        if (ArraySize(data.candle_range) < 2)
            return;

        draw_vertical_line(RANGE_NAME_L, data.candle_range[0].time);
        draw_vertical_line(RANGE_NAME_R, data.candle_range[ArraySize(data.candle_range) - 1].time);
    }

    static void delete_candle_range_chart()
    {
        ChartUtils::delete_chart_object(RANGE_NAME_L);
        ChartUtils::delete_chart_object(RANGE_NAME_R);
    }

    static void add_candle_to_range(AdvisorData &data, int candle_index, bool from_cache)
    {
        int size = ArraySize(data.candle_range);
        ArrayResize(data.candle_range, size + 1);
        data.candle_range[size] = CandleUtils::get_candle_data_by_index(candle_index);
    }

public:
    static void delete_candle_range(AdvisorData &data)
    {
        ArrayResize(data.candle_range, 0);

        if (data.show_indicators)
            delete_candle_range_chart();
    }

    static void set_candle_range(AdvisorData &data)
    {
        ArrayResize(data.candle_range, 0);

        for (int i = data.candle_range_left_index; i >= data.candle_range_right_index; i--)
            add_candle_to_range(data, i, true);

        if (data.show_indicators)
            draw_candle_range(data);
    }

    static void add_last_candle(AdvisorData &data)
    {
        add_candle_to_range(data, data.candle_range_right_index, false);

        if (ArraySize(data.candle_range) > data.candle_range_max_size)
            ArrayRemove(data.candle_range, 0, 1);

        if (data.show_indicators)
            draw_candle_range(data);
    }
};
