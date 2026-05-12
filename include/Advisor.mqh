#include "dto/AdvisorArgs.mqh"
#include "dto/PivotPoint.mqh"
#include "dto/Session.mqh"
#include "dto/Setup.mqh"
#include "dto/Structure.mqh"
#include "dto/Trend.mqh"
#include "dto/Zone.mqh"

#include "utils/ArrayUtils.mqh"
#include "utils/ChartUtils.mqh"
#include "utils/Constants.mqh"
#include "utils/RatesUtils.mqh"

#include "StatusBoard.mqh"

#include "MarketOrder.mqh"
#include "MarketPivot.mqh"
#include "MarketSession.mqh"
#include "MarketStructure.mqh"
#include "MarketTrend.mqh"
#include "MarketZone.mqh"

#include "setup/trend_follow/TrendFollow.mqh"

class Advisor {

  public:
    Advisor(AdvisorArgs& args) {
        init(args);
    }

    ~Advisor() {
        deinit();
    }

    void on_tick() {
        process_new_tick();
    }

  private:
    AdvisorArgs data;
    datetime last_rate_time;

    void init(AdvisorArgs& args) {
        Print("Advisor Init");
        delete_chart_objects();
        set_args(args);
    }

    void deinit() {
        Print("Advisor Deinit");
        delete_chart_objects();
    }

    void delete_chart_objects() {
        delete_market_analysis();
        StatusBoard::delete_status_board();
        ObjectsDeleteAll(0);
    }

    void process_new_tick() {

        if (MarketOrder::has_open_positions())
            check_open_positions();

        if (!is_new_rate())
            return;

        process_new_rate();
    }

    void set_args(AdvisorArgs& new_args) {
        this.data = new_args;
        TrendFollow::set_args(new_args);
    }

    bool is_trading_time() {
        return MarketSession::is_trading_time(this.data.session);
    }

    void update_status_board() {
        if (this.data.visual_mode)
            StatusBoard::update(this.data);
    }

    bool is_new_rate() {
        datetime new_value = iTime(_Symbol, _Period, 1);
        if (this.last_rate_time != new_value) {
            this.last_rate_time = new_value;
            return true;
        }
        return false;
    }

    void delete_market_analysis() {
        delete_rates();
        delete_pivot_points();
        delete_structure();
        delete_trends();
        delete_zones();
    }

    void set_market_analysis() {
        set_rates();
        set_pivot_points();
        set_structure();
    }

    void set_rates() {
        RatesUtils::set_rates(this.data);
    }

    void delete_rates() {
        RatesUtils::delete_rates();
    }

    void set_pivot_points() {
        MarketPivot::set_pivot_points(this.data);
    }

    void delete_pivot_points() {
        MarketPivot::delete_pivot_points();
    }

    void set_structure() {
        MarketStructure::set_market_structure(this.data);
    }

    void delete_structure() {
        MarketStructure::delete_market_structure();
    }

    void delete_trends() {
        MarketTrend::delete_trends();
    }

    void delete_zones() {
        MarketZone::delete_zones();
    }

    bool has_reached_daily_limit() {
        if (this.data.setup_type == SetupType::TREND_FOLLOW)
            return TrendFollow::has_reached_daily_limit();

        return true;
    }

    void check_open_positions() {
        if (this.data.setup_type == SetupType::TREND_FOLLOW)
            TrendFollow::check_open_positions();
    }

    void process_new_rate() {

        update_status_board();

        delete_market_analysis();

        if (!is_trading_time())
            return;

        if (has_reached_daily_limit())
            return;

        set_market_analysis();

        if (this.data.setup_type == SetupType::TREND_FOLLOW)
            TrendFollow::process_new_rate();
    }
};
