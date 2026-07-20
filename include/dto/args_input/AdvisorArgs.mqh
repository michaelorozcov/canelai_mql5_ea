#include "./../../../include/dto/args_input/general/GeneralArgs.mqh"
#include "./../../../include/dto/args_input/general/RiskManagement.mqh"
#include "./../../../include/dto/args_input/strategy/TrendFollowArgs.mqh"

struct AdvisorArgs {

    // General
    GeneralArgs general;
    RiskManagement risk;

    // Strategies
    TrendFollowArgs trend_follow;
};
