make:
	kotlinc hw6.kt -include-runtime -d hw6.jar

check:	make
	java -jar hw6.jar

clean: 
	rm hw6.jar *~

build:
	tar -czvf hw6.tar.gz hw6.kt Makefile