//+------------------------------------------------------------------+
//|                                                   canelAI_EA.mq5 |
//|                                  Copyright 2026, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property version "1.00"

#include <Generic/ArrayList.mqh>

// Custom Classes
#include "include/Board.mqh";
#include "include/Candle.mqh";
#include "include/Region.mqh";
#include "include/Zone.mqh";

// Constants
const string BOARD_ITEM_ACTIVE_NAME = "status_board_item_active";
const string BOARD_ITEM_ACTIVE_VALUE = "Active: ";

const string BOARD_ITEM_REGION_NAME = "status_board_item_region";
const string BOARD_ITEM_REGION_VALUE = "Region: {hrs} hrs";

const string BOARD_ITEM_ZONES_NAME = "status_board_item_zones";
const string BOARD_ITEM_ZONES_VALUE = "Zones: {z}";

const string BOARD_ITEM_TREND_NAME = "status_board_item_trend";
const string BOARD_ITEM_TREND_VALUE = "Trend: ";
const string BOARD_ITEM_TREND_BULLISH = "Bullish (↑)";
const string BOARD_ITEM_TREND_BEARISH = "Bearish (↓)";

// Inputs
input string trading_time_start = "08:00";
input string trading_time_end = "12:00";
input int region_hours_back = 12;
input int zone_margin_pips = 2;

// Global variables
bool is_trading_time;
int region_candle_left;
int region_candle_rigth;
datetime last_candle_time;
bool displayed_analysis;
CArrayList<Zone *> zones;

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("OnDeinit");
    clean_chart();
    reset_ea_variables();
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("OnInit");
    clean_chart();
    reset_ea_variables();

    is_trading_time = inside_trading_time();
    region_candle_left = Candle::get_shift_candles(region_hours_back);
    last_candle_time = iTime(_Symbol, PERIOD_CURRENT, 0);

    update_ea_status();

    if (is_trading_time)
        analyze_market();

    return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    is_trading_time = inside_trading_time();

    if (!is_trading_time && displayed_analysis)
        clean_chart();

    if (is_trading_time && is_new_candle())
        analyze_market();
}

//+------------------------------------------------------------------+

void reset_ea_variables()
{
    is_trading_time = false;
    region_candle_left = 0;
    region_candle_rigth = 0; // Testing only - default 0
    last_candle_time = 0;
    displayed_analysis = false;
    zones.Clear();
}

void clean_chart()
{
    Board::delete_board();
    Region::delete_scan_region();

    Zone *zone = NULL;
    for (int i = 0; i < zones.Count(); i++)
    {
        zones.TryGetValue(i, zone);
        if (zone != NULL)
        {
            zone.delete_zone();
            delete zone;
        }
    }
    zones.Clear();
    displayed_analysis = false;

    ObjectsDeleteAll(0);
}

bool inside_trading_time()
{
    datetime current_time = TimeLocal();
    datetime start = StringToTime(trading_time_start);
    datetime end = StringToTime(trading_time_end);
    return (current_time >= start) && (current_time < end);
}

bool is_new_candle()
{
    datetime current_candle_time = iTime(_Symbol, PERIOD_CURRENT, 0);
    if (current_candle_time != last_candle_time)
    {
        last_candle_time = current_candle_time;
        return true;
    }
    return false;
}

void update_ea_status()
{
    Board::delete_labels();

    string active_text = BOARD_ITEM_ACTIVE_VALUE + (is_trading_time ? "ON" : "OFF");
    Board::create_label(BOARD_ITEM_ACTIVE_NAME, active_text);

    if (!is_trading_time)
        return;

    // Region
    string text_region = BOARD_ITEM_REGION_VALUE;
    StringReplace(text_region, "{hrs}", IntegerToString(region_hours_back));
    Board::create_label(BOARD_ITEM_REGION_NAME, text_region);

    // Zones
    string text_zones = BOARD_ITEM_ZONES_VALUE;
    StringReplace(text_zones, "{z}", IntegerToString(zones.Count()));
    Board::create_label(BOARD_ITEM_ZONES_NAME, text_zones);
}

double get_pip_value()
{
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    return (digits == 3) ? 0.10 : 0.01;
}

double get_zone_margin_price()
{
    return zone_margin_pips * get_pip_value();
}

CArrayList<PriceLevel *> get_top_prices(bool include_high = false)
{
    CArrayList<PriceLevel *> top_prices;
    for (int i = region_candle_left; i > region_candle_rigth; i--)
    {
        double price = 0;
        if (Candle::is_bullish_candle(i))
            price = iClose(_Symbol, _Period, i);
        else if (Candle::is_bearish_candle(i))
            price = iOpen(_Symbol, _Period, i);

        PriceLevel *price_level = new PriceLevel(i, price);
        top_prices.Add(price_level);

        // TODO: CHECK FLOW
        if (include_high)
        {
            double high = iHigh(_Symbol, _Period, i);
            if (price != high)
            {
                PriceLevel *high_level = new PriceLevel(i, high);
                top_prices.Add(high_level);
            }
        }
    }
    return top_prices;
}

CArrayList<PriceLevel *> get_not_superpassed_prices(CArrayList<PriceLevel *> &top_prices)
{
    CArrayList<PriceLevel *> filtered_prices;

    for (int i = 0; i < top_prices.Count(); i++)
    {
        PriceLevel *level = NULL;
        top_prices.TryGetValue(i, level);
        double price = level.price;
        bool valid = true;

        for (int j = region_candle_left; j > region_candle_rigth; j--)
        {
            if (j >= level.candle)
                continue;

            double open = iOpen(_Symbol, _Period, j);
            double close = iClose(_Symbol, _Period, j);
            bool exceeded = (open > price) && (close > price);
            bool inside_bullish = (price > open) && (price < close);
            bool inside_bearish = (price < open) && (price > close);
            valid = !inside_bearish && !inside_bullish && !exceeded;

            if (!valid)
                break;
        }

        if (valid)
            filtered_prices.Add(level);
    }

    return filtered_prices;
}

void set_zones_based_on_price_levels(CArrayList<PriceLevel *> &price_levels)
{
    zones.Clear();

    for (int i = 0; i < price_levels.Count(); i++)
    {
        PriceLevel *level = NULL;
        price_levels.TryGetValue(i, level);
        Zone *zone = new Zone(level.candle, level.price, get_zone_margin_price());
        zone.draw_zone(region_candle_rigth);
        zones.Add(zone);
    }
}

void check_resistance_price_levels()
{
    // Take top prices
    CArrayList<PriceLevel *> top_prices = get_top_prices();
    // Filter price levels not surpassed
    CArrayList<PriceLevel *> filtered_prices = get_not_superpassed_prices(top_prices);
    // TODO: Filter price levels by hints

    // Register and draw zones
    set_zones_based_on_price_levels(filtered_prices);
}

void analyze_market()
{
    // TODO complete
    clean_chart();

    Region::draw_scan_region(region_candle_left, region_candle_rigth);
    check_resistance_price_levels();

    displayed_analysis = true;
    update_ea_status();
}
