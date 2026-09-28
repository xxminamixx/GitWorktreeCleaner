APP_NAME := GitWorktreeCleaner
PROJECT := $(APP_NAME).xcodeproj
WORKSPACE := $(APP_NAME).xcworkspace
SCHEME := $(APP_NAME)
CONFIGURATION := Release
BUILD_DIR := build
APP_PATH := $(BUILD_DIR)/Build/Products/$(CONFIGURATION)/$(APP_NAME).app
ZIP_PATH := $(BUILD_DIR)/$(APP_NAME).zip

.PHONY: open zip clean

open:
	open $(WORKSPACE)

# Builds a Release .app and packages it as a .zip that stays a working
# .app after someone downloads and unzips it (uses ditto, not `zip`,
# so the bundle structure survives intact).
zip:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIGURATION) \
		-skipMacroValidation -derivedDataPath $(BUILD_DIR) build
	rm -f $(ZIP_PATH)
	ditto -c -k --keepParent "$(APP_PATH)" "$(ZIP_PATH)"
	@echo "Created $(ZIP_PATH)"

clean:
	rm -rf $(BUILD_DIR)
