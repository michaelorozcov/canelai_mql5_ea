// Divide into 1000 to get PCT
enum ENUM_FIBO_LEVELS {
    FIBO_LEVEL_0 = 0,
    FIBO_LEVEL_23 = 236,
    FIBO_LEVEL_38 = 382,
    FIBO_LEVEL_50 = 500,
    FIBO_LEVEL_61 = 618,
    FIBO_LEVEL_78 = 786,
    FIBO_LEVEL_100 = 1000
};

ENUM_FIBO_LEVELS FIBO_LEVELS[] = {
    FIBO_LEVEL_0,
    FIBO_LEVEL_23,
    FIBO_LEVEL_38,
    FIBO_LEVEL_50,
    FIBO_LEVEL_61,
    FIBO_LEVEL_78,
    FIBO_LEVEL_100
    //
};

double get_fibo_value(ENUM_FIBO_LEVELS level) {
    double value = ((double)level / 1000.0);
    return NormalizeDouble(value, 3);
}
