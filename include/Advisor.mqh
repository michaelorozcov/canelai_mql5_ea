#include "utils/DataTransferObjects.mqh"

#include "StatusBoard.mqh"
#include "CandleRange.mqh"
#include "MarketSwing.mqh"

class Advisor
{
public:
    Advisor(AdvisorData &data_param)
    {
        Print("Advisor Init");
        ObjectsDeleteAll(0);
        init(data_param);
    }

    ~Advisor()
    {
        Print("Advisor Deinit");
        ObjectsDeleteAll(0);
        deinit();
    }

    void on_tick()
    {
        process_new_tick();
    }

private:
    AdvisorData data;

    void init(AdvisorData &data_param)
    {
        this.data = data_param;
        this.data.candle_range_left_index = (get_shift_candles(this.data.candle_range_hours) + 1);
        this.data.candle_range_right_index = 1; // Testing only - default 1
        this.data.candle_range_max_size = (this.data.candle_range_left_index - this.data.candle_range_right_index) + 1;
        this.data.is_trading_time = is_trading_time();
        this.data.last_candle_time = iTime(_Symbol, _Period, 0);
        this.data.active_analysis = false;

        update_status_board();
    }

    void deinit()
    {
        StatusBoard::delete_status_board();
        CandleRange::delete_candle_range(this.data);
        MarketSwing::delete_swings(this.data);
    }

    int get_shift_candles(int hours)
    {
        int seconds = hours * 60 * 60;
        return (seconds / PeriodSeconds(_Period));
    }

    bool is_trading_time()
    {
        MqlDateTime start_time;
        TimeToStruct(this.data.trading_time_start, start_time);

        MqlDateTime end_time;
        TimeToStruct(this.data.trading_time_end, end_time);

        MqlDateTime current_time;
        TimeToStruct(TimeLocal(), current_time);

        bool valid_hour = (current_time.hour >= start_time.hour) && (current_time.hour < end_time.hour);
        bool valid_min = (current_time.min >= start_time.min);

        return valid_hour && valid_min;
    }

    //------------------------------------------------------------------

    void process_new_tick()
    {
        check_trading_time();

        if (!this.data.is_trading_time && this.data.active_analysis)
            delete_market_analysis();

        else if (this.data.is_trading_time && !this.data.active_analysis)
            init_market_analysis();

        else if (this.data.is_trading_time && this.data.active_analysis)
            update_market_analysis();
    }

    void check_trading_time()
    {
        bool trading_time = is_trading_time();
        if (trading_time != this.data.is_trading_time)
        {
            this.data.is_trading_time = trading_time;
            update_status_board();
        }
    }

    void update_status_board()
    {
        if (this.data.show_indicators)
            StatusBoard::update(this.data);
    }

    void delete_market_analysis()
    {
        CandleUtils::clear_cache();
        CandleRange::delete_candle_range(this.data);
        MarketSwing::delete_swings(this.data);

        this.data.active_analysis = false;
        update_status_board();
    }

    void init_market_analysis()
    {
        // TODO
        CandleUtils::load_cache(this.data);
        CandleRange::set_candle_range(this.data);
        MarketSwing::set_swings(this.data);

        this.data.active_analysis = true;
        update_status_board();
    }

    void update_market_analysis()
    {
        // TODO
        if (!this.data.active_analysis || !is_new_candle())
            return;

        CandleRange::add_last_candle(this.data);
        MarketSwing::delete_swings(this.data);
        MarketSwing::set_swings(this.data);
    }

    bool is_new_candle()
    {
        datetime current_candle_time = iTime(_Symbol, _Period, 0);
        if (current_candle_time != this.data.last_candle_time)
        {
            this.data.last_candle_time = current_candle_time;
            return true;
        }
        return false;
    }

    /*



    void set_initial_candle_range()
    {
        ArrayResize(this.data.candle_range, 0);

        int start = (this.data.range_index_left + this.data.swing_strength);
        for (int index = start; index > this.data.range_index_right; index--)
            add_candle_to_range(index);
    }





    void set_swings_by_type(SwingType swing_type, Swing &swing_list[])
    {
        for (int i = 0; i < ArraySize(this.data.candle_range); i++)
        {
            Candle candle = this.data.candle_range[i];
            if (is_swing_candle(swing_type, candle))
            {
                Swing swing;
                swing.type = swing_type;
                swing.candle = candle;
                swing.name = (swing_type == SWING_HIGH ? "sh_" : "sl_") + IntegerToString(candle.index);

                int size = ArraySize(swing_list);
                ArrayResize(swing_list, size + 1);
                swing_list[size] = swing;
            }
        }
    }

    void set_swings()
    {
        ArrayResize(this.data.swing_highs, 0);
        set_swings_by_type(SWING_HIGH, this.data.swing_highs);

        ArrayResize(this.data.swing_lows, 0);
        set_swings_by_type(SWING_LOW, this.data.swing_lows);
    }






    void clean_chart()
    {
        if (this.data.show_visual_indicators)
        {
            StatusBoard::delete_status_board();
            CandleRange::delete_candle_range();
            Structure::delete_swings();
        }
    }

    void delete_market_analysis()
    {
        clean_chart();

        this.data.active_analysis = false;
        update_status_board();
    }

    void init_market_analysis()
    {
        set_initial_candle_range();
        set_swings();

        if (this.data.show_visual_indicators)
        {
            CandleRange::draw_candle_range(this.data);
            Structure::draw_swings(this.data);
        }

        this.data.active_analysis = true;
        update_status_board();
    }
        */
};

/*




    static void get_swings(SwingType type, int strength, Candle &range_candles[], Swing &swings[])
    {
        if (ArraySize(swings) > 0)
            ArrayResize(swings, 0);

        Candle candle;
        for (int i = 0; i < ArraySize(range_candles); i++)
        {
            candle = range_candles[i];
            if (is_swing_candle(type, strength, candle))
            {
                Swing swing;
                swing.type = type;
                swing.candle = candle;
                swing.name = (type == SWING_HIGH ? "sh_" : "sl_") + IntegerToString(candle.index);

                int size = ArraySize(swings);
                ArrayResize(swings, size + 1);
                swings[size] = swing;
            }
        }
    }

    static MarketStructure get_market_structure(int strength, Candle &range_candles[])
    {
        MarketStructure structure = STRUCTURE_UNDEFINED;

        Swing swing_highs[];
        get_swings(SWING_HIGH, strength, range_candles, swing_highs);

        Swing swing_lows[];
        get_swings(SWING_LOW, strength, range_candles, swing_lows);

        for (int i = 0; i < ArraySize(swing_highs); i++)
            create_swing_chart(swing_highs[i]);

        for (int i = 0; i < ArraySize(swing_lows); i++)
            create_swing_chart(swing_lows[i]);

        // TODO: COMPLETE
        return structure;
    }

    void set_candle_range(AdvisorData &data)
    {
        ArrayResize(data.candle_range, 0);

        int start = (data.range_index_left + data.swing_strength);
        for (int index = start; index > data.range_index_right; index--)
            add_candle_to_range(data.candle_range, index);

        if (data.show_visual_indicators)
            create_candle_range_chart(data);
    }







    void create_candle_range_chart(AdvisorData &data)
    {
        if (ArraySize(data.candle_range) < 2)
            return;

        delete_candle_range_chart();

        Candle left_candle = data.candle_range[0];
        draw_vertical_line(RANGE_NAME_L, left_candle.time);

        Candle right_candle = data.candle_range[ArraySize(data.candle_range) - 1];
        draw_vertical_line(RANGE_NAME_R, right_candle.time);
    }


// Global variables
bool is_trading_time;
int range_candle_left;
int range_candle_rigth;
datetime last_candle_time;
bool displayed_analysis;
// CArrayList<Zone *> zones;

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("OnDeinit");
    clean_chart();
    reset_ea_variables();

    Board::deinit();
    CandleRecord::deinit();
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("OnInit");
    clean_chart();
    reset_ea_variables();

    Board::init();
    CandleRecord::init();

    is_trading_time = inside_trading_time();
    range_candle_left = get_shift_candles(range_hours_back);
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


void reset_ea_variables()
{
    is_trading_time = false;
    range_candle_left = 0;
    range_candle_rigth = 0; // Testing only - default 0
    last_candle_time = 0;
    displayed_analysis = false;
    // zones.Clear();
}

void clean_chart()
{
    Board::delete_labels();
    CandleRecord::delete_candle_range();
    Structure::delete_swings();

    /*
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







void update_ea_status()
{
    Board::delete_labels();

    string active_text = BOARD_ITEM_ACTIVE_VALUE + (is_trading_time ? "ON" : "OFF");
    Board::create_label(BOARD_ITEM_ACTIVE_NAME, active_text);

    if (!is_trading_time)
        return;

    // Range
    string text_range = BOARD_ITEM_RANGE_VALUE;
    StringReplace(text_range, "{hrs}", IntegerToString(range_hours_back));
    Board::create_label(BOARD_ITEM_RANGE_NAME, text_range);

    /*
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
    // return zone_margin_pips * get_pip_value();
    return get_pip_value();
}
/*
CArrayList<PriceLevel *> get_top_prices(bool include_high = false)
{
    CArrayList<PriceLevel *> top_prices;
    for (int i = range_candle_left; i > range_candle_rigth; i--)
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

        for (int j = range_candle_left; j > range_candle_rigth; j--)
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
        zone.draw_zone(range_candle_rigth);
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
    clean_chart();

    // Set range candles
    CandleRecord::create_candle_range(swing_strength, range_candle_left, range_candle_rigth);

    // Identify market structure (swing highs and lows)
    Structure::get_market_structure(swing_strength, CandleRecord::candle_range);

    // CArrayList<int> range_candles = Range::get_candle_list();
    // MarketStructure market_structure = Structure::get_market_structure(swing_strength, range_candles);

    /*
    // Identify market structure (swing highs and lows)
    CArrayList<PriceLevel *> swing_highs = Structure::get_swing_highs(range_candle_left, range_candle_rigth, swing_strength);
    Print("Swings ", swing_highs.Count());

    for (int i = 0; i < swing_highs.Count(); i++)
    {
        PriceLevel *level = NULL;
        swing_highs.TryGetValue(i, level);
        string name = "sh_" + IntegerToString(i);
        ObjectCreate(0, name, OBJ_HLINE, 0, iTime(_Symbol, _Period, level.candle), level.price);
        ObjectSetInteger(0, name, OBJPROP_COLOR, clrGreen);
    }

    // Check current trend
    // Trend::get_current_trend(range_candle_left, range_candle_rigth);
    // check_resistance_price_levels();


    displayed_analysis = true;
    update_ea_status();
}

*/