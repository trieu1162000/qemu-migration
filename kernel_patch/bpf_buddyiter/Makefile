obj-m := buddyiter.o

KDIR ?= /lib/modules/$(shell uname -r)/build
PWD  := $(shell pwd)

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

install: all
	sudo insmod buddyiter.ko

uninstall:
	sudo rmmod buddyiter || true

test: install
	@echo "=== Check dmesg for registration ==="
	sudo dmesg | tail -5
	@echo ""
	@echo "=== Check exported symbols ==="
	sudo cat /proc/kallsyms | grep bpf_iter_buddyallocator
