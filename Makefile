TTCTL := tt
ifeq (,$(shell which tt 2>/dev/null))
$(error tt is not found)
endif

.PHONY: rpm
rpm:
	OS=el DIST=7 packpack/packpack

.rocks: metrics-scm-1.rockspec metrics/*.lua metrics/*/*.lua
	$(TTCTL) rocks make
	$(TTCTL) rocks install luatest 1.0.1
	$(TTCTL) rocks install luacov 0.13.0
	$(TTCTL) rocks install luacheck 0.26.0
	if [ -n '$(CARTRIDGE_VERSION)' ]; then \
		$(TTCTL) rocks install cartridge $(CARTRIDGE_VERSION); \
	fi

.PHONY: lint
lint: .rocks
	.rocks/bin/luacheck .

.PHONY: test
test: .rocks
	.rocks/bin/luatest -v -c

.PHONY: test_with_coverage_report
test_with_coverage_report: .rocks
	rm -f tmp/luacov.*.out*
	.rocks/bin/luatest --coverage -v -c --shuffle group --repeat 3
	.rocks/bin/luacov .
	echo
	grep -A999 '^Summary' tmp/luacov.report.out

.PHONY: test_promtool
test_promtool: .rocks
	tarantool test/promtool.lua
	cat prometheus-input | promtool check metrics
	rm prometheus-input

update-pot:
	sphinx-build doc/monitoring doc/locale/en/ -c doc/ -d doc/.doctrees -b gettext

update-po:
	sphinx-intl update -p doc/locale/en/ -d doc/locale/ -l "ru"

bench: .rocks
	$(TTCTL) rocks install --server https://moonlibs.org luabench 0.3.0
	$(TTCTL) rocks install --server https://luarocks.org argparse 0.7.1
	.rocks/bin/luabench -d 3s

.PHONY: clean
clean:
	rm -rf .rocks
