import java.util.concurrent.atomic.AtomicIntegerArray;

class GetNSetState implements State {
    private AtomicIntegerArray value;
    private byte maxval;

    GetNSetState(byte[] v) 
	{
        maxval = 127;
        int[] int_array = new int[v.length];

        for (int i = 0; i < v.length; i++)
            int_array[i] = v[i];

        value = new AtomicIntegerArray(int_array);
        
    }

    GetNSetState(byte[] v, byte m) 
	{
        maxval = m;
        int[] int_array = new int[v.length];

        for (int i = 0; i < v.length; i++)
            int_array[i] = v[i];

        value = new AtomicIntegerArray(int_array);
        
    }

    public int size() 
	{ 
		return value.length(); 
	}

    public byte[] current() 
	{
        byte[] byte_array = new byte[value.length()];

        for (int i = 0; i < value.length(); i++) 
            byte_array[i] = (byte) value.get(i);

        return byte_array;
    }

    public boolean swap(int i, int j) 
	{
        int value_at_i = value.get(i);
        int value_at_j = value.get(j);

        if (value_at_i <= 0 || value_at_j >= maxval) 
            return false;

        value.set(i, value_at_i - 1);
        value.set(j, value_at_j + 1);
        return true;
    }
}