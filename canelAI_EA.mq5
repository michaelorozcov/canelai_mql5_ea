//+------------------------------------------------------------------+
//|                                                   canelAI_EA.mq5 |
//|                                  Copyright 2026, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property version "1.00"

// Inputs
input string duty_time_start = "07:00";
input string duty_time_end = "13:00";

// Constants
string status_board_name = "status_board_name";
string status_board_label_active = "Active: ";

// Global variables
bool on_active_duty = false;
datetime last_candle_datetime = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("OnInit");
    init_expert_advisor();
    return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("OnDeinit");
    close_expert_advisor();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    if (!is_new_candle())
        return;

    check_active_status();
}

//+------------------------------------------------------------------+

void init_expert_advisor()
{
    ObjectsDeleteAll(0);
    create_status_board();
    check_active_status();
}

void close_expert_advisor()
{
    ObjectsDeleteAll(0);
    on_active_duty = false;
}

void check_active_status()
{
    bool previous_value = on_active_duty;
    datetime current_time = TimeLocal();
    datetime start = StringToTime(duty_time_start);
    datetime end = StringToTime(duty_time_end);
    on_active_duty = (current_time >= start) && (current_time < end);

    if (previous_value != on_active_duty)
        update_status_board();
}

bool is_new_candle()
{
    datetime current_candle_datetime = iTime(_Symbol, PERIOD_CURRENT, 0);
    if (current_candle_datetime != last_candle_datetime)
    {
        last_candle_datetime = current_candle_datetime;
        return true;
    }
    return false;
}

void create_status_board()
{
    if (ObjectFind(0, status_board_name) != -1)
        ObjectDelete(0, status_board_name);

    ObjectCreate(0, status_board_name, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, status_board_name, OBJPROP_XDISTANCE, 5);
    ObjectSetInteger(0, status_board_name, OBJPROP_YDISTANCE, 25);

    ObjectSetInteger(0, status_board_name, OBJPROP_XSIZE, 100);
    ObjectSetInteger(0, status_board_name, OBJPROP_YSIZE, 20);

    ObjectSetInteger(0, status_board_name, OBJPROP_BGCOLOR, clrDarkRed);
    ObjectSetInteger(0, status_board_name, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, status_board_name, OBJPROP_BORDER_TYPE, BORDER_RAISED);
    ObjectSetString(0, status_board_name, OBJPROP_TEXT, status_board_label_active + "OFF");

    ObjectSetInteger(0, status_board_name, OBJPROP_SELECTABLE, true);
    ObjectSetInteger(0, status_board_name, OBJPROP_SELECTED, false);
}

void update_status_board()
{
    ObjectSetInteger(0, status_board_name, OBJPROP_BGCOLOR, on_active_duty ? clrDarkGreen : clrDarkRed);

    string text = status_board_label_active + (on_active_duty ? "ON" : "OFF");
    ObjectSetString(0, status_board_name, OBJPROP_TEXT, text);
}
