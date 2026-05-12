class ArrayUtils {
  public:
    template <typename T>
    static void add_item(T& array[], T& item) {
        int size = ArraySize(array);
        ArrayResize(array, size + 1);
        array[size] = item;
    }

    template <typename T>
    static void clear(T& array[]) {
        ArrayFree(array);
    }

    template <typename T>
    static void copy(T& dest[], T& src[]) {
        clear(dest);
        ArrayResize(dest, ArraySize(src));
        for (int i = 0; i < ArraySize(src); i++)
            dest[i] = src[i];
    }

    template <typename T>
    static void get_last_item(T& dest, T& array[]) {
        int size = ArraySize(array);
        if (size > 0)
            dest = array[size - 1];
    }
};
