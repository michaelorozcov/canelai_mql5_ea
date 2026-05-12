enum MarketSessionEnum {
    LONDON,
    NEW_YORK,
    TOKYO,
    SYDNEY,
    ALL,
};

struct MarketSessionTime {
    MarketSessionEnum session;
    string start;
    string end;
};

// UTC 24hrs
const MarketSessionTime MARKET_SESSIONS[] = {
    {LONDON, "08:00", "17:00"},
    {NEW_YORK, "12:00", "21:00"},
    {TOKYO, "00:00", "09:00"},
    {SYDNEY, "20:00", "05:00"},
    {ALL, "00:00", "23:59"},
};
