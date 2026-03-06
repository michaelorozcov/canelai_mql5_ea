/*
#include "ChartUtils.mqh"
#include "../DataTransferObjects.mqh"

class Structure
{
private:





public:
    static void delete_swings()
    {
        for (int i = 0; i < ArraySize(Structure::swing_names); i++)
            delete_swing(Structure::swing_names[i]);

        ArrayResize(Structure::swing_names, 0);
    }

    static void draw_swings(AdvisorData &data)
    {
        delete_swings();

        for (int i = 0; i < ArraySize(data.swing_highs); i++)
            draw_swing(data.swing_highs[i]);

        for (int i = 0; i < ArraySize(data.swing_lows); i++)
            draw_swing(data.swing_lows[i]);
    }
};


*/