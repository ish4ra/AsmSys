NASM := nasm
LD := ld

SRC := src/main.asm
OBJ := build/main.o
BIN := asmsys

.PHONY: all clean run

all: $(BIN)

build:
	mkdir -p build

$(OBJ): $(SRC) | build
	$(NASM) -f elf64 $(SRC) -o $(OBJ)

$(BIN): $(OBJ)
	$(LD) $(OBJ) -o $(BIN)

run: $(BIN)
	./$(BIN)

clean:
	rm -rf build $(BIN)
