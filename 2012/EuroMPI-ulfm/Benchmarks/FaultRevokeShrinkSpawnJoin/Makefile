all: frssj

#OPTS = -Wall -g
OPTS = -O3

frssj: frssj.o
	mpicc -o frssj frssj.o

frssj.o: frssj.c
	mpicc -c $(OPTS) frssj.c -o frssj.o

clean:
	rm -f frssj frssj.o
