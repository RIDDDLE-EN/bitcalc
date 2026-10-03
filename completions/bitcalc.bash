_bitcalc() {
	local cur prev
	cur=${COMP_WORDS[COMP_CWORD]}
	prev=${COMP_WORDS[COMP_CWORD - 1]}
	case $prev in
	-f | --from) mapfile -t COMPREPLY < <(compgen -W "bin oct dec hex" -- "$cur"); return ;;
	-t | --to) mapfile -t COMPREPLY < <(compgen -W "bin oct dec hex bcd gray" -- "$cur"); return ;;
	-w | --width) mapfile -t COMPREPLY < <(compgen -W "auto 8 16 32 64" -- "$cur"); return ;;
	esac
	if [[ $cur == -* ]]; then
		mapfile -t COMPREPLY < <(compgen -W "--from --to --width --prec --quiet --verbose --truth --unsigned --no-color --color --interactive --version --help" -- "$cur")
	else
		mapfile -t COMPREPLY < <(compgen -W "ADD SUB MUL DIV MOD AND OR XOR NAND NOR XNOR LSHIFT RSHIFT ASR ROL ROR NOT 1COMP 2COMP NEG BSWAP POPCNT CLZ CTZ REV PARITY" -- "${cur^^}")
	fi
}
complete -F _bitcalc bitcalc
