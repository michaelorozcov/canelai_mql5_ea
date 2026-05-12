static const int STRUCTURE_BLOCKS_SHIFT = 2;
static const int STRUCTURE_BLOCKS_STRENGTH_MIN = 1;
static const int STRUCTURE_BLOCKS_DISTANCE_MAX = 120;

static const int BREAKOUT_RATE_INDEX = 1;
static const bool BREAKOUT_DELTA_CHECK = true;
static const double BREAKOUT_SIZE_FACTOR_MIN = 1.5;
static const double BREAKOUT_SIZE_FACTOR_MAX = 3.0;
static const bool BREAKOUT_VOLUME_CHECK = true;

static const double RISK_PERCENTAGE = 1.0;
static const double RISK_REWARD_RATIO = 3.0;

static const double BREAKEVEN_VALUE = 2.0;

static const int DAILY_LIMIT_LOSSES = 2;
static const int DAILY_LIMIT_WINS = 1;

struct TrendFollowArgs {

    int structure_blocks_shift;
    int structure_blocks_strength_min;
    int structure_blocks_distance_max;

    int breakout_rate_index;
    bool breakout_delta_check;
    double breakout_size_factor_min;
    double breakout_size_factor_max;
    bool breakout_volume_check;

    double risk_percentage;
    double risk_reward_ratio;

    double breakeven_value;

    int daily_limit_losses;
    int daily_limit_wins;

    double monthly_limit_percentage;

    TrendFollowArgs() {

        structure_blocks_shift = STRUCTURE_BLOCKS_SHIFT;
        structure_blocks_strength_min = STRUCTURE_BLOCKS_STRENGTH_MIN;
        structure_blocks_distance_max = STRUCTURE_BLOCKS_DISTANCE_MAX;

        breakout_rate_index = BREAKOUT_RATE_INDEX;
        breakout_delta_check = BREAKOUT_DELTA_CHECK;
        breakout_size_factor_min = BREAKOUT_SIZE_FACTOR_MIN;
        breakout_size_factor_max = BREAKOUT_SIZE_FACTOR_MAX;
        breakout_volume_check = BREAKOUT_VOLUME_CHECK;

        risk_percentage = RISK_PERCENTAGE;
        risk_reward_ratio = RISK_REWARD_RATIO;

        breakeven_value = BREAKEVEN_VALUE;

        daily_limit_losses = DAILY_LIMIT_LOSSES;
        daily_limit_wins = DAILY_LIMIT_WINS;

        monthly_limit_percentage = 0.0;
    }
};
