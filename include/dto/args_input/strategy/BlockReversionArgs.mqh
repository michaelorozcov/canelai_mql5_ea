#include "./../../../../include/utils/Constants.mqh"

static const int BR_ANALYSIS_SHIFT_MINUTES = 720;
static const int BR_ANALYSIS_LOWEST_INDEX = 1;

static const int BR_BOLLINGER_PERIOD = 14;
static const double BR_BOLLINGER_DEVIATIONS = 2.0;

static const int BR_RSI_PERIOD = 14;
static const double BR_RSI_THRESHOLD_TOP = 70;
static const double BR_RSI_THRESHOLD_BOTTOM = 30;

static const int BR_ATR_PERIOD = 14;

static const double BR_SL_BLOCKS = 0.0;

struct BlockReversionArgs {

    bool analysis_mode;
    int analysis_shift_minutes;
    int analysis_lowest_index;

    int pivot_point_strength;

    int bollinger_period;
    double bollinger_deviations;

    int rsi_period;
    double rsi_threshold_top;
    double rsi_threshold_bottom;

    int atr_period;

    double sl_blocks;

    BlockReversionArgs() {
        this.analysis_mode = false;
        this.analysis_shift_minutes = (((int)_Period) * BR_ANALYSIS_SHIFT_MINUTES);
        this.analysis_lowest_index = BR_ANALYSIS_LOWEST_INDEX;

        this.pivot_point_strength = FIRST_ORDER_PIVOT_STRENGTH;

        this.bollinger_period = BR_BOLLINGER_PERIOD;
        this.bollinger_deviations = BR_BOLLINGER_DEVIATIONS;

        this.rsi_period = BR_RSI_PERIOD;
        this.rsi_threshold_top = BR_RSI_THRESHOLD_TOP;
        this.rsi_threshold_bottom = BR_RSI_THRESHOLD_BOTTOM;

        this.atr_period = BR_ATR_PERIOD;

        this.sl_blocks = BR_SL_BLOCKS;
    }
};
