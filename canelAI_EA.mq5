//+------------------------------------------------------------------+
//|                                                   canelAI_EA.mq5 |
//|                                  Copyright 2026, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property version "2.6"

#include <Trade\Trade.mqh>

#include "include/dto/AdvisorArgs.mqh"
#include "include/dto/PivotPoint.mqh"
#include "include/dto/Session.mqh"
#include "include/dto/Structure.mqh"
#include "include/dto/Trend.mqh"
#include "include/dto/Zone.mqh"

#include "include/utils/ArrayUtils.mqh"
#include "include/utils/ChartUtils.mqh"
#include "include/utils/Constants.mqh"
#include "include/utils/RatesUtils.mqh"
#include "include/utils/StatusBoard.mqh"

#include "include/market/MarketOrder.mqh"
#include "include/market/MarketPivot.mqh"
#include "include/market/MarketSession.mqh"
#include "include/market/MarketStructure.mqh"
#include "include/market/MarketTrend.mqh"
#include "include/market/MarketZone.mqh"

#include "include/strategy/Strategy.mqh"
#include "include/strategy/trend_follow/TrendFollow.mqh"
#include "include/strategy/trend_follow_HFT/TrendFollowHFT.mqh"
#include "include/strategy/trend_recoil/TrendRecoil.mqh"

#include "include/Advisor.mqh"

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "==== General ====";
input StrategyType in_strategy = TREND_FOLLOW;   // Strategy
input ENUM_MARKET_SESSION in_session = NEW_YORK; // Session
input bool in_visual_mode = true;                // Visual
input bool in_log_file = true;                   // Logs

input group "==== Strategy: Trend Follow ====";
input int tf_shift_minutes = 370;                // Shift Minutes
input int tf_structure_blocks_distance_max = 60; // Blocks distance max (in minutes)
input bool tf_breakout_delta_check = false;      // Delta check (above zone)
input bool tf_breakout_volume_check = false;     // Volume check (tick volume)
input double tf_risk_percentage = 1.0;           // Risk %
input double tf_risk_reward_ratio = 3.0;         // R:R
input double tf_breakeven_value = 0;             // BE
input int tf_daily_limit_losses = 1;             // Daily limit losses
input int tf_daily_limit_wins = 1;               // Daily limit wins
input double tf_monthly_limit_percentage = 0.0;  // Monthly limit %

//+------------------------------------------------------------------+
//| Advisor Arguments                                                |
//+------------------------------------------------------------------+
AdvisorArgs advisor_args;

void set_advisor_args() {

    // General
    advisor_args.strategy = in_strategy;
    advisor_args.session = in_session;
    advisor_args.visual_mode = in_visual_mode;
    advisor_args.log_file = in_log_file;

    if (advisor_args.strategy == TREND_FOLLOW)
        set_trend_follow_args();
}

void set_trend_follow_args() {
    advisor_args.trend_follow.analysis_shift_minutes = tf_shift_minutes;
    advisor_args.trend_follow.structure_blocks_distance_max = tf_structure_blocks_distance_max;
    advisor_args.trend_follow.breakout_delta_check = tf_breakout_delta_check;
    advisor_args.trend_follow.breakout_volume_check = tf_breakout_volume_check;
    advisor_args.trend_follow.risk_percentage = tf_risk_percentage;
    advisor_args.trend_follow.risk_reward_ratio = tf_risk_reward_ratio;
    advisor_args.trend_follow.breakeven_value = tf_breakeven_value;
    advisor_args.trend_follow.daily_limit_losses = tf_daily_limit_losses;
    advisor_args.trend_follow.daily_limit_wins = tf_daily_limit_wins;
    advisor_args.trend_follow.monthly_limit_percentage = tf_monthly_limit_percentage;
}

//+------------------------------------------------------------------+
//| Functions                                                        |
//+------------------------------------------------------------------+

void delete_chart_objects() {
    ObjectsDeleteAll(0);
}

void delete_timer() {
    EventKillTimer();
}

void set_timer() {
    EventSetMillisecondTimer(ADVISOR_TIMER_INTERVAL_MILLISECONDS);
}

//+------------------------------------------------------------------+
//| Event Handling                                                   |
//+------------------------------------------------------------------+

int OnInit() {
    Print("OnInit");
    delete_chart_objects();
    set_advisor_args();
    Advisor::on_init(advisor_args);
    set_timer();
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
    Print("OnDeinit");
    delete_timer();
    Advisor::on_deinit();
    delete_chart_objects();
}

void OnTick() {
    Advisor::on_tick();
}

void OnTimer() {
    Advisor::on_timer();
}

void OnTradeTransaction(
    const MqlTradeTransaction& trans,
    const MqlTradeRequest& request,
    const MqlTradeResult& result) {
    Advisor::on_trade_transaction(trans, request, result);
}
