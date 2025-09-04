#!/bin/sh

# Colors
RED="$(printf '\033[31m')"
GREEN="$(printf '\033[32m')"
RESET="$(printf '\033[0m')"

# Path to your parser binary
PARSER="./ccjsonparser"

# Number of parallel jobs (adjust to number of cores)
JOBS=16

# Function to test a single file
test_file() {
    file=$1
    expected=$2

    if [ ! -f "$file" ]; then
        printf "%s[SKIP]%s %s (file not found)\n" "$RED" "$RESET" "$file"
        return
    fi

    $PARSER "$file" >/dev/null 2>&1
    actual=$?

    if [ "$actual" -eq "$expected" ]; then
        printf "%s[PASS]%s %s (expected=%s, got=%s)\n" "$GREEN" "$RESET" "$file" "$expected" "$actual"
    else
        printf "%s[FAIL]%s %s (expected=%s, got=%s)\n" "$RED" "$RESET" "$file" "$expected" "$actual"
    fi
}

export PARSER RED GREEN RESET
export -f test_file

# Read file list and expected codes, run in parallel
awk '!/^($|#)/ {print $1, $2}' expected_exit_codes.txt | \
    xargs -n2 -P $JOBS sh -c 'test_file "$0" "$1"' 
