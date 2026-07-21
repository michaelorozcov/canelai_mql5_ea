//+------------------------------------------------------------------+
//|                                                   canelAI_EA.mq5 |
//|                                  Copyright 2026, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property version "2.11"

#include "include/dto/args_input/AdvisorArgs.mqh"
#include "include/dto/args_input/general/RiskManagement.mqh"
#include "include/dto/args_input/strategy/StrategyType.mqh"

#include "include/dto/Session.mqh"

#include "include/utils/Constants.mqh"

#include "include/indicators/BollingerBands.mqh"
#include "include/indicators/RSI.mqh"

#include "include/Advisor.mqh"

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "==== General ====";
input StrategyType in_strategy = BLOCK_REVERSION; // Strategy
input ENUM_MARKET_SESSION in_session = ALL;       // Session
input bool in_visual_mode = true;                 // Visual
input bool in_log_file = true;                    // Logs

input group "==== Risk Management ====";
input ENUM_TRADE_RISK_TYPE in_trade_risk_type = TRADE_RISK_PCT;            // Trade risk type
input double in_trade_risk_value = 1.0;                                    // Trade risk value
input double in_reward_ratio = 3.0;                                        // Reward ratio (R:R)
input double in_breakeven = 0.0;                                           // Breakeven
input double in_trailing_stop = 0.0;                                       // Trailing stop (R)
input double in_trade_time_limit = 0.0;                                    // Trade limit (minutes)
input ENUM_DAILY_LIMIT_TYPE in_daily_limit_won_type = DAILY_LIMIT_TRADES;  // Won daily limit type
input double in_daily_limit_won_value = 1.0;                               // Won daily limit value
input ENUM_DAILY_LIMIT_TYPE in_daily_limit_lost_type = DAILY_LIMIT_TRADES; // Lost daily limit type
input double in_daily_limit_lost_value = 1.0;                              // Lost daily limit value

input group "==== Strategy: Trend Follow ====";
input int tf_shift_minutes = 720;                // Shift Minutes
input int tf_structure_blocks_distance_max = 60; // Blocks distance max (in minutes)
input bool tf_breakout_delta_check = false;      // Delta check (above zone)
input bool tf_breakout_volume_check = false;     // Volume check (tick volume)

input group "==== Strategy: Block Reversion ====";
input bool br_analysis_mode = true;                             // Analysis mode
input int br_pivot_point_strength = 5;                          // Pivot Strength
input ENUM_BOLLINGER_PERIOD br_bollinger_period = BB_PERIOD_20; // Bollinger period
input ENUM_RSI_PERIOD br_rsi_period = RSI_PERIOD_14;            // RSI period
input double br_sl_blocks = 0.0;                                // SL blocks

//+------------------------------------------------------------------+
//| Advisor Arguments                                                |
//+------------------------------------------------------------------+
AdvisorArgs advisor_args;

void set_advisor_args() {
    set_general_args();
    set_risk_management_args();
    set_strategy_args();
}

void set_general_args() {
    advisor_args.general.strategy = in_strategy;
    advisor_args.general.session = in_session;
    advisor_args.general.visual_mode = in_visual_mode;
    advisor_args.general.log_file = in_log_file;
}

void set_risk_management_args() {

    advisor_args.risk.trade_risk.type = in_trade_risk_type;
    advisor_args.risk.trade_risk.value = in_trade_risk_value;

    advisor_args.risk.reward_ratio = in_reward_ratio;
    advisor_args.risk.breakeven = in_breakeven;
    advisor_args.risk.trailing_stop = in_trailing_stop;
    advisor_args.risk.time_limit = in_trade_time_limit;

    advisor_args.risk.daily_limit_won.type = in_daily_limit_won_type;
    advisor_args.risk.daily_limit_won.value = in_daily_limit_won_value;

    advisor_args.risk.daily_limit_lost.type = in_daily_limit_lost_type;
    advisor_args.risk.daily_limit_lost.value = in_daily_limit_lost_value;
}

void set_strategy_args() {
    switch (advisor_args.general.strategy) {
    case TREND_FOLLOW:
        set_trend_follow_args();
        break;
    case BLOCK_REVERSION:
        set_block_reversion_args();
        break;
    default:
        break;
    }
}

void set_trend_follow_args() {
    advisor_args.trend_follow.analysis_shift_minutes = tf_shift_minutes;
    advisor_args.trend_follow.structure_blocks_distance_max = tf_structure_blocks_distance_max;
    advisor_args.trend_follow.breakout_delta_check = tf_breakout_delta_check;
    advisor_args.trend_follow.breakout_volume_check = tf_breakout_volume_check;
}

void set_block_reversion_args() {
    advisor_args.block_reversion.analysis_mode = br_analysis_mode;
    advisor_args.block_reversion.pivot_point_strength = br_pivot_point_strength;
    advisor_args.block_reversion.bollinger_period = br_bollinger_period;
    advisor_args.block_reversion.rsi_period = br_rsi_period;
    advisor_args.block_reversion.sl_blocks = br_sl_blocks;
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
    Print("canelAI_EA: OnInit");
    delete_chart_objects();
    set_advisor_args();
    Advisor::on_init(advisor_args);
    set_timer();
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
    Print("canelAI_EA: OnDeinit");
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
