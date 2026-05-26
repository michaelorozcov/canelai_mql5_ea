static const int TR_ANALYSIS_SHIFT_MINUTES = 370;
static const int TR_ANALYSIS_LOWEST_INDEX = 1;

struct TrendRecoilArgs {
    int analysis_shift_minutes;
    int analysis_lowest_index;

    TrendRecoilArgs() {
        analysis_shift_minutes = TR_ANALYSIS_SHIFT_MINUTES;
        analysis_lowest_index = TR_ANALYSIS_LOWEST_INDEX;
    }
};
