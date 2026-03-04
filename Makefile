APP_NAME = SystemPulse
BUILD_DIR = build
APP_PATH = $(BUILD_DIR)/$(APP_NAME).app
DMG_PATH = $(BUILD_DIR)/$(APP_NAME).dmg

.PHONY: build test app dmg clean run

build:
	swift build -c release

test:
	swift test

app: build
	chmod +x Scripts/build-app.sh
	./Scripts/build-app.sh

dmg: app
	chmod +x Scripts/create-dmg.sh
	./Scripts/create-dmg.sh "$(APP_PATH)" "$(DMG_PATH)"

run:
	swift run

clean:
	rm -rf $(BUILD_DIR) .build
