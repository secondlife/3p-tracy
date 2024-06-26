CFLAGS +=
CXXFLAGS := $(CFLAGS) -std=c++17
DEFINES += -DIMGUI_ENABLE_FREETYPE
INCLUDES := $(shell pkg-config --cflags glfw3 freetype2 capstone) -I../../../imgui
LIBS := $(shell pkg-config --libs glfw3 freetype2 capstone) -lpthread -ldl

DISPLAY_SERVER := X11

ifdef TRACY_USE_WAYLAND
	DISPLAY_SERVER := WAYLAND
	LIBS += $(shell pkg-config --libs wayland-client)
endif

CXXFLAGS += -D"DISPLAY_SERVER_$(DISPLAY_SERVER)"

PROJECT := Tracy
IMAGE := $(PROJECT)-$(BUILD)

FILTER := ../../../nfd/nfd_win.cpp
include ../../../common/src-from-vcxproj.mk

ifdef TRACY_NO_FILESELECTOR
	CXXFLAGS += -DTRACY_NO_FILESELECTOR
else
	UNAME := $(shell uname -s)
	ifeq ($(UNAME),Darwin)
		SRC3 += ../../../nfd/nfd_cocoa.m
		LIBS +=  -framework CoreFoundation -framework AppKit
	else
		SRC += ../../../nfd/nfd_portal.cpp
		INCLUDES += $(shell pkg-config --cflags dbus-1)
		LIBS += $(shell pkg-config --libs dbus-1)
	endif
endif

include ../../../common/unix.mk
