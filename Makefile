# Ranja Ionut
LEX = flex
LFLAGS = -w
CC = gcc
CFLAGS =
LDFLAGS = -lfl

build: tema.o
	$(CC) -o tema $(LDFLAGS) tema.o

tema.o: tema.c
	$(CC) $(CFLAGS) -o tema.o -c tema.c

tema.c: tema.l
	$(LEX) $(LFLAGS) -o tema.c tema.l

clean:
	rm -f tema.c tema.o tema