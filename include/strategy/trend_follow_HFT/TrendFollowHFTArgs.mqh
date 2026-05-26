static const int TF_HFT_ANALYSIS_SHIFT_MINUTES = 120;
static const int TF_HFT_ANALYSIS_LOWEST_INDEX = 2;

static const int TF_HFT_LAST_RATE_INDEX = 1;

static const int TF_HFT_TRADES_MAX_AMOUNT = 5;

struct TrendFollowHFTArgs {
    int analysis_shift_minutes;
    int analysis_lowest_index;
    int last_rate_index;
    int trades_max_amount;

    TrendFollowHFTArgs() {
        analysis_shift_minutes = TF_HFT_ANALYSIS_SHIFT_MINUTES;
        analysis_lowest_index = TF_HFT_ANALYSIS_LOWEST_INDEX;
        last_rate_index = TF_HFT_LAST_RATE_INDEX;
        trades_max_amount = TF_HFT_TRADES_MAX_AMOUNT;
    }
};
