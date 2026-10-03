# bitcalc

A hardware-engineering calculator for the command line: bitwise operations, binary arithmetic and
base conversion, with the **working shown as aligned bit rows** so you can see *why* the answer is
what it is. Pipe-friendly: when output is not a terminal it prints only the result.

```text
$ bitcalc 10 ADD 3
10 ADD 3   [8-bit]
carry   :      1
10      = 0000 1010  (10)
3       = 0000 0011  (3)
        = +
-------------------------
ans     = 0000 1101
ans_dec = 13
flags   = Z=0 N=0 C=0 V=0
```

## Install

Debian, Ubuntu, Raspberry Pi OS, Kali (any apt system, any CPU architecture):

```bash
curl -fsSL https://ridddle-en.github.io/bitcalc/install.sh | bash
```

Uninstall:

```bash
curl -fsSL https://ridddle-en.github.io/bitcalc/uninstall.sh | bash
```

The installer adds a **GPG-signed** apt repository (the key fingerprint is checked before it is trusted)
and installs the `bitcalc` package, so `apt upgrade` keeps it current. Manual setup instructions are on
the repository page. You can also run `src/bitcalc` directly; it only needs bash 4.4+.

## What it does

| Area | Operators |
|------|-----------|
| Arithmetic (with carry / borrow / overflow flags) | `ADD SUB MUL DIV MOD` (or `+ - * / %`) |
| Logic (with truth tables via `-T`) | `AND OR XOR NAND NOR XNOR NOT` |
| Shifts | `LSHIFT RSHIFT ASR` (or `<< >> >>>`) |
| Rotates (MCU style) | `ROL ROR` |
| Unary | `NOT 1COMP 2COMP NEG BSWAP POPCNT PARITY CLZ CTZ REV` |
| Conversion | bin / oct / dec / hex / BCD / Gray, fractional dec<->bin, widths 2-64 |

**A negative count reverses the direction:** `LSHIFT -2` runs as `RSHIFT 2`, `ROL -3` as `ROR 3`, and so on;
the output says so.

### Examples

```bash
bitcalc 10 AND -2                  # working for a bitwise AND, signed operand
bitcalc -T 0b10110001 ROL -3       # rotate the other way + bit-mapping table
bitcalc -T XNOR                    # plain truth table
bitcalc -w 16 0xABCD BSWAP         # byte swap
bitcalc -w 16 -t hex 2COMP -10     # 0xFFF6
bitcalc --prec 12 13.625           # decimal fraction -> binary, multiply-by-2 trace
bitcalc -f bin 1101.101            # binary fraction -> 13.625
bitcalc -q 10 LSHIFT 2 | bitcalc -t hex   # pipelines: result only
echo "0xFF ROR 4" | bitcalc        # expressions from stdin
bitcalc -i                         # interactive shell: ans, :width 16, :to hex, history
```

Width defaults to the smallest of 8/16/32/64 bits that holds the operands; `-w` overrides it.
Results wrap to the width; the `flags` row reports Z (zero), N (sign), C (carry, B on subtraction), V (signed overflow).
Full reference: `man bitcalc`.

## Repository layout

```text
src/bitcalc               the program (single bash file)
man/bitcalc.1             man page
completions/              bash completion
packaging/                control template, install/uninstall one-liners, landing page
scripts/                  build-deb.sh, make-apt-repo.sh, gen-signing-key.sh
tests/                    run.sh (unit-style checks), fuzz.sh (cross-check against Python)
keys/                     PUBLIC signing key (committed)
.github/workflows/        ci.yml (test + package + install matrix), release.yml (sign + publish + verify)
docs/RELEASING.md         one-time setup and how to cut a release
Makefile                  make lint | test | deb | repo-local
```

## Development

```bash
make lint        # shellcheck
make test        # tests/run.sh + fuzz
make deb VERSION=1.0.0
```

Releasing and key setup: see [docs/RELEASING.md](docs/RELEASING.md).

## License

MIT, see [LICENSE](LICENSE).
