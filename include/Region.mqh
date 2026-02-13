class Region
{
private:
    static const string REGION_NAME;
    static const color REGION_COLOR;

public:
    static void draw_scan_region(int candle_index_left, int candle_index_rigth)
    {
        delete_scan_region();

        datetime time_left = iTime(_Symbol, PERIOD_CURRENT, candle_index_left);
        datetime time_rigth = iTime(_Symbol, PERIOD_CURRENT, candle_index_rigth);

        double max_price = iHigh(_Symbol, _Period, iHighest(_Symbol, _Period, MODE_HIGH, candle_index_left, candle_index_rigth));
        double min_price = iLow(_Symbol, _Period, iLowest(_Symbol, _Period, MODE_LOW, candle_index_left, candle_index_rigth));

        ObjectCreate(0, Region::REGION_NAME, OBJ_RECTANGLE, 0, time_left, max_price, time_rigth, min_price);
        ObjectSetInteger(0, Region::REGION_NAME, OBJPROP_COLOR, Region::REGION_COLOR);
        ObjectSetInteger(0, Region::REGION_NAME, OBJPROP_BACK, true);
        ObjectSetInteger(0, Region::REGION_NAME, OBJPROP_FILL, true);
        ObjectSetInteger(0, Region::REGION_NAME, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, Region::REGION_NAME, OBJPROP_SELECTED, false);
    }

    static void delete_scan_region()
    {
        ObjectDelete(0, Region::REGION_NAME);
    }
};

static const string Region::REGION_NAME = "region_name";
static const color Region::REGION_COLOR = clrPaleGoldenrod;
