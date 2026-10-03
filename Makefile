VERSION ?= 0.0.0-dev
.PHONY: lint test deb clean
lint:
	shellcheck -x -S style -e SC2312 src/bitcalc scripts/*.sh packaging/install.sh packaging/uninstall.sh completions/bitcalc.bash tests/*.sh || \
	shellcheck -x -S warning src/bitcalc scripts/*.sh packaging/install.sh packaging/uninstall.sh completions/bitcalc.bash tests/*.sh
test:
	tests/run.sh
	tests/fuzz.sh
deb:
	scripts/build-deb.sh $(VERSION)
clean:
	rm -rf build dist
