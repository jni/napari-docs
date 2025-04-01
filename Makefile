.PHONY: clean clean-gallery

SPHINXOPTS =

# Gallery path must be given relative to the docs/ folder

ifeq ($(GALLERY_PATH),)
GALLERY_PATH := ../../napari/examples
endif

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(dir $(mkfile_path))
docs_dir := $(current_dir)docs

clean:
	echo clean
	echo $(current_dir)
	rm -rf $(docs_dir)/_build/
	rm -rf $(docs_dir)/api/napari*.rst

clean-gallery:
	rm -rf $(docs_dir)/gallery/*
	rm -rf $(docs_dir)/_tags

prep-docs:
	python $(docs_dir)/_scripts/prep_docs.py

# generate stubs in place of the files from prep_docs
# this will not overwrite existing files
prep-stubs:
	python $(docs_dir)/_scripts/prep_docs.py --stubs

docs-build: prep-docs
	NAPARI_CONFIG="" NAPARI_APPLICATION_IPY_INTERACTIVE=0 sphinx-build -M html docs/ docs/_build  -WT --keep-going -D sphinx_gallery_conf.examples_dirs=$(GALLERY_PATH) $(SPHINXOPTS)

docs-xvfb: prep-docs
	NAPARI_CONFIG="" NAPARI_APPLICATION_IPY_INTERACTIVE=0 xvfb-run --auto-servernum sphinx-build -M html docs/ docs/_build -D sphinx_gallery_conf.examples_dirs=$(GALLERY_PATH) $(SPHINXOPTS)

# full docs (re)build
# cleans everything, starts from scratch
html: clean clean-gallery docs-build

# no gallery, no clean - call 'make clean' manually if needed
# will use stubs for autogenerated content if needed
# no initial build, so run a manual full or slim build first
# will rebuild notebooks and run cells in edited files
# autogenerated paths need to be ignored to prevent reload loops
html-noplot-live: prep-stubs
	NAPARI_APPLICATION_IPY_INTERACTIVE=0 \
	sphinx-autobuild \
		-b html \
		docs/ \
		docs/_build/html \
		-D plot_gallery=0 \
		-D sphinx_gallery_conf.examples_dirs=$(GALLERY_PATH) \
		--ignore $(docs_dir)"/_tags/*" \
		--ignore $(docs_dir)"/api/napari*.rst" \
		--ignore $(docs_dir)"/gallery/*" \
		--ignore $(docs_dir)"/jupyter_execute/*" \
		--open-browser \
		--port=0 \
		$(SPHINXOPTS)

# full build, no gallery
# will not remove existing gallery files
html-noplot: clean prep-docs
	NAPARI_APPLICATION_IPY_INTERACTIVE=0 sphinx-build -M html docs/ docs/_build -D plot_gallery=0 -D sphinx_gallery_conf.examples_dirs=$(GALLERY_PATH) $(SPHINXOPTS)

# just napari/docs
# no generation from prep_docs scripts, no gallery
# does run notebook cells
# will not remove existing gallery files
docs: clean prep-stubs
	NAPARI_APPLICATION_IPY_INTERACTIVE=0 sphinx-build -M html docs/ docs/_build -D plot_gallery=0 -D sphinx_gallery_conf.examples_dirs=$(GALLERY_PATH) $(SPHINXOPTS) 

# live variant of `docs`
docs-live: prep-stubs
	NAPARI_APPLICATION_IPY_INTERACTIVE=0 \
	sphinx-autobuild -M html docs/ docs/_build -D plot_gallery=0 \
	-D sphinx_gallery_conf.examples_dirs=$(GALLERY_PATH) \
	--ignore $(docs_dir)"/_tags/*" \
	--ignore $(docs_dir)"/api/napari*.rst" \
	--ignore $(docs_dir)"/gallery/*" \
	--ignore $(docs_dir)"/jupyter_execute/*" \
	--open-browser \
	--port=0 \
	-j auto $(SPHINXOPTS)

# no notebook execution, no generation from prep_docs, no gallery
# will note remove existing gallery files
slim: clean prep-stubs
	NB_EXECUTION_MODE=off NAPARI_APPLICATION_IPY_INTERACTIVE=0 sphinx-build -M html docs/ docs/_build -D plot_gallery=0 -D sphinx_gallery_conf.examples_dirs=$(GALLERY_PATH) $(SPHINXOPTS)

# slim, but uses -j auto to parallelize the build
slimfast: clean prep-stubs
	NB_EXECUTION_MODE=off NAPARI_APPLICATION_IPY_INTERACTIVE=0 sphinx-build -M html docs/ docs/_build -D plot_gallery=0 -D sphinx_gallery_conf.examples_dirs=$(GALLERY_PATH) -j auto $(SPHINXOPTS)

# slimfast, but uses sphinx-autobuild to rebuild changed files
# this will run an initial build, because it's fast
# will not remove existing gallery files
slimfast-live: clean prep-stubs
	NB_EXECUTION_MODE=off NAPARI_APPLICATION_IPY_INTERACTIVE=0 \
	sphinx-autobuild -M html docs/ docs/_build -D plot_gallery=0 \
	-D sphinx_gallery_conf.examples_dirs=$(GALLERY_PATH) \
	--ignore $(docs_dir)"/_tags/*" \
	--ignore $(docs_dir)"/api/napari*.rst" \
	--ignore $(docs_dir)"/gallery/*" \
	--ignore $(docs_dir)"/jupyter_execute/*" \
	--open-browser \
	--port=0 \
	-j auto $(SPHINXOPTS)

# slim, but with all gallery examples
# does not remove existing gallery files
slimgallery: clean clean-gallery prep-stubs
	NB_EXECUTION_MODE=off NAPARI_APPLICATION_IPY_INTERACTIVE=0 \
	sphinx-build -M html docs/ docs/_build -T --keep-going \
	-D sphinx_gallery_conf.examples_dirs=$(GALLERY_PATH) \
	$(SPHINXOPTS)

# slimgallery, but uses sphinx-autobuild to rebuild any changed examples
# no clean - call 'make clean' and/or `make clean-gallery` manually
# does not remove existing gallery files
# will rebuild whole gallery if it's not present
slimgallery-live: prep-stubs
	NB_EXECUTION_MODE=off NAPARI_APPLICATION_IPY_INTERACTIVE=0 \
	sphinx-autobuild -M html docs/ docs/_build -T --keep-going \
	-D sphinx_gallery_conf.examples_dirs=$(GALLERY_PATH) \
	--ignore $(docs_dir)"/_tags/*" \
	--ignore $(docs_dir)"/api/napari*.rst" \
	--ignore $(docs_dir)"/gallery/*" \
	--ignore $(docs_dir)"/jupyter_execute/*" \
	--ignore $(docs_dir)/sg_execution_times.rst \
	--watch $(docs_dir)/$(GALLERY_PATH) \
	--open-browser \
	--port=0 \
	$(SPHINXOPTS)

# slimgallery-live, but only builds a single gallery example
# pass the name of the example without .py
# e.g. slimgallery-live-vortex for vortex.py
# because it's just 1 example, uses -j auto
# Does not require a full gallery build
# Does clean existing files first, to minimize warnings
# Makefile note: this needs to be first, as the matching rule is more specific
slimgallery-live-%:
	$(MAKE) build-specific-example-live EXAMPLE_NAME=$*

# slimgallery, but only builds a single gallery example
# pass the name of the example without .py
# e.g. slimgallery-vortex for vortex.py
# because it's just 1 example, uses -j auto
# Does not require a full gallery build first
# Does clean the existing gallery to minimize warnings
slimgallery-%:
	$(MAKE) build-specific-example EXAMPLE_NAME=$*

# a target for slimgallery-%
# runs slimgallery with a single example
build-specific-example: clean clean-gallery prep-stubs
	NB_EXECUTION_MODE=off NAPARI_APPLICATION_IPY_INTERACTIVE=0 \
	sphinx-build -M html docs/ docs/_build -T --keep-going \
	-D sphinx_gallery_conf.filename_pattern=$(EXAMPLE_NAME)".py" \
	-D sphinx_gallery_conf.examples_dirs=$(GALLERY_PATH) \
	-j auto \
	$(SPHINXOPTS)

# a target for slimgallery-live-%
# runs slimgallery-live with a single example
build-specific-example-live: clean clean-gallery prep-stubs
	NB_EXECUTION_MODE=off NAPARI_APPLICATION_IPY_INTERACTIVE=0 \
	sphinx-autobuild -M html docs/ docs/_build -T --keep-going \
	-D sphinx_gallery_conf.filename_pattern=$(EXAMPLE_NAME)".py" \
	-D sphinx_gallery_conf.examples_dirs=$(GALLERY_PATH) \
	--ignore $(docs_dir)"/_tags/*" \
	--ignore $(docs_dir)"/api/napari*.rst" \
	--ignore $(docs_dir)"/gallery/*" \
	--ignore $(docs_dir)"/jupyter_execute/*" \
	--ignore $(docs_dir)/sg_execution_times.rst \
	--watch $(docs_dir)/$(GALLERY_PATH)/$(EXAMPLE_NAME)".py" \
	--open-browser \
	--port=0 \
	-j auto \
	$(SPHINXOPTS)

linkcheck-files: prep-docs
	NAPARI_APPLICATION_IPY_INTERACTIVE=0 sphinx-build -b linkcheck -D plot_gallery=0 --color docs/ docs/_build/html ${FILES} -D sphinx_gallery_conf.examples_dirs=$(GALLERY_PATH) $(SPHINXOPTS)

fallback-videos:
	for video in $(basename $(wildcard docs/_static/images/*.webm)); do \
		if [ -a $$video.mp4 ]; then \
			echo "skipping $$video.mp4"; \
			continue; \
		fi; \
		ffmpeg -i $$video.webm -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -c:v libx264 -preset slow -crf 22 -c:a aac -b:a 128k -strict -2 -y $$video.mp4; \
	done

fallback-videos-clean:
	rm -f docs/_static/images/*.mp4
