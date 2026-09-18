ARCHS = arm64
TARGET = iphone:clang:latest:15.0
THEOS_PACKAGE_SCHEME = roothide

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MewRemoteOffline
MewRemoteOffline_FILES = Tweak.xm
MewRemoteOffline_FRAMEWORKS = Foundation
MewRemoteOffline_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
