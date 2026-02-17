class Board
{
private:
    static const string BOARD_NAME;
    static const int BOARD_XDISTANCE;
    static const int BOARD_YDISTANCE;
    static const int BOARD_XSIZE;
    static const int BOARD_YSIZE;

    static string labels[];

    static void create_object(ENUM_OBJECT type, string name)
    {
        ObjectDelete(0, name);
        ObjectCreate(0, name, type, 0, 0, 0);
        ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
    }

    static void resize_board()
    {
        int x_margin = 2;
        int contained_labels = ArraySize(Board::labels);

        ObjectSetInteger(0, BOARD_NAME, OBJPROP_XDISTANCE, BOARD_XDISTANCE - x_margin);
        ObjectSetInteger(0, BOARD_NAME, OBJPROP_YDISTANCE, BOARD_YDISTANCE);
        ObjectSetInteger(0, BOARD_NAME, OBJPROP_XSIZE, BOARD_XSIZE + x_margin);
        ObjectSetInteger(0, BOARD_NAME, OBJPROP_YSIZE, (BOARD_YSIZE * contained_labels));
    }

    static void create_board(color bg_color = clrSienna)
    {
        create_object(OBJ_RECTANGLE_LABEL, BOARD_NAME);
        ObjectSetInteger(0, BOARD_NAME, OBJPROP_COLOR, bg_color);
        ObjectSetInteger(0, BOARD_NAME, OBJPROP_BGCOLOR, bg_color);
        ObjectSetInteger(0, BOARD_NAME, OBJPROP_BORDER_TYPE, BORDER_FLAT);
        resize_board();
    }

public:
    static void delete_board()
    {
        delete_labels();
        ObjectDelete(0, BOARD_NAME);
    }

    static void delete_labels()
    {
        for (int i = 0; i < ArraySize(Board::labels); i++)
            ObjectDelete(0, Board::labels[i]);

        ArrayResize(Board::labels, 0);
    }

    static void create_label(string label_name, string label_text)
    {
        if (ObjectFind(0, BOARD_NAME) == -1)
            create_board();

        int labels_size = ArraySize(Board::labels);
        int position = labels_size + 1;

        create_object(OBJ_LABEL, label_name);
        ObjectSetInteger(0, label_name, OBJPROP_XDISTANCE, BOARD_XDISTANCE);
        ObjectSetInteger(0, label_name, OBJPROP_YDISTANCE, (BOARD_YDISTANCE * position));
        ObjectSetInteger(0, label_name, OBJPROP_XSIZE, BOARD_XSIZE);
        ObjectSetInteger(0, label_name, OBJPROP_YSIZE, BOARD_YSIZE);
        ObjectSetString(0, label_name, OBJPROP_TEXT, label_text);
        ObjectSetInteger(0, label_name, OBJPROP_COLOR, clrWhite);

        ArrayResize(Board::labels, position);
        Board::labels[labels_size] = label_name;

        resize_board();
    }
};

static const string Board::BOARD_NAME = "status_board_name";
static const int Board::BOARD_XDISTANCE = 5;
static const int Board::BOARD_YDISTANCE = 25;
static const int Board::BOARD_XSIZE = 100;
static const int Board::BOARD_YSIZE = 25;

string Board::labels[];
