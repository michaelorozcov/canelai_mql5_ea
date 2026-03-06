struct Candle
{
    double open;
    double high;
    double low;
    double close;
    datetime time;
};

enum SwingType
{
    SWING_HIGH,
    SWING_LOW,
};

struct Swing
{
    SwingType type;
    Candle candle;
    string name;
};

enum MarketStructure
{
    STRUCTURE_UNDEFINED,
    STRUCTURE_UPTREND,
    STRUCTURE_DOWNTREND,
    STRUCTURE_RANGING,
};

struct AdvisorData
{
    // Input values
    datetime trading_time_start;
    datetime trading_time_end;
    bool show_indicators;
    int candle_range_hours;
    int swing_strength;

    // Initial values
    datetime last_candle_time;
    int candle_range_left_index;
    int candle_range_right_index;
    int candle_range_max_size;
    bool is_trading_time;
    bool active_analysis;

    // Analysis values
    Candle candle_range[];
    Swing swing_highs[];
    Swing swing_lows[];
};
