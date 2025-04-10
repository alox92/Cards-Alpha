.PHONY: all clean compile list debug

SWIFT_FILES = $(shell find . -name "*.swift" -not -path "./CoreKit/*" -not -path "./.build/*" -not -path "./Scripts/*" -not -path "./Tests/*" | grep -v ".bak" | sort)
FRAMEWORK_PATH = $(shell xcrun --show-sdk-path)/System/Library/Frameworks
SDK_PATH = $(shell xcrun --show-sdk-path)
BUILD_DIR = build

all: compile

compile:
	@echo "Compilation de l'application..."
	@mkdir -p $(BUILD_DIR)
	@swiftc -sdk $(SDK_PATH) \
		-F $(FRAMEWORK_PATH) \
		-target arm64-apple-macosx12.0 \
		-I . \
		-parse-as-library \
		-o $(BUILD_DIR)/CardApp \
		$(SWIFT_FILES)
	@echo "Compilation terminée!"

debug:
	@echo "Compilation en mode debug..."
	@mkdir -p $(BUILD_DIR)
	@swiftc -sdk $(SDK_PATH) \
		-F $(FRAMEWORK_PATH) \
		-target arm64-apple-macosx12.0 \
		-I . \
		-parse-as-library \
		-g \
		-o $(BUILD_DIR)/CardApp \
		$(SWIFT_FILES)
	@echo "Compilation debug terminée!"

clean:
	@echo "Nettoyage des fichiers de compilation..."
	@rm -rf $(BUILD_DIR)
	@echo "Nettoyage terminé!"

list:
	@echo "Liste des fichiers Swift à compiler:"
	@echo $(SWIFT_FILES) 