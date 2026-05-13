//+------------------------------------------------------------------+
//|                                                   canelAI_EA.mq5 |
//|                                  Copyright 2026, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property version "1.2"

#include "include/dto/AdvisorArgs.mqh"
#include "include/dto/Session.mqh"
#include "include/dto/Setup.mqh"

#include "include/Advisor.mqh"

//+------------------------------------------------------------------+
//| Inputs
//+------------------------------------------------------------------+
input group "==== General ====";
input bool visual_mode = true;                 // Visual mode
input MarketSessionEnum in_session = NEW_YORK; // Session
// input SetupType in_setup_type = TREND_FOLLOW;  // Setup

input group "==== Structure ====";
input int in_structure_blocks_distance_max = 120; // Blocks distance max (in minutes)

input group "==== Breakout ====";
input bool in_breakout_delta_check = false;  // Delta check (above zone)
input bool in_breakout_volume_check = false; // Volume check (tick volume)

input group "==== Risk Management ====";
input double in_risk_percentage = 1.0;          // Risk %
input double in_risk_reward_ratio = 3.0;        // R:R
input double in_breakeven_value = 2.0;          // BE
input int in_daily_limit_losses = 2;            // Daily limit losses
input int in_daily_limit_wins = 1;              // Daily limit wins
input double in_monthly_limit_percentage = 0.0; // Monthly limit %

// Advisor
Advisor* advisor_instance;

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    delete advisor_instance;
    advisor_instance = NULL;
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    AdvisorArgs args;

    // General
    args.visual_mode = visual_mode;
    args.session = in_session;
    // args.setup_type = in_setup_type;

    // Structure
    args.trend_follow.structure_blocks_distance_max = in_structure_blocks_distance_max;

    // Breakout
    args.trend_follow.breakout_delta_check = in_breakout_delta_check;
    args.trend_follow.breakout_volume_check = in_breakout_volume_check;

    // Risk Management
    args.trend_follow.risk_percentage = in_risk_percentage;
    args.trend_follow.risk_reward_ratio = in_risk_reward_ratio;
    args.trend_follow.breakeven_value = in_breakeven_value;
    args.trend_follow.daily_limit_losses = in_daily_limit_losses;
    args.trend_follow.daily_limit_wins = in_daily_limit_wins;
    args.trend_follow.monthly_limit_percentage = in_monthly_limit_percentage;

    advisor_instance = new Advisor(args);

    return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    if (CheckPointer(advisor_instance) == POINTER_DYNAMIC)
        advisor_instance.on_tick();
}

//+------------------------------------------------------------------+
