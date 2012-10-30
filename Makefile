# The kernel tree you do builds in.
# Uncomment if you're building for the emulator
#include ../../.config	# to check toolchain CONFIG_RSDK_rsdk-1.5.4-5281-EB-2.6.30-0.9.30.3-uls-101110

KERNEL_ROOT = ..
VMLINUX?=vml
#include $(KERNEL_ROOT)/.config
CVIMG=cvimg

CONFIG_RTL_KERNEL_LOAD_ADDRESS=0
CONFIG_RTL_LINUX_IMAGE_OFFSET=0

AS              = $(CROSS_COMPILE)as
LD              = $(CROSS_COMPILE)ld
CC              = $(CROSS_COMPILE)gcc
CPP             = $(CC) -E
AR              = $(CROSS_COMPILE)ar
NM              = $(CROSS_COMPILE)nm
STRIP           = $(CROSS_COMPILE)strip
OBJCOPY         = $(CROSS_COMPILE)objcopy
OBJDUMP         = $(CROSS_COMPILE)objdump


EMUOPTS =
LDSCRIPT = ld.script

COPTIONS = -DROM_MEMORY -DCOMPRESSED_KERNEL -D__KERNEL__

#SOURCES = misc.c hfload.c start.S cache.c #bzip2
#SOURCES = string.c ctype.c misc.c hfload.c start.S read_memory.c cache.c #gzip
SOURCES = string.c ctype.c misc.c hfload.c start.S read_memory.c cache.c LzmaDecode.c #lzma

LOADER_FILES = hfload.o read_memory.o


#SUPPORT_FILES = misc.o cache.o # bzip2
#SUPPORT_FILES = vsprintf.o prom_printf.o string.o ctype.o misc.o cache.o #gzip
#SUPPORT_FILES = string.o ctype.o misc.o cache.o LzmaDecode.o #quiet
SUPPORT_FILES = vsprintf.o prom_printf.o string.o ctype.o misc.o cache.o LzmaDecode.o  #lzma
    
CFLAGS =-Os -g -fno-pic -mno-abicalls $(EMUOPTS) -march=rlx4181

#CFLAGS  += $(WARNINGS)  -D__DO_QUIET__ #quiet


CFLAGS += -DEMBEDDED -I$(KERNEL_ROOT)/include/linux -I$(KERNEL_ROOT)/include -I$(KERNEL_ROOT)/lib $(COPTIONS) -G 0
CFLAGS += -I$(KERNEL_ROOT)/arch/rlx/bsp -I$(KERNEL_ROOT)/arch/rlx/include -I$(KERNEL_ROOT)/arch/rlx/include/asm/mach-generic 
#ASFLAGS = -g $(EMUOPTS) -DEMBEDDED -I$(KERNEL_ROOT)/include -I$(KERNEL_ROOT)/arch/rlx/include
#CFLAGS +=  -I$(KERNEL_ROOT)/arch/mips/include -I$(KERNEL_ROOT)/arch/mips/include/asm/mach-generic 
#ASFLAGS = -g $(EMUOPTS) -DEMBEDDED -I$(KERNEL_ROOT)/include -I$(KERNEL_ROOT)/arch/mips/include
ASFLAGS = -g -fno-pic -mno-abicalls $(EMUOPTS) -DEMBEDDED -I$(KERNEL_ROOT)/include -I$(KERNEL_ROOT)/arch/rlx/include

LDFLAGS=-static -nostdlib

#CFLAGS += -DBZ2_COMPRESS #bzip2
#ASFLAGS += -DBZ2_COMPRESS #bzip2
#CFLAGS += #gzip
#ASFLAGS += #gzip
CFLAGS += -DLZMA_COMPRESS #lzma
ASFLAGS += -DLZMA_COMPRESS #lzma


START_FILE = start.o


CV_OPTION=linux-ro
#CV_OPTION=linux

SEDFLAGS       = s/LOAD_ADDR/$(CONFIG_RTL_KERNEL_LOAD_ADDRESS)/;


O_TARGET := rtk
obj-y		:= vmlinux_img.o $(START_FILE) $(LOADER_FILES) $(SUPPORT_FILES)

all: linux.bin

%.o:%.S
	${CC} ${CFLAGS} -c -o $@ $<
%.o:%.c
	${CC} ${CFLAGS} -c -o $@ $<

linux.bin: $(VMLINUX) $(START_FILE) $(LOADER_FILES) $(SUPPORT_FILES)
	cp $(VMLINUX) vmlinux-stripped
	$(STRIP) vmlinux-stripped $(STRIP-OPTIONS-y)
	$(OBJCOPY) -Obinary vmlinux-stripped vmlinux_img
	#lzma -z < vmlinux_img > vmlinux_img.squish || rm -f vmlinux_img.squish
	lzma e vmlinux_img vmlinux_img.squish
	#bzip2 -9 < vmlinux_img >  vmlinux_img.squish || rm -f vmlinux_img.squish
	#gzip -9 < vmlinux_img > vmlinux_img.squish || rm -f vmlinux_img.squish
	$(CVIMG) vmlinuxhdr vmlinux_img.squish vmlinux_img.squish.hdr $(KERNEL_ROOT)/vmlinux
	$(CC) ${CFLAGS} -D__KERNEL__ -c vmlinux_img.c -o vmlinux_img.o
	$(OBJCOPY) --add-section .vmlinux=vmlinux_img.squish.hdr vmlinux_img.o
	sed "$(SEDFLAGS)" < ld.script.in > $(LDSCRIPT)
	$(LD) $(LDFLAGS) -G 0 -T $(LDSCRIPT) -o memload-partial $(START_FILE) $(LOADER_FILES) $(SUPPORT_FILES) vmlinux_img.o
	$(NM) memload-partial | grep -v '\(compiled\)\|\(\.o$$\)\|\( [aU] \)\|\(\.\.ng$$\)\|\(LASH[RL]DI\)' | sort > system.map
	cp memload-partial memload-full
	$(OBJCOPY) -Obinary memload-full nfjrom
	$(CVIMG) $(CV_OPTION) nfjrom linux.bin $(CONFIG_RTL_KERNEL_LOAD_ADDRESS) $(CONFIG_RTL_LINUX_IMAGE_OFFSET) $(CV_SIGNATURE)

clean:
	rm -f *.o memload system.map nfjrom memload-partial memload-full vmlinux_img.squish vmlinux_img.squish.hdr target target.img strip1 linux.bin vmlinux-stripped  $(LDSCRIPT) vmlinux_img vmlinux_img.gzip.uboot.jffs2


depend:
	rm -f .depend
	$(CC) $(CFLAGS) -MM $(SOURCES) >.depend


