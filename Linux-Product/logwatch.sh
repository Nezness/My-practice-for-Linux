#!/usr/bin/env bash
# Exit codes: 0 = no match, 1 = error, 2 = match found

set -u

PROGNAME=$(basename "$0")
echo "$PROGNAME launched"
echo "If you need help, type -h"
PATTERN="error|fail|critical"
OUTFILE=""
FOLLOW=false
VERBOSE=false

print_usage()
{
	cat <<USAGE
Usage: $PROGNAME [option] <file|dir>
Options:
	-p, --pattern PAT
	-o, --output FILE
	-f, --follow
	-s, --silent
	-v, --verbose
	-h, --help
Exit codes:
	0 = no match found
	1 = error (args wrong|not found)
	2 = match found
Behaviour:
	- If target is a file: search that file
	- If target is a directory: search *.log files inside
USAGE
}

# For debug
logerr()
{
	if [ "$VERBOSE" = true ]; then
		printf '%s\n' "$*" >&2
	fi
}

ARGS=()
while [[ $# -gt 0 ]]; do
	case "$1" in
		-p|--pattern) shift; PATTERN="$1"; shift;;
		-o|--output) shift; OUTFILE="$1"; shift;;
		-f|--follow) FOLLOW=true; shift;;
		-s|--silent) SILENT=true; shift;;
		-v|--verbose) VERBOSE=true; shift;;
		-h|--help) print_usage; exit 0;;
		--) shift; break;;
		-*) echo "Unknown option: $1"; print_usage; exit 1;;
		*) ARGS+=("$1"); shift;;
	esac
done

# Check arguments
if [ "${#ARGS[@]}" -lt 1 ]; then
	echo "Error: target file or directory required" >&2
	print_usage
	exit 1
fi
TARGET="${ARGS[0]}"

# What target is ?
TG=()
if [ -f "$TARGET" ]; then
	TG+=("$TARGET")
elif [ -d "$TARGET" ]; then
	while IFS= read -r -d $'\0' f; do
		TG+=("$f")
	done < <(find "$TARGET" -maxdepth 1 -type f -name '*.log' -print0)
else
	echo "Error: target not found: $TARGET" >&2
	exit 1
fi

if [ "${#TG[@]}" -eq 0 ]; then
	echo "No log files found in target: $TARGET" >&2
	exit 1
fi

# Function to search
perform_search()
{
	local file="$1"
	logerr "Searching in: $file"
	if [ "$FOLLOW" = true ];then
		if [ -n "$OUTFILE" ]; then
			tail -n 0 -F "$file" 2>/dev/null | grep --line-buffered -Ei "$PATTERN" | tee -a "$OUTFILE"${SILENT:+ >/dev/null}
		else
			tail -n 0 -F "$file" 2>/dev/null |grep --line-buffered -Ei "$PATTERN"
		fi
		return 0
	else
		if [ -n "$OUTFILE" ]; then
			if [ "$SILENT" = true ]; then
				grep -Ei "$PATTERN" "$file" >> "$OUTFILE" || true
			else
				grep -Ei "$PATTERN" "$file" | tee -a "$OUTFILE"
			fi
			return ${PIPESTATUS[0]:-0}
		else
		grep -Ei "$PATTERN" "$file"
		return ${PIPESTATUS[0]:-0}
		fi
	fi
}

# Execution logic
if [ "$FOLLOW" = false ]; then
	match_found=false
	for f in "${TG[@]}"; do
		if perform_search "$f"; then
			if grep -Ei "$PATTERN" "$f" >/dev/null 2>&1; then
				match_found=true
			fi
		else
			logerr "grep failed on $f"
		fi
	done

	if [ "$match_found" = true ]; then
		exit 2
	else
		exit 0
	fi

else
	for f in "${TG[@]}"; do
		perform_search "$f" &
	done
	wait
fi
