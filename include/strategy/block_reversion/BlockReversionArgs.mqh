#include "../../utils/Constants.mqh"

static const int BR_ANALYSIS_SHIFT_MINUTES = 360;
static const int BR_ANALYSIS_LOWEST_INDEX = 1;

static const double BR_ENTRY_LEVEL_MAX = 25.0;

static const int MR_BOLLINGER_PERIOD = 20;
static const double MR_BOLLINGER_DEVIATIONS = 2.0;

static const int MR_RSI_PERIOD = 7;
static const double MR_RSI_THRESHOLD_TOP = 70;
static const double MR_RSI_THRESHOLD_BOTTOM = 30;

static const double BR_RISK_PERCENTAGE = 1.0;
static const double BR_RISK_REWARD_RATIO = 3.0;

static const double BR_FIXED_VOLUME = 0.01;

static const double BR_LIMIT_DAILY_PCT_WON = 1.0;
static const double BR_LIMIT_DAILY_PCT_LOST = 2.0;

struct BlockReversionArgs {

    int analysis_shift_minutes;
    int analysis_lowest_index;

    int pivot_point_strength;

    double entry_level_max;

    int bollinger_period;
    double bollinger_deviations;

    int rsi_period;
    double rsi_threshold_top;
    double rsi_threshold_bottom;

    double risk_percentage;
    double risk_reward_ratio;

    double fixed_volume;

    double limit_daily_pct_won;
    double limit_daily_pct_lost;

    BlockReversionArgs() {
        this.analysis_shift_minutes = (((int)_Period) * BR_ANALYSIS_SHIFT_MINUTES);
        this.analysis_lowest_index = BR_ANALYSIS_LOWEST_INDEX;

        this.pivot_point_strength = FIRST_ORDER_PIVOT_STRENGTH;

        this.entry_level_max = BR_ENTRY_LEVEL_MAX;

        this.bollinger_period = MR_BOLLINGER_PERIOD;
        this.bollinger_deviations = MR_BOLLINGER_DEVIATIONS;

        this.rsi_period = MR_RSI_PERIOD;
        this.rsi_threshold_top = MR_RSI_THRESHOLD_TOP;
        this.rsi_threshold_bottom = MR_RSI_THRESHOLD_BOTTOM;

        this.risk_percentage = BR_RISK_PERCENTAGE;
        this.risk_reward_ratio = BR_RISK_REWARD_RATIO;

        this.fixed_volume = BR_FIXED_VOLUME;

        this.limit_daily_pct_won = BR_LIMIT_DAILY_PCT_WON;
        this.limit_daily_pct_lost = BR_LIMIT_DAILY_PCT_LOST;
    }
};
