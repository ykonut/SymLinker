APP_NAME := SymLinker
BUNDLE_ID := com.quick-symlink.app
SOURCE_DIR := Sources

BUILD_DIR := .build
RELEASE_DIR := $(BUILD_DIR)/release

# Build with SwiftPM
.PHONY: build
build:
	swift build -c release

# Run directly via SwiftPM
.PHONY: run
run:
	swift run

# Build a standalone .app bundle
.PHONY: app
app: build
	rm -rf "$(APP_NAME).app"
	mkdir -p "$(APP_NAME).app/Contents/MacOS"
	mkdir -p "$(APP_NAME).app/Contents/Resources"
	cp -f "AppIcon.icns" "$(APP_NAME).app/Contents/Resources/AppIcon.icns"
	cp -f "AppIcon.icns" "$(APP_NAME).app/Contents/Resources/$(APP_NAME).icns"
	cp "$(RELEASE_DIR)/$(APP_NAME)" "$(APP_NAME).app/Contents/MacOS/$(APP_NAME)"
	sed -e "s/APP_NAME/$(APP_NAME)/g" \
		-e "s/BUNDLE_ID/$(BUNDLE_ID)/g" \
		"InfoTemplate.plist" > "$(APP_NAME).app/Contents/Info.plist"
	echo "APPL????" > "$(APP_NAME).app/Contents/PkgInfo"
	@echo "\n✅ App bundle created: $(APP_NAME).app"
	@echo "   Drag it to /Applications to install."

# Open in Xcode
.PHONY: xcode
xcode:
	open Package.swift

# Clean
.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
	rm -rf "$(APP_NAME).app"

.PHONY: install
install: app
	cp -R "$(APP_NAME).app" /Applications/
	@echo "\n✅ Installed to /Applications/$(APP_NAME).app"
