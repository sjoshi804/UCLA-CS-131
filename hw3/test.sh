small=""
for i in {1..100}
do
 number=$RANDOM
 let number%=128
 small="$small $number"
done
#echo ${small}

medium=""
for i in {1..500}
do
 number=$RANDOM
 let number%=128
 medium="$medium $number"
done
#echo ${medium}

large=""
for i in {1..1000}
do
 number=$RANDOM
 let number%=128
 large="$large $number"
done
#echo ${large}

## Arrays
declare -a models=("Null" "BetterSafe" "Synchronized" "GetNSet" "Synchronized" "Unsynchronized")
declare -a sizes=("$small" "$medium" "$large")

#Loop through all models
for i in "${models[@]}"
do
    for j in 8 16 32
    do
	echo "java UnsafeMemory $i threads=$j swaps=100000 maxval=127 array=medium"
	eval "java UnsafeMemory $i $j 100000 127 $medium"
	echo -e "\n"
    done
    for j in 100000 500000 1000000
    do
	echo "java UnsafeMemory $i threads=8 swaps=$j maxval=127 array=medium"
	eval "java UnsafeMemory $i 8 $j 127 $medium"
	echo -e "\n"
    done
    for j in "${sizes[@]}"
    do 
	echo "java UnsafeMemory $i threads=8 swaps=100000 maxval=127 trying different sizes"
	eval "java UnsafeMemory $i 8 100000 127 $j"
	echo -e "\n"
    done
done
