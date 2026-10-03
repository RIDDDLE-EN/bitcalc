#!/usr/bin/env bash
set -u
BIN=${1:-"$(dirname "$0")/../src/bitcalc"}
pass=0 fail=0

ok() { # description expected actual
	if [[ $2 == "$3" ]]; then
		pass=$((pass + 1))
	else
		fail=$((fail + 1))
		printf 'FAIL: %s\n  expected: %s\n  actual:   %s\n' "$1" "$2" "$3"
	fi
}
q() { "$BIN" -q "$@" 2>&1; }

# --- conversions -----------------------------------------------------------
ok "dec->bin" "0b00001010" "$(q -t bin 10)"
ok "hex input"  "255" "$(q 0xFF)"
ok "bin input"  "10" "$(q 0b1010)"
ok "oct input"  "8" "$(q 0o10)"
ok "-f hex no prefix" "0b10000101" "$(q -f hex -t bin 85)"
ok "auto width 300" "0x012C" "$(q -t hex 300)"
ok "to oct" "0o377" "$(q -t oct 255)"
ok "bcd" "1001 0100" "$(q -t bcd 94)"
ok "gray" "0b00001011" "$(q -t gray 13)"
ok "negative as bin" "0b11110110" "$(q -t bin -10)"
ok "negative dec" "-10" "$(q -10)"
ok "unsigned flag" "246" "$(q -u -10)"
ok "frac dec->bin" "00001101.101" "$(q 13.625)"
ok "frac bin->dec" "13.625" "$(q -f bin 1101.101)"
ok "64-bit hex" "0xFFFFFFFFFFFFFFFF" "$(q -w 64 -t hex 0xFFFFFFFFFFFFFFFF)"
ok "64-bit unsigned dec" "18446744073709551615" "$(q -w 64 0xFFFFFFFFFFFFFFFF)"

# --- arithmetic ------------------------------------------------------------
ok "add" "12" "$(q 10 ADD 2)"
ok "add symbol" "12" "$(q 10 + 2)"
ok "add wraps" "44" "$(q 200 ADD 100)"
ok "sub" "7" "$(q 10 SUB 3)"
ok "sub negative result" "-2" "$(q 3 SUB 5)" 
ok "mul" "143" "$(q 13 MUL 11)"
ok "mul wide" "143" "$(q -w 16 13 MUL 11)"
ok "div" "14" "$(q 100 DIV 7)"
ok "mod" "2" "$(q 100 MOD 7)"
ok "div signed" "-14" "$(q -- -100 DIV 7)"
ok "div by zero" "bitcalc: error: division by zero" "$(q 1 DIV 0)"

# --- logic -----------------------------------------------------------------
ok "and neg" "10" "$(q 10 AND -2)"
ok "or" "14" "$(q 10 OR 12)"
ok "xor" "6" "$(q 10 XOR 12)"
ok "nand" "247" "$(q 12 NAND 10)"
ok "nor" "241" "$(q 12 NOR 10)"
ok "xnor" "249" "$(q 12 XNOR 10)"
ok "not" "84" "$(q NOT 0b10101011)"
ok "not postfix" "84" "$(q 0b10101011 NOT)"
ok "1comp" "245" "$(q 1COMP 10)"

# --- shifts and rotates (negative count flips direction) -------------------
ok "lshift" "40" "$(q 10 LSHIFT 2)"
ok "rshift" "2" "$(q 10 RSHIFT 2)"
ok "lshift -n == rshift n" "$(q 10 RSHIFT 2)" "$(q 10 LSHIFT -2)"
ok "rshift -n == lshift n" "$(q 10 LSHIFT 2)" "$(q 10 RSHIFT -2)"
ok "asr keeps sign" "0b11111111" "$(q -t bin -2 ASR 1)"
ok "rol" "0b00000011" "$(q -t bin 0b10000001 ROL 1)"
ok "ror" "0b11000000" "$(q -t bin 0b10000001 ROR 1)"
ok "rol -n == ror n" "$(q 0b10110001 ROR 3)" "$(q 0b10110001 ROL -3)"
ok "ror -n == rol n" "$(q 0b10110001 ROL 3)" "$(q 0b10110001 ROR -3)"
ok "rotate wraps count" "$(q 0b10110001 ROL 3)" "$(q 0b10110001 ROL 11)"
ok "shift too big" "bitcalc: error: shift count 8 is not smaller than the register width (8); use --width" "$(q 1 LSHIFT 8)"
ok "64-bit lshift" "9223372036854775808" "$(q -w 64 1 LSHIFT 63)"
ok "64-bit rshift logical" "1" "$(q -w 64 0x8000000000000000 RSHIFT 63)"

# --- unary -----------------------------------------------------------------
ok "2comp negative" "0b11110110" "$(q -t bin 2COMP -10)"
ok "neg" "-5" "$(q NEG 5)"
ok "popcnt" "5" "$(q 0b10110110 POPCNT)"
ok "clz" "4" "$(q 0b00001010 CLZ)"
ok "ctz" "1" "$(q 0b00001010 CTZ)"
ok "rev" "0b01010000" "$(q -t bin 0b00001010 REV)"
ok "parity" "1" "$(q 0b00000111 PARITY)"
ok "bswap 16" "0xCDAB" "$(q -w 16 -t hex 0xABCD BSWAP)"
ok "bswap 32" "0x78563412" "$(q -w 32 -t hex 0x12345678 BSWAP)"
ok "bswap bad width" "bitcalc: error: BSWAP needs a width that is a multiple of 8, at least 16 (use --width 16/32/64)" "$(q -w 8 BSWAP 5)"

# --- input validation ------------------------------------------------------
ok "bad binary" "bitcalc: error: '0b102' is not binary (digits 0-1 only)" "$(q 0b102 ADD 1)"
ok "too wide explicit" "bitcalc: error: '300' does not fit in 8 bits (use --width)" "$(q -w 8 300 ADD 1)"
ok "unknown op" "bitcalc: error: unknown operator 'FOO' (see --help)" "$(q 1 FOO 2)"
ok "bad width" "bitcalc: error: width must be an integer from 2 to 64 (got '99')" "$(q -w 99 1)"
ok "huge decimal" "bitcalc: error: '99999999999999999999' is too large for decimal input (max 9223372036854775807); use 0x... for bigger values" "$(q 99999999999999999999)"

# --- stdin / pipelines -----------------------------------------------------
ok "stdin expression" "12" "$(echo "10 ADD 2" | "$BIN" -q)"
ok "pipeline" "0x28" "$("$BIN" -q 10 LSHIFT 2 | "$BIN" -q -t hex)"
ok "non-tty is quiet by default" "12" "$("$BIN" 10 ADD 2)"

# --- verbose output --------------------------------------------------------
v() { "$BIN" -v --no-color "$@" 2>&1; }
out=$(v 10 ADD 3)
[[ $out == *carry* && $out == *"flags"* && $out == *"ans_dec = 13"* ]]; ok "verbose add rows" 0 $?
out=$(v -T 10 AND 12)
[[ $out == *"truth table: AND"* && $out == *"used"* ]]; ok "truth table shown" 0 $?
out=$(v -T 10 LSHIFT -2)
[[ $out == *"runs as RSHIFT 2"* && $out == *"bit map"* ]]; ok "negative shift explained" 0 $?
# every verbose line must be aligned: the '=' sits in the same column on all rows
out=$(v -w 16 0x1234 AND 0x00FF | grep ' = ')
cols=$(while IFS= read -r l; do pre=${l%% = *}; echo "${#pre}"; done <<<"$out" | sort -u | wc -l)
ok "verbose '=' column aligned" 1 "$cols"
out=$(v 5 ADD 3 | tr -d '\033')
[[ $out != *$'\033'* ]]; ok "no escape codes with --no-color" 0 $?

# --- meta ------------------------------------------------------------------
ok "version flag" "bitcalc" "$("$BIN" --version | cut -d' ' -f1)"
"$BIN" --help >/dev/null; ok "help exits 0" 0 $?
"$BIN" 1 FOO 2 >/dev/null 2>&1; ok "error exits 1" 1 $?

printf '\n%d passed, %d failed\n' "$pass" "$fail"
((fail == 0))
