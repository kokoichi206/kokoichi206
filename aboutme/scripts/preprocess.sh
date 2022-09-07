#!/bin/sh
#
# Description:
#   Preprocess as the following steps:
#   1. \<YY> -> Current Year
#   2. \<MM> -> Current Month
#   3. \<DD> -> Current Day
#   4. XXXX 年　YY 月 ZZ 日生 (満 \<Age> 歳)
#        -> Fill in the <Age> using your birthday.
#
# Usage:
#   bash preprocess.sh <markdown_file.md>
#   # Without a file name, preprocess all markdown files (*.md).
#   bash preprocess.sh
#
set -euo pipefail

# ===== BEGIN: parse arguments =====
if [ "$#" -eq 1 ]; then
    # If file name is passed, only preprocess that file.
    files=("$1")
else
    # No arg is passed, preprocess all markdown files.
    files=$(ls *.md)
fi
# ===== END: parse arguments =====

# Need 3 arguments:
#   1. file name
#   2. before string
#   3. after string
function inline_substitute() {
    if [ "$#" -ne 3 ]; then
        return
    fi
    if [ "$(uname)" == "Darwin" ]; then
        # macOS
        sed -i -e "s@$2@$3@g" $1
    elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
        # Linux OS
        sed -i -E "s@$2@$3@g" $1
    fi
}

# ===== BEGIN: trap EXIT =====
function post_process() {
    if [ "$(uname)" == "Darwin" ]; then
        # macOS
        # Delete temporary files created by sed command.
        rm *.md-e
    fi
}
# ERR is special feature to bash
trap post_process EXIT
# ===== END: trap EXIT =====

YEAR=$(TZ=JST-9 date +"%Y")
MONTH=$(TZ=JST-9 date +"%m")
DAY=$(TZ=JST-9 date +"%d")
AGE_LINE_FORMAT=".*([0-9]{4})[ 　]?年[ 　]?([0-9][0-9]?)[ 　]?月[ 　]?([0-9][0-9]?)[ 　]?日生[ 　]?（満[ 　]?\\\<Age>[ 　]?歳）.*"

# ===== BEGIN: main loop =====
for file in ${files[@]}; do
    while read -r line
    do
        # step 1
        inline_substitute "$file" "\\\<YY>" "${YEAR}"
        # step 2
        inline_substitute "$file" "\\\<MM>" "${MONTH}"
        # step 3
        inline_substitute "$file" "\\\<DD>" "${DAY}"
        # step 4
        if [[ "${line}" =~ $AGE_LINE_FORMAT ]]; then
            # Calculate your age
            birthday=$(echo ${BASH_REMATCH[1]}*10000 + ${BASH_REMATCH[2]}*100+${BASH_REMATCH[3]} | bc)
            now=$(echo ${YEAR}*10000 + ${MONTH}*100+${DAY} | bc)
            age_day=$(echo $now-$birthday | bc)
            age=${age_day:0:${#age_day}-4}

            # Substitute $age for \<Age>
            inline_substitute "$file" "\\\<Age>" "${age}"
        fi
    done < "$file"
done
# ===== END: main loop =====
