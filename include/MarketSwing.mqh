#include "utils/ChartUtils.mqh"
#include "utils/DataTransferObjects.mqh"

const double ARROW_MARGIN = 1.0;

class MarketSwing
{
private:
    static string swing_names[];

    static void draw_arrow(string name, ENUM_OBJECT type, datetime time, double price, color colour)
    {
        ChartUtils::create_chart_object(type, name, time, price);
        ObjectSetInteger(0, name, OBJPROP_COLOR, colour);
    }

    static void draw_swing(Swing &swing)
    {
        int size = ArraySize(MarketSwing::swing_names);
        ArrayResize(MarketSwing::swing_names, size + 1);
        MarketSwing::swing_names[size] = swing.name;

        double price = swing.type == SWING_HIGH ? swing.candle.high + ARROW_MARGIN : swing.candle.low - ARROW_MARGIN;
        color colour = swing.type == SWING_HIGH ? clrGreen : clrRed;
        ENUM_OBJECT arrow = swing.type == SWING_HIGH ? OBJ_ARROW_SELL : OBJ_ARROW_BUY;

        draw_arrow(swing.name, arrow, swing.candle.time, price, colour);
    }

    static void delete_swings_chart()
    {
        for (int i = 0; i < ArraySize(MarketSwing::swing_names); i++)
            ChartUtils::delete_chart_object(MarketSwing::swing_names[i]);

        ArrayResize(MarketSwing::swing_names, 0);
    }

    static void clean_swing_lists(AdvisorData &data)
    {
        ArrayResize(data.swing_highs, 0);
        ArrayResize(data.swing_lows, 0);
    }

    static void add_swing_to_list(Swing &swing_list[], Swing &swing)
    {
        int size = ArraySize(swing_list);
        ArrayResize(swing_list, size + 1);
        swing_list[size] = swing;
    }

    static bool is_swing_candle(AdvisorData &data, SwingType type, int index)
    {
        int left_items = MathMin(data.swing_strength, index);
        int right_items = MathMin(data.swing_strength, ArraySize(data.candle_range) - index - 1);
        int start = index - left_items;
        int end = index + right_items;

        for (int i = start; i <= end; i++)
        {
            if (i == index)
                continue;

            if ((type == SWING_HIGH) && (data.candle_range[i].high > data.candle_range[index].high))
                return false;

            if ((type == SWING_LOW) && (data.candle_range[i].low < data.candle_range[index].low))
                return false;
        }

        return true;
    }

public:
    static void delete_swings(AdvisorData &data)
    {
        clean_swing_lists(data);

        if (data.show_indicators)
            delete_swings_chart();
    };

    static void set_swings(AdvisorData &data)
    {
        clean_swing_lists(data);

        for (int i = 0; i < ArraySize(data.candle_range); i++)
        {
            bool is_swing = false;
            Swing swing = {};
            Candle candle = data.candle_range[i];

            if (is_swing_candle(data, SWING_HIGH, i))
            {
                is_swing = true;
                swing.type = SWING_HIGH;
                swing.candle = candle;
                swing.name = "SH_" + IntegerToString(i);
                add_swing_to_list(data.swing_highs, swing);
            }

            if (is_swing_candle(data, SWING_LOW, i))
            {
                is_swing = true;
                swing.type = SWING_LOW;
                swing.candle = candle;
                swing.name = "SL_" + IntegerToString(i);
                add_swing_to_list(data.swing_lows, swing);
            }

            if (is_swing && data.show_indicators)
                draw_swing(swing);
        }
    }
};

static string MarketSwing::swing_names[];
