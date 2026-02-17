class Zone
{
private:
    double bottom_price()
    {
        return this.price - this.margin;
    }

    double top_price()
    {
        return this.price + this.margin;
    }

public:
    string name;
    int candle;
    double price;
    double margin;

    Zone() {}

    Zone(int ref_candle, double ref_price, double ref_margin)
    {
        this.candle = ref_candle;
        this.price = ref_price;
        this.margin = ref_margin;
        this.name = "zone_" + IntegerToString(this.candle) + "_" + DoubleToString(this.price, 2);
    }

    bool contains_price(double ref_price)
    {
        return (ref_price >= bottom_price()) && (ref_price <= top_price());
    }

    void draw_zone(int candle_rigth_limit)
    {
        delete_zone();

        // TODO: remove
        /*
                datetime time = iTime(_Symbol, PERIOD_CURRENT, this.candle);
                string h_name = "h_" + this.name;
                ObjectCreate(0, h_name, OBJ_HLINE, 0, time, this.price);
                ObjectSetInteger(0, h_name, OBJPROP_COLOR, clrRed);

                string v_name = "v_" + this.name;
                ObjectCreate(0, v_name, OBJ_VLINE, 0, time, 0);
                ObjectSetInteger(0, v_name, OBJPROP_COLOR, clrRed);

                return;
        */
        // TODO: remove

        datetime time_left = iTime(_Symbol, PERIOD_CURRENT, this.candle);
        datetime time_rigth = iTime(_Symbol, PERIOD_CURRENT, candle_rigth_limit);

        ObjectCreate(0, this.name, OBJ_RECTANGLE, 0, time_left, top_price(), time_rigth, bottom_price());
        ObjectSetInteger(0, this.name, OBJPROP_COLOR, clrRed);
        ObjectSetInteger(0, this.name, OBJPROP_BACK, true);
        ObjectSetInteger(0, this.name, OBJPROP_FILL, false);
        ObjectSetInteger(0, this.name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, this.name, OBJPROP_SELECTED, false);
    }

    void delete_zone()
    {
        ObjectDelete(0, this.name);
        ObjectDelete(0, "h_" + this.name);
        ObjectDelete(0, "v_" + this.name);
    }
};

class PriceLevel
{
public:
    int candle;
    double price;

    PriceLevel() {}

    PriceLevel(int ref_candle, double ref_price)
    {
        this.candle = ref_candle;
        this.price = ref_price;
    }
};
