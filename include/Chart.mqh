
class Chart
{
private:
    string STATUS_BOARD_NAME;
    string STATUS_BOARD_LABEL_ACTIVE;
    bool show_scan_zone;
    string SCAN_ZONE_NAME;
    color SCAN_ZONE_COLOR;

public:
    void init();
    void deinit();
    void create_status_board(bool trading_time = false);
    void update_status_board(bool trading_time);
    void create_scan_zone(int shift_candles);
    void delete_scan_zone();
    bool is_showing_scan_zone();
};

void Chart::init()
{
    this.STATUS_BOARD_NAME = "status_board_name";
    this.STATUS_BOARD_LABEL_ACTIVE = "Active: ";
    this.show_scan_zone = false;
    this.SCAN_ZONE_NAME = "scan_zone_name";
    this.SCAN_ZONE_COLOR = clrPaleGoldenrod;
}

void Chart::deinit()
{
    this.show_scan_zone = false;
    ObjectDelete(0, STATUS_BOARD_NAME);
    ObjectDelete(0, SCAN_ZONE_NAME);
}

void Chart::create_status_board(bool trading_time = false)
{
    if (ObjectFind(0, STATUS_BOARD_NAME) != -1)
        ObjectDelete(0, STATUS_BOARD_NAME);

    ObjectCreate(0, STATUS_BOARD_NAME, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, STATUS_BOARD_NAME, OBJPROP_XDISTANCE, 5);
    ObjectSetInteger(0, STATUS_BOARD_NAME, OBJPROP_YDISTANCE, 25);

    ObjectSetInteger(0, STATUS_BOARD_NAME, OBJPROP_XSIZE, 100);
    ObjectSetInteger(0, STATUS_BOARD_NAME, OBJPROP_YSIZE, 20);

    ObjectSetInteger(0, STATUS_BOARD_NAME, OBJPROP_BGCOLOR, clrDarkRed);
    ObjectSetInteger(0, STATUS_BOARD_NAME, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, STATUS_BOARD_NAME, OBJPROP_BORDER_TYPE, BORDER_RAISED);
    ObjectSetString(0, STATUS_BOARD_NAME, OBJPROP_TEXT, STATUS_BOARD_LABEL_ACTIVE + "OFF");

    ObjectSetInteger(0, STATUS_BOARD_NAME, OBJPROP_SELECTABLE, true);
    ObjectSetInteger(0, STATUS_BOARD_NAME, OBJPROP_SELECTED, false);

    update_status_board(trading_time);
}

void Chart::update_status_board(bool trading_time)
{
    ObjectSetInteger(0, STATUS_BOARD_NAME, OBJPROP_BGCOLOR, trading_time ? clrDarkGreen : clrDarkRed);

    string text = STATUS_BOARD_LABEL_ACTIVE + (trading_time ? "ON" : "OFF");
    ObjectSetString(0, STATUS_BOARD_NAME, OBJPROP_TEXT, text);
}

void Chart::create_scan_zone(int shift)
{
    delete_scan_zone();

    datetime shift_time = iTime(_Symbol, PERIOD_CURRENT, shift);
    datetime current_time = iTime(_Symbol, PERIOD_CURRENT, 0);

    double max_price = iHigh(_Symbol, _Period, iHighest(_Symbol, _Period, MODE_HIGH, shift, 0));
    double min_price = iLow(_Symbol, _Period, iLowest(_Symbol, _Period, MODE_LOW, shift, 0));

    ObjectCreate(0, SCAN_ZONE_NAME, OBJ_RECTANGLE, 0, shift_time, max_price, current_time, min_price);
    ObjectSetInteger(0, SCAN_ZONE_NAME, OBJPROP_COLOR, SCAN_ZONE_COLOR);
    ObjectSetInteger(0, SCAN_ZONE_NAME, OBJPROP_BACK, true);
    ObjectSetInteger(0, SCAN_ZONE_NAME, OBJPROP_FILL, true);

    this.show_scan_zone = true;
}

void Chart::delete_scan_zone()
{
    if (ObjectFind(0, SCAN_ZONE_NAME) != -1)
        ObjectDelete(0, SCAN_ZONE_NAME);

    this.show_scan_zone = false;
}

bool Chart::is_showing_scan_zone()
{
    return this.show_scan_zone;
}
