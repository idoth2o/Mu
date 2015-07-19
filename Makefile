# build
OPT			:= -Os
CFLAGS		:= $(OPT) -std=gnu11 -ffreestanding -nostdinc -nostdlib
CXXFLAGS	:= $(OPT) -std=gnu++1y -ffreestanding -nostdinc -nostdlib -fno-exceptions -fno-rtti

ifeq ($(arch),x64)
	CORSS		:= x86_64-pc-linux-gnu-
	CFLAGS		+= -D__x86_64__ -m64 -mcmodel=kernel
	CXXFLAGS	+= -D__x86_64__ -m64 -mcmodel=kernel
	LDFLAGS		:= -T linker.ld -z max-page-size=0x1000
else
	CORSS		:= i686-pc-linux-gnu-
	CFLAGS		+= -D__x86__ 
	CXXFLAGS	+= -D__x86__
	LDFLAGS		:= -T linker32.ld
endif

TARGET=kernel.elf
ISO=boot.iso
OBJ=obj
PARTS = $(OBJ)/boot.o $(OBJ)/kernel.o
CFLAGS		+= -Wall -Wextra
CXXFLAGS		+= -Wall -Wextra
INCLUDES	:= -I./include -I./include/lib

CC			:=	$(CORSS)gcc
CXX			:=	$(CORSS)g++
AR			:=	$(CORSS)ar
LD			:=	$(CORSS)ld

$(TARGET): $(PARTS)
	${LD} ${LDFLAGS} -o iso/boot/${TARGET} $(PARTS) 
	
# General Rules
$(OBJ)/%.o: */%.S
	$(CC) $(CFLAGS) $(INCLUDES) -c -o $@ $<

$(OBJ)/%.o: */%.c
	$(CC) $(CFLAGS) $(INCLUDES) -c -o $@ $<

${ISO}:${TARGET}
	#mv $<  iso/boot
	grub-mkrescue --output=${ISO} iso

iso: ${ISO}

clean:
	-rm $(OBJ)/*.o
	-rm *.iso
