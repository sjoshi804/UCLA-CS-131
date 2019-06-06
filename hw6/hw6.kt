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
    
    //Check trivial case where N = 1 and check if immutable
    var test1 = mutableListOf("A", "B", "C", "D", "E")
    if (everyNth(test1, 1) == test1.toList())
        println("Test Case 1: Passed")
    else 
        println("Test Case 1: Failed")
    
    //Check for more complex N
    var test2 = mutableListOf(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
    if (everyNth(test2, 2) == listOf(2, 4, 6, 8, 10))
        println("Test Case 2: Passed")
    else 
        println("Test Case 2: Failed")

    //Check edge case: N <= 0
    if (everyNth(test2, 0) == listOf<Int>())
        println("Test Case 3: Passed")
    else 
        println("Test Case 3: Failed")
    
    if (everyNth(test2, -1) == listOf<Int>())
        println("Test Case 4: Passed")
    else
        println("Test Case 4: Failed")

    //Check edge case N > size
    if (everyNth(test2, test2.size + 1) == listOf<Int>())
        println("Test Case 5: Passed")
    else 
        println("Test Case 5: Failed")

    //Check edge case N = size
    if (everyNth(test2, test2.size) == listOf(10))
        println("Test Case 6: Passed")
    else 
        println("Test Case 6: Failed")

    println("All test cases passed")
}