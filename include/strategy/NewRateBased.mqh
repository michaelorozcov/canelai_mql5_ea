#include "./../../include/dto/args_input/AdvisorArgs.mqh"

#include "./../../include/strategy/RiskManaged.mqh"

class NewRateBased : public RiskManaged {
  public:
    NewRateBased(AdvisorArgs& param_args, string param_advisor_id)
        : RiskManaged(param_args, param_advisor_id) {
        get_last_rate_time(this.last_rate_time);
    }

  protected:
    MqlDateTime last_rate_time;

    void get_last_rate_time(MqlDateTime& dest) {
        datetime time = iTime(_Symbol, _Period, 1);
        TimeToStruct(time, dest);
    }

    void base_on_timer() override {
        on_timer();

        if (is_new_rate())
            on_new_rate();
    }

    bool is_new_rate() {

        MqlDateTime new_value;
        get_last_rate_time(new_value);

        bool diff_day = this.last_rate_time.day_of_year != new_value.day_of_year;
        bool diff_hour = this.last_rate_time.hour != new_value.hour;
        bool diff_min = this.last_rate_time.min != new_value.min;

        if (diff_day || diff_hour || diff_min) {
            this.last_rate_time = new_value;
            return true;
        }

        return false;
    }

    virtual void on_new_rate() {
        // to be implemented by specific strategies
    }
};
