#include "Session.mqh"

#include "../utils/Constants.mqh"

#include "../strategy/Strategy.mqh"

#include "../strategy/block_reversion/BlockReversionArgs.mqh"
#include "../strategy/trend_follow/TrendFollowArgs.mqh"
#include "../strategy/trend_follow_HFT/TrendFollowHFTArgs.mqh"
#include "../strategy/trend_recoil/TrendRecoilArgs.mqh"

struct AdvisorArgs {

    StrategyType strategy;
    ENUM_MARKET_SESSION session;
    bool visual_mode;
    bool log_file;

    BlockReversionArgs block_reversion;

    TrendFollowArgs trend_follow;
    TrendFollowHFTArgs trend_follow_hft;
    TrendRecoilArgs trend_recoil;

    AdvisorArgs() {
        strategy = StrategyType::TREND_FOLLOW;
        session = ENUM_MARKET_SESSION::NEW_YORK;
        visual_mode = true;
        log_file = true;
    }
};
