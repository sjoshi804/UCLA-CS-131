//Importing the class for Atomic Integer Array
import java.util.concurrent.atomic.AtomicIntegerArray;

class GetNSet implements State {
    private AtomicIntegerArray value;
    private byte maxval;

    GetNSet(byte[] v) 
    {
        maxval = 127;
        value = new AtomicIntegerArray(v.length);
        for (int i = 0; i < v.length; i++)
            value.set(i, (int) v[i]);
    }

    GetNSet(byte[] v, byte m)
    {
        maxval = m;
        for(int i = 0; i < v.length; i++)
            value.addAndGet(i, (int) v[i]);
    }

    public int size() { return value.length(); }

    public byte[] current() 
    {
        byte[] result = new byte[value.length()];
        for (int i = 0; i < value.length(); i++)
            result[i] = (byte) value.get(i);
        return result;
    }

    public boolean swap(int i, int j) 
    {
        int value_at_i = value.get(i);
        int value_at_j = value.get(j);
        if (value_at_i <= 0 || value_at_j >= maxval) {
            return false;
        }
        value.set(i, value_at_i - 1);
        value.set(j, value_at_j + 1);
        return true;
    }
}