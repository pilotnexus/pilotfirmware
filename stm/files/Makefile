ifeq ($(OS),Windows_NT)
  CP := copy
  RM := del /f /q
  S=\\

  rmdir = IF EXIST $1 rmdir $1 /s /q
  mk = IF NOT EXIST $1 md $1
else
  CP := cp
  RM := rm -f
  S=/
  rmdir = rm -rf $1
  mk = mkdir -p $1
endif

DEBUG_LEVEL=0
SRC_DIR=..${S}src
RUST_ASM_DIR=..${S}tarrget${S}thumbv7m-none-eabi${S}debug${S}deps
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
LDFLAGS=-mcpu=cortex-m3 -mthumb -DUSE_STDPERIPH_DRIVER -specs=nosys.specs -nostartfiles -g -O$(DEBUG_LEVEL) -Wl,-Tstm32.ld,--gc-sections -I"." -I"inc" -zmuldefs -ffunction-sections -fdata-sections

SRCS=$(wildcard *.c)
SSRCS=$(wildcard *.s)
DEPS=$(wildcard *.h)
OBJS = \
 $(patsubst %.s,$(BUILD_DIR)${S}%.o,$(SSRCS)) \
 $(patsubst %.c,$(BUILD_DIR)${S}%.o,$(SRCS)) \

RUST_OBJS := $(wildcard ..${S}src${S}*.o)

default: $(OBJS) 
	$(CC) $(LDFLAGS) $(OBJS) $(RUST_OBJS) -o stm.axf
	$(OBJCOPY) -O binary stm.axf stm.bin

rust: CCFLAGS+=-DEXTERNAL_PLC 
rust: $(OBJS) 
	$(CC) $(LDFLAGS) $(OBJS) -L..${S}..${S}lib${S} -lpilot -Wl,--print-memory-usage -o stm.axf
	$(OBJCOPY) -O binary stm.axf stm.bin

lib: $(OBJS)
	$(AR) -r libbasefw.a $(OBJS) 

$(BUILD_DIR)${S}%.o: %.c $(DEPS)
	@$(call mk, $(BUILD_DIR))
	$(CC) -c $(CCFLAGS) $*.c -o $(BUILD_DIR)${S}$*.o

$(BUILD_DIR)${S}%.o: %.s
	@$(call mk, $(BUILD_DIR))
	$(CC) -c $(CCFLAGS) $*.s -o $(BUILD_DIR)${S}$*.o

clean:
	$(call rmdir, $(BUILD_DIR))
	${RM} libbasefw.a
