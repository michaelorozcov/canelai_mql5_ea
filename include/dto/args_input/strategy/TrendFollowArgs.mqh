static const int TF_ANALYSIS_SHIFT_MINUTES = 370;
static const int TF_ANALYSIS_LOWEST_INDEX = 2;

static const int TF_STRUCTURE_BLOCKS_SHIFT = 2;
static const int TF_STRUCTURE_BLOCKS_STRENGTH_MIN = 1;
static const int TF_STRUCTURE_BLOCKS_DISTANCE_MAX = 60;

static const int TF_BREAKOUT_RATE_INDEX = 1;
static const bool TF_BREAKOUT_DELTA_CHECK = false;
static const double TF_BREAKOUT_SIZE_FACTOR_MIN = 1.5;
static const double TF_BREAKOUT_SIZE_FACTOR_MAX = 3.0;
static const bool TF_BREAKOUT_VOLUME_CHECK = false;

struct TrendFollowArgs {

    int analysis_shift_minutes;
    int analysis_lowest_index;

    int structure_blocks_shift;
    int structure_blocks_strength_min;
    int structure_blocks_distance_max;

    int breakout_rate_index;
    bool breakout_delta_check;
    double breakout_size_factor_min;
    double breakout_size_factor_max;
    bool breakout_volume_check;

    TrendFollowArgs() {

        analysis_shift_minutes = TF_ANALYSIS_SHIFT_MINUTES;
        analysis_lowest_index = TF_ANALYSIS_LOWEST_INDEX;

        structure_blocks_shift = TF_STRUCTURE_BLOCKS_SHIFT;
        structure_blocks_strength_min = TF_STRUCTURE_BLOCKS_STRENGTH_MIN;
        structure_blocks_distance_max = TF_STRUCTURE_BLOCKS_DISTANCE_MAX;

        breakout_rate_index = TF_BREAKOUT_RATE_INDEX;
        breakout_delta_check = TF_BREAKOUT_DELTA_CHECK;
        breakout_size_factor_min = TF_BREAKOUT_SIZE_FACTOR_MIN;
        breakout_size_factor_max = TF_BREAKOUT_SIZE_FACTOR_MAX;
        breakout_volume_check = TF_BREAKOUT_VOLUME_CHECK;
    }
};
