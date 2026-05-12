class ChartUtils {
  public:
    static void delete_chart_object(string name) {
        if (ObjectFind(0, name) >= 0)
            ObjectDelete(0, name);
    }

    static void create_chart_object(
        ENUM_OBJECT type, string name,
        datetime time = 0, double price = 0,
        datetime time_2 = 0, double price_2 = 0) {

        delete_chart_object(name);
        ObjectCreate(0, name, type, 0, time, price, time_2, price_2);
        ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
        ObjectSetInteger(0, name, OBJPROP_BACK, true);
        ObjectSetInteger(0, name, OBJPROP_FILL, false);
    }
};
