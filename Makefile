SNAP_DIRS := $(shell find target -type d -exec test -e {}/snap/snapcraft.yaml \; -print)

all: build

build: $(SNAP_DIRS)

prepare:
	(cd content-snap-generator && mvn package)
	java -jar content-snap-generator/target/content-snap-generator-1.0-shaded.jar \
		-m devpack-for-spring-manifest/supported.yaml \
		-d target -t content-snaps

$(SNAP_DIRS): prepare
	@echo "Building snap in $@"
	cd $@ && snapcraft && snap install *.snap --classic --dangerous

clean:
	for dir in $(SNAP_DIRS); do \
		(cd $$dir && snapcraft clean); \
	done

.PHONY: all install clean $(SNAP_DIRS) *.snap
