static const int MR_ANALYSIS_SHIFT_MINUTES = 360;
static const int MR_ANALYSIS_LOWEST_INDEX = 1;
static const int MR_ANALYSIS_PIVOT_POINT_STRENGTH = 5;
static const int MR_ANALYSIS_BLOCK_AMOUNT = 3;
static const int MR_ANALYSIS_RATE_DELAY = 1;

static const int MR_BOLLINGER_PERIOD = 20;
static const double MR_BOLLINGER_DEVIATIONS = 2.0;

static const int MR_RSI_MA_PERIOD = 7;
static const double MR_RSI_THRESHOLD_TOP = 70;
static const double MR_RSI_THRESHOLD_BOTTOM = 30;

static const double MR_ENTRY_LEVEL_MAX = 30;
static const double MR_RISK_REWARD_RATIO = 0.5;
static const bool MR_TRAILING_STOP = true;

struct MeanReversionArgs {

    int analysis_shift_minutes;
    int analysis_lowest_index;
    int analysis_pivot_point_strength;
    int analysis_block_amount;
    int analysis_rate_delay;

    int bollinger_period;
    double bollinger_deviations;

    int rsi_ma_period;
    double rsi_threshold_top;
    double rsi_threshold_bottom;

    double entry_level_max;
    double risk_reward_ratio;
    bool trailing_stop;

    MeanReversionArgs() {
        this.analysis_shift_minutes = (((int)_Period) * MR_ANALYSIS_SHIFT_MINUTES);
        this.analysis_lowest_index = MR_ANALYSIS_LOWEST_INDEX;
        this.analysis_pivot_point_strength = MR_ANALYSIS_PIVOT_POINT_STRENGTH;
        this.analysis_block_amount = MR_ANALYSIS_BLOCK_AMOUNT;
        this.analysis_rate_delay = MR_ANALYSIS_RATE_DELAY;

        this.bollinger_period = MR_BOLLINGER_PERIOD;
        this.bollinger_deviations = MR_BOLLINGER_DEVIATIONS;

        this.rsi_ma_period = MR_RSI_MA_PERIOD;
        this.rsi_threshold_top = MR_RSI_THRESHOLD_TOP;
        this.rsi_threshold_bottom = MR_RSI_THRESHOLD_BOTTOM;

        this.entry_level_max = MR_ENTRY_LEVEL_MAX;
        this.risk_reward_ratio = MR_RISK_REWARD_RATIO;
        this.trailing_stop = MR_TRAILING_STOP;
    }
};
