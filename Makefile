#!make

name="00000000-init"

new:
	@hugo new "content/$(name)/index.md" --verbose

serve:
	@hugo server -D -E -F --bind "127.0.0.1" --port 1313 \
		--baseURL "http://127.0.0.1:1313" --noHTTPCache \
		--gc --disableFastRender --verbose --watch --print-mem \
		--templateMetricsHints --templateMetrics

lista:
	@hugo list all --verbose

listd:
	@hugo list drafts --verbose
