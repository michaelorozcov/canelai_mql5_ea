#include "./../../../../include/dto/args_input/general/FiboLevels.mqh"

static const int TFB_ANALYSIS_SHIFT_MINUTES = 720;
static const int TFB_ANALYSIS_LOWEST_INDEX = 1;
static const int TFB_PIVOT_STRENGTH = 1;

struct TrendFollowFiboArgs {

    int analysis_shift_minutes;
    int analysis_lowest_index;
    int pivot_strength;

    ENUM_FIBO_LEVELS entry_level;
    ENUM_FIBO_LEVELS sl_level;
    ENUM_FIBO_LEVELS tp_level;

    TrendFollowFiboArgs() {
        this.analysis_shift_minutes = TFB_ANALYSIS_SHIFT_MINUTES;
        this.analysis_lowest_index = TFB_ANALYSIS_LOWEST_INDEX;
        this.pivot_strength = TFB_PIVOT_STRENGTH;
        this.entry_level = FIBO_LEVEL_78;
        this.sl_level = FIBO_LEVEL_100;
        this.tp_level = FIBO_LEVEL_0;
    }
};
