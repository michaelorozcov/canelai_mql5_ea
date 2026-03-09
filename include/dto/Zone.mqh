enum ZoneType {
    SUPPORT,
    RESISTANCE,
};

struct Zone {
    ZoneType type;
    int rate_index;
    double price;
    double treshold;
    string name;
    int hints;

    Zone() {
        this.clear();
    }

    void add_hint() {
        this.hints++;
    }

    double get_bottom_price() {
        return (price - treshold);
    }

    double get_top_price() {
        return (price + treshold);
    }

    bool contains_price(double ref_price) {
        return (ref_price >= get_bottom_price()) && (ref_price <= get_top_price());
    }

    bool is_valid() {
        return (rate_index > 0) && (price > 0.0);
    }

    void clear() {
        this.rate_index = 0;
        this.price = 0.0;
        this.treshold = 0.0;
        this.name = "";
        this.hints = 0;
    }
};
