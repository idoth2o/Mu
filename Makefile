# build
OPT			:= -Os
CFLAGS		:= $(OPT) -ffreestanding -nostdinc -nostdlib
CXXFLAGS	:= $(OPT) -ffreestanding -nostdinc -nostdlib -fno-exceptions -fno-rtti

# resolve tool name
ifeq ($(OS),Windows_NT)
# for Windows
ifeq ($(arch),x64)
	CORSS		:= x86_64-pc-linux-gnu-
else
	CORSS		:= i686-pc-linux-gnu-
endif

else
UNAME = ${shell uname}
ifeq ($(UNAME),Linux)
# for Linux
ifeq ($(arch),x64)
	
else
	LDFLAG=-mi386linux
endif

endif
ifeq ($(UNAME),Darwin)
# for MacOSX
CROSS=i386-none-elf-
endif
endif

ifeq ($(arch),x64)
	CFLAGS		+= -D__x86_64__ -m64 -mcmodel=kernel
	CXXFLAGS	+= -D__x86_64__ -m64 -mcmodel=kernel
	LDFLAGS		+= -T linker.ld -z max-page-size=0x1000
else
	CFLAGS		+= -D__x86__ -m32
	CXXFLAGS	+= -D__x86__ -m32
	LDFLAGS		+= -T linker32.ld
endif

#define yourself
#CORSS		:= i686-pc-linux-gnu-

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
