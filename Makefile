################################################################################
# Makefile for providing gowin tools introduced environment via docker
#
# usage:
#   $ make docker  # get console on gowin-tools container
#   $ make clean   # cleanup generated files
################################################################################

.PHONY: default docker clean

# dump variables
#@$(foreach v,$(.VARIABLES),$(info $v=$($v)))

SCRIPT_DIR     := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
PROJ_ROOT      := .

IMAGE_NAME     := gowin-tools
IMAGE_TAG      := 1.9.8
INTERNAL_USER  := guser
BUILD_REQUIRED := \
	$(shell if ! (type docker > /dev/null 2>&1); then echo 0; \
	elif ! (docker inspect $(IMAGE_NAME):$(IMAGE_TAG) > /dev/null 2>&1); then echo 1; \
	elif [ $$(date -r Dockerfile +%s) -gt $$(date -d $$(docker inspect -f '{{.Created}}' $(IMAGE_NAME):$(IMAGE_TAG) ) +%s) ]; then echo 1 ; \
	else echo 0 ; \
	fi )

default: docker

# get gowin tools introduced shell on a container
# VendorID / ProductID :
#   0403:6010 = FT2232C/D/H Dual UART/FIFO IC (Tang-Nano rev. 2704 (first-gen) and Tang-Nano 9K)
docker:
	@if !(type docker > /dev/null 2>&1); then echo "command 'docker' not found." ; exit 1 ; fi
	@if [ $(BUILD_REQUIRED) -eq 1 ]; then time docker build --no-cache -t $(IMAGE_NAME):$(IMAGE_TAG) . ; fi
	docker run --rm --net host -it --init -w $(SCRIPT_DIR) \
		-v $(SCRIPT_DIR)/$(PROJ_ROOT)/:$(SCRIPT_DIR)/$(PROJ_ROOT)/ \
		-v /opt:/opt -e USER_ID=`id -u` -e GROUP_ID=`id -g` \
		$(shell if [ -n "`lsusb -d 0403:6010`" ] ; then echo "--device `lsusb -d 0403:6010`" | perl -pe 's!Bus\s(\d{3})\sDevice\s(\d{3}).*!/dev/bus/usb/\1/\2!' ; fi) \
		-e DISPLAY=$(DISPLAY) -v /tmp/.X11-unix:/tmp/.X11-unix -v $(HOME)/.Xauthority:/home/$(INTERNAL_USER)/.Xauthority \
		$(IMAGE_NAME):$(IMAGE_TAG) bash && true

# remove docker image
clean:
	@if !(type docker > /dev/null 2>&1); then echo "command 'docker' not found." ; exit 1 ; fi
	@if !(docker inspect $(IMAGE_NAME):$(IMAGE_TAG) > /dev/null 2>&1); then echo "no '$(IMAGE_NAME):$(IMAGE_TAG)' image, do nothing."; exit 1 ; fi
	docker image rm $(IMAGE_NAME):$(IMAGE_TAG)
