#include "Session.mqh"

#include "../utils/Constants.mqh"

#include "../strategy/Strategy.mqh"
#include "../strategy/trend_follow/TrendFollowArgs.mqh"
#include "../strategy/trend_follow_HFT/TrendFollowHFTArgs.mqh"
#include "../strategy/trend_recoil/TrendRecoilArgs.mqh"

struct AdvisorArgs {

    StrategyType strategy;
    MarketSessionEnum session;
    bool visual_mode;
    bool log_file;

    TrendFollowArgs trend_follow;
    TrendFollowHFTArgs trend_follow_hft;
    TrendRecoilArgs trend_recoil;

    AdvisorArgs() {
        strategy = StrategyType::TREND_FOLLOW;
        session = MarketSessionEnum::NEW_YORK;
        visual_mode = true;
        log_file = true;
    }
};
