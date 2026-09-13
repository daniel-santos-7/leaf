#!/bin/sh
# Diff a Leaf register dump against the Spike signature it has to reproduce.
#
# Both files are one hex word per line, so a plain diff reports line numbers
# and leaves you to multiply by four. This reports the offset from begin_dump
# instead -- the address the test stored to -- and stops after DIFF_LIMIT
# mismatches so one systematic failure cannot bury the log of a whole suite
# run. DIFF_LIMIT=0 lists every one of them.
#
# A word-count mismatch is reported on its own rather than as a wall of diff:
# it means DUMP_SIZE disagrees with what the test writes, which is a different
# mistake from a wrong value and is fixed in the test's Makefile.
#
# usage: compare.sh <leaf-dump> <spike-signature> [dump-size]
#   env: DIFF_LIMIT  mismatches to print before summarising (default 20)

set -eu

leaf=${1:?usage: compare.sh <leaf-dump> <spike-signature> [dump-size]}
spike=${2:?usage: compare.sh <leaf-dump> <spike-signature> [dump-size]}
dump_size=${3:-}
limit=${DIFF_LIMIT:-20}

name=$(basename "$(pwd)")

for f in "$leaf" "$spike"; do
	if [ ! -r "$f" ]; then
		echo "FAIL $name: $f is missing"
		exit 1
	fi
done

leaf_words=$(wc -l < "$leaf")
spike_words=$(wc -l < "$spike")

if [ "$leaf_words" -ne "$spike_words" ]; then
	echo "FAIL $name: $leaf_words words dumped, $spike_words in the signature"
	echo "   DUMP_SIZE${dump_size:+ ($dump_size)} has to match the bytes the test writes"
	exit 1
fi

if awk -v limit="$limit" '
	NR == FNR { leaf[FNR] = tolower($0); next }
	{
		if (leaf[FNR] != tolower($0)) {
			bad++
			if (limit <= 0 || bad <= limit)
				printf "   begin_dump+0x%04x: leaf %s  spike %s\n",
				       (FNR - 1) * 4, leaf[FNR], tolower($0)
		}
	}
	END {
		if (limit > 0 && bad > limit)
			printf "   ... %d more\n", bad - limit
		if (bad)
			printf "   %d of %d words differ\n", bad, FNR
		exit (bad != 0)
	}' "$leaf" "$spike"
then
	echo "PASS $name: $leaf_words words match the Spike signature"
else
	echo "FAIL $name: differs from the Spike signature"
	exit 1
fi
