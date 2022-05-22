#!make

name="00000000-init"

new:
	@hugo new "content/$(name)/index.md" --verbose

serve:
	@hugo server -D -E -F --bind "0.0.0.0" --port 1313 \
		--baseURL "http://0.0.0.0:1313" --noHTTPCache \
		--gc --disableFastRender --verbose --watch --printMemoryUsage \
		--templateMetricsHints --templateMetrics

list.all:
	@hugo list all --verbose

list.draft:
	@hugo list drafts --verbose

update.theme:
	@git submodule update --init --recursive

