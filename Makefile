EPUB_FILE := thisnewocean.epub

default: $(EPUB_FILE)

# for simplicity, depend on all files known to Git
GIT_FILES := $(shell git ls-tree -r --name-only HEAD)

# extract OEBPS dependencies from content.opf
OEBPS_FILES := $(addprefix OEBPS/, $(shell grep '<item href' OEBPS/content.opf | cut -d '"' -f 2))

$(EPUB_FILE): $(GIT_FILES) $(OEBPS_FILES)
	rm -f $@
	zip -X $@ mimetype
	zip -rg $@ META-INF OEBPS -x \*~ \*.gitignore

OEBPS/about.htm: about.htm
	$(eval REVISION := $(shell git rev-parse HEAD))
	$(eval TMP := $(shell mktemp -t $<))
	sed "s/REVISION/$(REVISION)/g" $< > $(TMP)
	./sanitize.py $(TMP) $@
	rm $(TMP)

OEBPS/%.htm: %.htm
	./sanitize.py $< $@

OEBPS/%.html: %.html
	./sanitize.py $< $@

OEBPS/%.gif: %.gif
	cp $< $@

OEBPS/%.jpg: %.jpg
	./resize.sh $< $@ 1000 1000

OEBPS/%.png: %.png
	./resize.sh $< $@ 1000 1000

OEBPS/stylesheet.css: stylesheet.css
	cp $< $@

.PHONY: clean
clean:
	git clean -fX

.PHONY: validate
validate: $(EPUB_FILE)
	java -jar epubcheck/epubcheck-3.0.jar $<
