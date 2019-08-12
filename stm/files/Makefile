DEBUG_LEVEL=3
SRC_DIR=../src
RUST_ASM_DIR=../tarrget/thumbv7m-none-eabi/debug/deps
BUILD_DIR=build
EXTRAFILES=
OBJCOPY=arm-none-eabi-objcopy
CC=arm-none-eabi-gcc
AR=arm-none-eabi-ar
CCFLAGS=-mcpu=cortex-m3 -mthumb -std=c99 -DUSE_STDPERIPH_DRIVER -g -O$(DEBUG_LEVEL) -I"." -I"inc" 
LDFLAGS=-specs=nosys.specs -nostartfiles -Wl,-Tstm32.ld 
#LDFLAGS=-Wl,-Tstm32.ld -nostdlib -nodefaultlibs -nostartfiles -Xlinker -Map=output.map
#LDFLAGS=-Wl,-Tstm32.ld -nostartfiles -Xlinker -Map=output.map
#CCFLAGS=-mcpu=cortex-m3 -mthumb -std=c99 -DUSE_STDPERIPH_DRIVER -specs=nosys.specs -nostartfiles -g -O$(DEBUG_LEVEL) -Wl,-Tstm32.ld -I"." -I"inc" 
CCFLAGS=-mcpu=cortex-m3 -mthumb -DUSE_STDPERIPH_DRIVER -specs=nosys.specs -nostartfiles -g -O$(DEBUG_LEVEL) -Wl,-Tstm32.ld -I"." -I"inc" 
LDFLAGS=-mcpu=cortex-m3 -mthumb -DUSE_STDPERIPH_DRIVER -specs=nosys.specs -nostartfiles -g -O$(DEBUG_LEVEL) -Wl,-Tstm32.ld -I"." -I"inc" 

SRCS=$(wildcard *.c)
SSRCS=$(wildcard *.s)
DEPS=$(wildcard *.h)
OBJS = \
 $(patsubst %.s,$(BUILD_DIR)/%.o,$(SSRCS)) \
 $(patsubst %.c,$(BUILD_DIR)/%.o,$(SRCS)) \

RUST_OBJS := $(wildcard ../src/*.o)

default: $(OBJS) 
	$(CC) $(LDFLAGS) $(OBJS) $(RUST_OBJS) -o stm.axf
	$(OBJCOPY) -O binary stm.axf stm.bin

rust: CCFLAGS+=-DEXTERNAL_PLC 
rust: $(OBJS) 
	$(CC) $(LDFLAGS) $(OBJS) -L../../lib/ -lpilot -o stm.axf
	$(OBJCOPY) -O binary stm.axf stm.bin

lib: $(OBJS)
	$(AR) -r libbasefw.a $(OBJS) 

$(BUILD_DIR)/%.o: %.c $(DEPS)
	@mkdir -p $(BUILD_DIR)
	$(CC) -c $(CCFLAGS) $*.c -o $(BUILD_DIR)/$*.o

$(BUILD_DIR)/%.o: %.s
	@mkdir -p $(BUILD_DIR)
	$(CC) -c $(CCFLAGS) $*.s -o $(BUILD_DIR)/$*.o

clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(SRC_DIR)/$(BUILD_DIR)
	rm -rf libbasefw.a
