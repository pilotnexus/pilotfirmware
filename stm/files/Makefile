DEBUG_LEVEL=0
SRC_DIR=../src
RUST_ASM_DIR=../tarrget/thumbv7m-none-eabi/debug/deps
BUILD_DIR=build
EXTRAFILES=
OBJCOPY=arm-none-eabi-objcopy
CC=arm-none-eabi-gcc
CCFLAGS=-mcpu=cortex-m3 -mthumb -std=c99 -DUSE_STDPERIPH_DRIVER -nostartfiles -g -O$(DEBUG_LEVEL) -Wl,-Tstm32.ld -I"." -I"inc" 
SRCS=$(filter-out $(EXCLUDE_SRCS), $(wildcard *.c))
SSRCS=$(wildcard *.s)
DEPS=$(wildcard *.h)
RUST_SRCS := $(wildcard $(SRC_DIR)/*.rs)
OBJS = \
 $(patsubst %.s,$(BUILD_DIR)/%.o,$(SSRCS)) \
 $(patsubst %.c,$(BUILD_DIR)/%.o,$(SRCS)) \
 $(patsubst ../src/%.rs,../src/$(BUILD_DIR)/%.o,$(RUST_SRCS)) \

RUST_OBJS := $(wildcard ../src/*.o)

default: $(OBJS) 
	$(CC) -mcpu=cortex-m3 -mthumb -std=c99 -DUSE_STDPERIPH_DRIVER -nostartfiles -g -O3 -Tstm32.ld -I"." -I"inc" $(OBJS) $(RUST_OBJS) -o stm.axf
	$(OBJCOPY) -O binary stm.axf stm.bin

$(BUILD_DIR)/%.o: %.c $(DEPS)
	@mkdir -p $(BUILD_DIR)
	$(CC) -c $(CCFLAGS) $*.c -o $(BUILD_DIR)/$*.o

$(BUILD_DIR)/%.o: %.s
	@mkdir -p $(BUILD_DIR)
	$(CC) -c $(CCFLAGS) $*.s -o $(BUILD_DIR)/$*.o

$(SRC_DIR)/$(BUILD_DIR)/%.o: $(SRC_DIR)/%.rs
	@mkdir -p ../src/$(BUILD_DIR)
	rustc $(SRC_DIR)/$*.rs --emit=obj --crate-type=lib --target=thumbv7m-none-eabi --out-dir=$(SRC_DIR)/$(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(SRC_DIR)/$(BUILD_DIR)

help:
	echo "$(OBJS)"
