#!/usr/bin/env bash
set -u
BIN=${1:-"$(dirname "$0")/../src/bitcalc"}
N=${2:-300}
command -v python3 >/dev/null || { echo "python3 not found, skipping fuzz"; exit 0; }
python3 - "$BIN" "$N" <<'PY'
import random, subprocess, sys
binp, n = sys.argv[1], int(sys.argv[2])
random.seed(1234)
bad = 0
def run(args):
    r = subprocess.run([binp, "-q", "--no-color", *args], capture_output=True, text=True)
    return r.stdout.strip()
for _ in range(n):
    w = random.choice([8, 16, 32, 64]); m = (1 << w) - 1
    a = random.getrandbits(w); b = random.getrandbits(w)
    op = random.choice(["ADD","SUB","MUL","AND","OR","XOR","NAND","NOR","XNOR","LSHIFT","RSHIFT","ROL","ROR"])
    k = random.randrange(0, w)
    if op in ("LSHIFT","RSHIFT","ROL","ROR"):
        flip = random.random() < .3
        cnt = -k if flip else k
        eff = {"LSHIFT":"RSHIFT","RSHIFT":"LSHIFT","ROL":"ROR","ROR":"ROL"}[op] if flip else op
        exp = {"LSHIFT": (a << k) & m, "RSHIFT": a >> k,
               "ROL": ((a << (k % w)) | (a >> (w - k % w))) & m if k % w else a,
               "ROR": ((a >> (k % w)) | (a << (w - k % w))) & m if k % w else a}[eff]
        got = run(["-w", str(w), "-t", "hex", hex(a), op, str(cnt)])
    else:
        exp = {"ADD": (a+b)&m, "SUB": (a-b)&m, "MUL": (a*b)&m, "AND": a&b, "OR": a|b, "XOR": a^b,
               "NAND": ~(a&b)&m, "NOR": ~(a|b)&m, "XNOR": ~(a^b)&m}[op]
        got = run(["-w", str(w), "-t", "hex", hex(a), op, hex(b)])
    want = "0x%0*X" % ((w + 3) // 4, exp)
    if got != want:
        bad += 1
        print(f"MISMATCH w={w} {hex(a)} {op} {hex(b) if op not in ('LSHIFT','RSHIFT','ROL','ROR') else cnt}: got {got} want {want}")
print(f"fuzz: {n - bad}/{n} ok")
sys.exit(1 if bad else 0)
PY
