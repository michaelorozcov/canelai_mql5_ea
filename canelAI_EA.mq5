//+------------------------------------------------------------------+
//|                                                   canelAI_EA.mq5 |
//|                                  Copyright 2026, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property version "1.00"

#include "include/utils/DataTransferObjects.mqh"
#include "include/Advisor.mqh"

// Expert Advisor
Advisor *advisor = NULL;

// Inputs
input string trading_time_start = "08:00";
input string trading_time_end = "12:00";
input bool show_indicators = true;
input int candle_range_hours = 6;
input int swing_strength = 3;

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    delete advisor;
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    AdvisorData data;
    data.trading_time_start = StringToTime(trading_time_start);
    data.trading_time_end = StringToTime(trading_time_end);
    data.show_indicators = show_indicators;
    data.candle_range_hours = candle_range_hours;
    data.swing_strength = swing_strength;

    advisor = new Advisor(data);

    return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    if (advisor != NULL)
        advisor.on_tick();
}

//+------------------------------------------------------------------+
