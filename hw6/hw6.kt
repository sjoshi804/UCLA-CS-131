fun <T> everyNth(L: List<T>, N: Int): List<T>
{

    //Checks if N is valid, if not returns empty list
    if (N > L.size || N <= 0)
        return listOf<T>()

    //Loop to add every Nth to a mutable list
    var everyChosen = mutableListOf<T>()
    var i = N - 1
    while (i < L.size)
    {
        everyChosen.add(L[i])
        i += N
    }

    //Ensures list returned is immutable
    return everyChosen.toList()
}

fun main(args: Array<String>) {
    var list = mutableListOf("Hello", "Hi", "Ho")
    if(everyNth(list, 1) == listOf("Hello", "Hi", "Ho"))
        println("TEST 1 SUCCESS")
    else
        println("TEST 1 FAIL")
    list.add("hello")
    if(everyNth(list, 2) == listOf("Hi", "hello"))
        println("TEST 2 SUCCESS")
    else
        println("TEST 3 FAIL")
    var list2 = mutableListOf(1, 2, 3, 4, 5, 6)
    if(everyNth(list2, 2) == listOf(2,4,6))
        println("TEST 3 SUCCESS")
    else
        println("TEST 3 FAIL")
    //everyNth(list2, 2).add(3)
    if(everyNth(list2, 3) == listOf(3,6))
        println("TEST 4 SUCCESS")
    else
        println("TEST 4 FAIL")
    if(everyNth(list2, 6) == listOf(6))
        println("TEST 5 SUCCESS")
    else
        println("TEST 5 FAIL")
    if(everyNth(list2, 7) == listOf<Int>())
        println("TEST 6 SUCCESS")
    else
        println("TEST 6 FAIL")
    var list3 = mutableListOf(true, false)
    if(everyNth(list3, 1) == listOf(true, false))
        println("TEST 7 SUCCESS")
    else
        println("TEST 7 FAIL")
    if(everyNth(list3, 0) == listOf<Boolean>())
        println("TEST 8 SUCCESS")
    else
        println("TEST 8 FAIL")
    if(everyNth(list3, -1) == listOf<Boolean>())
        println("TEST 9 SUCCESS")
    else
        println("TEST 9 FAIL")

}