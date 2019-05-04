import java.util.concurrent.locks.ReentrantLock;

class BetterSafeState implements State {
    private byte[] value;
    private ReentrantLock value_lock;
    private byte maxval;

    BetterSafeState(byte[] v) 
    { 
        value = v; 
        maxval = 127; 
        value_lock = new ReentrantLock();
    }

    BetterSafeState(byte[] v, byte m) 
    { 
        value = v;
        maxval = m; 
        value_lock = new ReentrantLock();
    }

    public int size() 
    {
        return value.length;
    }

    public byte[] current() 
    { 
        return value; 
    }

    public boolean swap(int i, int j) 
    {
        value_lock.lock();
        if (value[i] <= 0 || value[j] >= maxval) 
        {
            value_lock.unlock();
            return false;
        }
        value[i]--;
        value[j]++;
        value_lock.unlock();
        return true;
    }
}