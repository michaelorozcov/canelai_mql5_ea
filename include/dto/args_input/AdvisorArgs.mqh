#include "./../../../include/dto/args_input/general/GeneralArgs.mqh"
#include "./../../../include/dto/args_input/general/RiskManagement.mqh"
#include "./../../../include/dto/args_input/strategy/TrendFollowArgs.mqh"
#include "./../../../include/dto/args_input/strategy/TrendFollowFiboArgs.mqh"

struct AdvisorArgs {

    // General
    GeneralArgs general;
    RiskManagement risk;

    // Strategies
    TrendFollowArgs trend_follow;
    TrendFollowFiboArgs trend_follow_fibo;
};
