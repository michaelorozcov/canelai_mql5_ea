#include "Session.mqh"
#include "Setup.mqh"

#include "../setup/trend_follow/TrendFollowArgs.mqh"

struct AdvisorArgs {

    bool visual_mode;

    MarketSessionEnum session;
    SetupType setup_type;

    TrendFollowArgs trend_follow;

    AdvisorArgs() {
        visual_mode = false;
        session = MarketSessionEnum::NEW_YORK;
        setup_type = SetupType::TREND_FOLLOW;
    }
};
