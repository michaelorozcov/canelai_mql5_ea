#include "utils/ChartUtils.mqh"
#include "utils/DataTransferObjects.mqh"

// Constants
const string BOARD_ITEM_ACTIVE_NAME = "status_board_item_active";
const string BOARD_ITEM_ACTIVE_VALUE = "Active: ";

const string BOARD_ITEM_RANGE_NAME = "status_board_item_range";
const string BOARD_ITEM_RANGE_VALUE = "Range: {hrs} hrs";

const string BOARD_ITEM_ZONES_NAME = "status_board_item_zones";
const string BOARD_ITEM_ZONES_VALUE = "Zones: {z}";

const string BOARD_ITEM_TREND_NAME = "status_board_item_trend";
const string BOARD_ITEM_TREND_VALUE = "Trend: ";
const string BOARD_ITEM_TREND_BULLISH = "Bullish (↑)";
const string BOARD_ITEM_TREND_BEARISH = "Bearish (↓)";

const string BOARD_NAME = "status_board_name";
const int BOARD_XDISTANCE = 5;
const int BOARD_YDISTANCE = 25;
const int BOARD_XSIZE = 110;
const int BOARD_YSIZE = 25;

class StatusBoard
{
private:
    static string labels[];

    static void set_board_color(color bg_color)
    {
        if (ObjectFind(0, BOARD_NAME) < 0)
            return;

        ObjectSetInteger(0, BOARD_NAME, OBJPROP_COLOR, bg_color);
        ObjectSetInteger(0, BOARD_NAME, OBJPROP_BGCOLOR, bg_color);
    }

    static void resize_board()
    {
        int x_margin = 2;
        int contained_labels = ArraySize(StatusBoard::labels);

        ObjectSetInteger(0, BOARD_NAME, OBJPROP_XDISTANCE, BOARD_XDISTANCE - x_margin);
        ObjectSetInteger(0, BOARD_NAME, OBJPROP_YDISTANCE, BOARD_YDISTANCE);
        ObjectSetInteger(0, BOARD_NAME, OBJPROP_XSIZE, BOARD_XSIZE + x_margin);
        ObjectSetInteger(0, BOARD_NAME, OBJPROP_YSIZE, (BOARD_YSIZE * contained_labels));
    }

    static void create_board(color bg_color = clrRed)
    {
        ChartUtils::create_chart_object(OBJ_RECTANGLE_LABEL, BOARD_NAME);
        set_board_color(bg_color);
        resize_board();
    }

    static void create_label(string label_name, string label_text)
    {
        if (ObjectFind(0, BOARD_NAME) < 0)
            create_board();

        int labels_size = ArraySize(StatusBoard::labels);
        int position = labels_size + 1;

        ChartUtils::create_chart_object(OBJ_LABEL, label_name);
        ObjectSetInteger(0, label_name, OBJPROP_XDISTANCE, BOARD_XDISTANCE);
        ObjectSetInteger(0, label_name, OBJPROP_YDISTANCE, (BOARD_YDISTANCE * position));
        ObjectSetInteger(0, label_name, OBJPROP_XSIZE, BOARD_XSIZE);
        ObjectSetInteger(0, label_name, OBJPROP_YSIZE, BOARD_YSIZE);
        ObjectSetString(0, label_name, OBJPROP_TEXT, label_text);
        ObjectSetInteger(0, label_name, OBJPROP_COLOR, clrWhite);

        ArrayResize(StatusBoard::labels, position);
        StatusBoard::labels[labels_size] = label_name;

        resize_board();
    }

    static void delete_labels()
    {
        int labels_size = ArraySize(StatusBoard::labels);
        for (int i = 0; i < labels_size; i++)
            ChartUtils::delete_chart_object(StatusBoard::labels[i]);

        ArrayResize(StatusBoard::labels, 0);
    }

public:
    static void delete_status_board()
    {
        delete_labels();
        ChartUtils::delete_chart_object(BOARD_NAME);
    }

    static void update(AdvisorData &data)
    {
        delete_labels();

        string active_text = BOARD_ITEM_ACTIVE_VALUE + (data.is_trading_time ? "ON" : "OFF");
        create_label(BOARD_ITEM_ACTIVE_NAME, active_text);

        set_board_color(data.is_trading_time ? clrGreen : clrRed);

        if (!data.is_trading_time)
            return;

        // Range
        if (data.candle_range_hours > 0)
        {
            string text_range = BOARD_ITEM_RANGE_VALUE;
            StringReplace(text_range, "{hrs}", IntegerToString(data.candle_range_hours));
            create_label(BOARD_ITEM_RANGE_NAME, text_range);
        }

        /*
            // Zones
            string text_zones = BOARD_ITEM_ZONES_VALUE;
            StringReplace(text_zones, "{z}", IntegerToString(zones.Count()));
            create_label(BOARD_ITEM_ZONES_NAME, text_zones);
        */
    }
};

static string StatusBoard::labels[];
