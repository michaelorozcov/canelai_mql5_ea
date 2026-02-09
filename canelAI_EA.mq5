//+------------------------------------------------------------------+
//|                                                   canelAI_EA.mq5 |
//|                                  Copyright 2026, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property version "1.00"

// Custom Classes
#include "include/Candle.mqh";
#include "include/Chart.mqh";
#include "include/Time.mqh";
#include "include/Trend.mqh";

// Inputs
input string trading_time_start = "08:00";
input string trading_time_end = "12:00";
input int scan_hours_back = 6;

// Global variables
bool is_trading_time = false;
int shift_candles = 0;

// Instances of custom classes
Chart chart;
Candle candle;
Time time;
Trend trend;

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("OnDeinit");
    ObjectsDeleteAll(0);

    chart.deinit();
    candle.deinit();
    time.deinit();

    is_trading_time = false;
    shift_candles = 0;

    // TODO ExpertRemove();
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("OnInit");
    ObjectsDeleteAll(0);

    chart.init();
    candle.init();
    time.init(trading_time_start, trading_time_end);

    is_trading_time = time.is_trading_time();
    shift_candles = candle.get_shift_candles(scan_hours_back);

    chart.create_status_board(is_trading_time);

    if (is_trading_time)
    {
        // TODO: trading logic
        chart.create_scan_zone(shift_candles);
    }

    return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    check_trading_time();

    if (!is_trading_time)
    {
        chart.delete_scan_zone();
        return;
    }

    if (!chart.is_showing_scan_zone())
        chart.create_scan_zone(shift_candles);

    if (!candle.is_new_candle())
        return;

    chart.create_scan_zone(shift_candles);

    // TODO: trading logic
}

//+------------------------------------------------------------------+

void check_trading_time()
{
    bool trading_time_new_value = time.is_trading_time();
    if (is_trading_time != trading_time_new_value)
    {
        is_trading_time = trading_time_new_value;
        chart.update_status_board(is_trading_time);
    }
}
