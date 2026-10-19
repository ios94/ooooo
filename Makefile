NAME := AshteMobile
PLATFORM := iphoneos
SCHEMES := Feather
TMP := $(TMPDIR)/$(NAME)
STAGE := $(TMP)/stage
APP := $(TMP)/Build/Products/Release-$(PLATFORM)
CERT_JSON_URL := https://ashtemobile.site/pack.json

.PHONY: all deps clean $(SCHEMES)

all: $(SCHEMES)

clean:
	rm -rf $(TMP)
	rm -rf packages
	rm -rf Payload

deps:
	rm -rf deps || true
	mkdir -p deps

	curl -kfSL "$(CERT_JSON_URL)" -o cert.json

	jq -r '.cert' cert.json > deps/server.crt
	jq -r '.key1, .key2' cert.json > deps/server.pem
	jq -r '.info.domains.commonName' cert.json > deps/commonName.txt

$(SCHEMES): deps
	xcodebuild \
	    -project Feather.xcodeproj \
	    -scheme "$@" \
	    -configuration Release \
	    -arch arm64 \
	    -sdk $(PLATFORM) \
	    -derivedDataPath $(TMP) \
	    -skipPackagePluginValidation \
	    CODE_SIGNING_ALLOWED=NO \
	    ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO

	rm -rf Payload
	rm -rf $(STAGE)/
	mkdir -p $(STAGE)/Payload

	mv "$(APP)/$(NAME).app" "$(STAGE)/Payload/$(NAME).app"

	chmod -R 0755 "$(STAGE)/Payload/$(NAME).app"
	codesign --force --sign - --timestamp=none "$(STAGE)/Payload/$(NAME).app"

	cp deps/* "$(STAGE)/Payload/$(NAME).app/" || true

	rm -rf "$(STAGE)/Payload/$(NAME).app/_CodeSignature"
	ln -sf "$(STAGE)/Payload" Payload
	
	mkdir -p packages
	zip -r9 "packages/$(NAME).ipa" Payload
