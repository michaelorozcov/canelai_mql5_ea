class MarketZone {
  private:
    static string zone_names[];
    static int zone_counter;

    static void delete_chart_zones() {
        for (int i = 0; i < ArraySize(zone_names); i++)
            ChartUtils::delete_chart_object(zone_names[i]);
        ArrayUtils::clear(zone_names);
        zone_counter = 0;
    }

    static double get_treshold(int start, int end) {
        double average = RatesUtils::get_average_size(start, end);
        return (average * ZONE_SENSITIVITY);
    }

    static void get_zone_from_pivot(
        Zone& dest, ZoneType zone_type, PivotPoint& pivot, bool use_wicks, int end_index) {

        int rate_index = pivot.rate_index;
        double price = 0.0;

        if (zone_type == RESISTANCE)
            price = RatesUtils::get_rate_highest_price(rate_index, use_wicks);
        else
            price = RatesUtils::get_rate_lowest_price(rate_index, use_wicks);

        string name = "Z_" + IntegerToString(++zone_counter) + "_" + DoubleToString(price, 2);

        dest.type = zone_type;
        dest.rate_index = rate_index;
        dest.price = price;
        dest.treshold = get_treshold(rate_index, end_index);
        dest.name = name;
    }

  public:
    static void delete_zones() {
        delete_chart_zones();
    }

    static void draw_zone(Zone& zone, int end_index) {

        if (!zone.is_valid())
            return;

        datetime time_1 = RatesUtils::get_rate_time(zone.rate_index);
        double price_1 = zone.get_top_price();
        datetime time_2 = RatesUtils::get_rate_time(end_index);
        double price_2 = zone.get_bottom_price();

        ChartUtils::create_chart_object(
            OBJ_RECTANGLE, zone.name, time_1, price_1, time_2, price_2);
        ObjectSetInteger(0, zone.name, OBJPROP_COLOR, ZONE_COLOR);
        ObjectSetInteger(0, zone.name, OBJPROP_STYLE, ZONE_STYLE);

        ArrayUtils::add_item(zone_names, zone.name);
    }

    static void draw_zones(Zone& zone[], int end_index) {
        for (int i = 0; i < ArraySize(zone); i++)
            draw_zone(zone[i], end_index);
    }

    static void get_zone_from_block(
        Zone& zone, StructureBlock& structure_bias, bool use_wicks, int end_index) {
        TrendType trend_type = structure_bias.get_trend_type();

        if (trend_type == TREND_BULLISH)
            get_zone_from_pivot(
                zone, RESISTANCE, structure_bias.end, use_wicks, end_index);

        else if (trend_type == TREND_BEARISH)
            get_zone_from_pivot(
                zone, SUPPORT, structure_bias.end, use_wicks, end_index);
    }

    static bool is_broken_by_rate(Zone& zone, int rate_index, double delta) {

        if (zone.type == RESISTANCE) {
            if (!RatesUtils::is_bullish_rate(rate_index))
                return false;

            double low = RatesUtils::get_rate_lowest_price(rate_index, false);
            if (low > zone.get_top_price())
                return false;

            double high = RatesUtils::get_rate_highest_price(rate_index, false);
            return (high > (zone.get_top_price() + delta));
        }

        if (zone.type == SUPPORT) {
            if (!RatesUtils::is_bearish_rate(rate_index))
                return false;

            double high = RatesUtils::get_rate_highest_price(rate_index, false);
            if (high < zone.get_bottom_price())
                return false;

            double low = RatesUtils::get_rate_lowest_price(rate_index, false);
            return (low < (zone.get_bottom_price() - delta));
        }

        return false;
    }
};

static string MarketZone::zone_names[];
static int MarketZone::zone_counter = 0;
