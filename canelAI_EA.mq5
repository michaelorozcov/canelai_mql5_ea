//+------------------------------------------------------------------+
//|                                                   canelAI_EA.mq5 |
//|                                  Copyright 2026, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property version "2.1"

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

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "==== General ====";
input StrategyType in_strategy = TREND_FOLLOW; // Strategy
input MarketSessionEnum in_session = NEW_YORK; // Session
input bool in_visual_mode = true;              // Visual

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
//| Instances                                                        |
//+------------------------------------------------------------------+
AdvisorArgs advisor_args;
Strategy* advisor_strategy;
bool advisor_trading_time;

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print("Advisor Deinit");
    delete_chart_objects();
    delete_instances();
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    Print("Advisor Init");
    delete_chart_objects();
    init_instances();
    return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    if (advisor_trading_time)
        advisor_strategy.base_on_tick();
}

//+------------------------------------------------------------------+
//| Expert timer function                                            |
//+------------------------------------------------------------------+
void OnTimer() {

    bool new_value = is_trading_time();

    if (advisor_trading_time != new_value) {
        advisor_trading_time = new_value;

        advisor_strategy.base_on_trading_time_change(advisor_trading_time);
        update_status_board();
    }

    if (advisor_trading_time)
        advisor_strategy.base_on_timer();
}

//+------------------------------------------------------------------+
//| Expert trade transaction function                                |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result) {
    advisor_strategy.base_on_trade_transaction(trans, request, result);
}

//+------------------------------------------------------------------+
//| Functions                                                        |
//+------------------------------------------------------------------+
void delete_chart_objects() {
    if (in_visual_mode) {
        StatusBoard::delete_status_board();
        ObjectsDeleteAll(0);
    }
}

void update_status_board() {
    if (in_visual_mode)
        StatusBoard::update(advisor_args);
}

void delete_instances() {
    delete_strategy_instance();
    delete_timer();
}

void delete_strategy_instance() {
    if (CheckPointer(advisor_strategy) == POINTER_DYNAMIC) {
        delete advisor_strategy;
        advisor_strategy = NULL;
    }
}

void delete_timer() {
    EventKillTimer();
}

void set_timer() {
    EventSetMillisecondTimer(ADVISOR_TIMER_INTERVAL_MILLISECONDS);
}

bool is_trading_time() {
    return MarketSession::is_trading_time(advisor_args.session);
}

void init_instances() {
    advisor_args.strategy = in_strategy;
    advisor_args.session = in_session;
    advisor_args.visual_mode = in_visual_mode;
    advisor_trading_time = is_trading_time();

    set_strategy_instance();
    update_status_board();
    set_timer();
}

void set_strategy_instance() {

    delete_strategy_instance();

    switch (advisor_args.strategy) {

    case TREND_FOLLOW:
        set_trend_follow_args();
        advisor_strategy = new TrendFollow(advisor_args);
        break;

    case TREND_FOLLOW_HFT:
        advisor_strategy = new TrendFollowHFT(advisor_args);
        break;

    case TREND_RECOIL:
        set_trend_recoil_args();
        advisor_strategy = new TrendRecoil(advisor_args);
        break;

    default:
        advisor_strategy = new Strategy();
    }
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

void set_trend_recoil_args() {
    // TODO
}
