#include "../dto/PivotPoint.mqh"
#include "../dto/Trend.mqh"

// Rates
const int RATES_LIMIT_SHIFT_MINUTES = 370;
const string RATES_LIMIT_LEFT = "rates_limit_left";
const string RATES_LIMIT_RIGHT = "rates_limit_right";
const color RATES_LIMIT_COLOR = clrPaleGoldenrod;
const ENUM_LINE_STYLE RATES_LIMIT_STYLE = STYLE_DASH;

// Analysis
const int ANALYSIS_LIMIT_SHIFT_MINUTES = 360;
const int ANALYSIS_LIMIT_LOWEST_INDEX = 2;

// Pivot Points
const int FIRST_ORDER_PIVOT_STRENGTH = 5;
const double CHART_PIVOT_PRICE_MARGIN = 2;
const color CHART_PIVOT_COLOR_1 = clrBlue;
const color CHART_PIVOT_COLOR_2 = clrYellow;
const color CHART_PIVOT_COLOR_3 = clrBrown;

// Trend
const color TREND_BULLISH_COLOR = clrLightGreen;
const color TREND_BEARISH_COLOR = clrIndianRed;
const TrendConfig TREND_BIAS_CONFIG[] = {
    {PIVOT_ORDER_1, 3, 0.5},
    {PIVOT_ORDER_1, 2, 1},
};

// Structure
const double STRUCTURE_BREAKOUT_THRESHOLD_FACTOR = 0.3;
const int STRUCTURE_MAX_PIVOTS_ANALYSIS = 100;

// Zone
const double ZONE_SENSITIVITY = 0.3;
const color ZONE_COLOR = clrBlue;
const ENUM_LINE_STYLE ZONE_STYLE = STYLE_DASH;
const int ZONE_HINTS_MIN = 3;
