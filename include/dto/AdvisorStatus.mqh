enum ENUM_STATUS_ACTIVE_REASON {
    ON_BY_SESSION,
    OFF_BY_SESSION,
    OFF_BY_LIMITS,
};

class AdvisorStatus {
  public:
    string advisor_id;
    string strategy_name;
    bool visual_mode;
    bool trading_time;
    bool active;
    ENUM_STATUS_ACTIVE_REASON reason;
};
