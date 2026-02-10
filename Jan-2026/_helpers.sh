#!/bin/bash
set -euo pipefail

markdown() {
  [ "${MARKDOWN_MODE:-}" = 1 ]
}

# Create a file with given content
function create-file() {
  local filename="$1"
  local content="$2"
  echo "$content" > $filename
}

# Append to a file with given content
function append-file() {
  local filename="$1"
  local content="$2"
  echo "$content" >> $filename
}

# Base functionality for custom file rendering
function show-file() {
  local filename="$1"
  local cmd="$2"
  show-cmd "cat $filename"
  run-cmd "$cmd"
}

# In the markdown/blog post version we can't easily show line numbers.
# So this is an alternative way to indicate that we're viewing an excerpt
# from the file rather then the whole file.
# If the sed param was: "17,$p"
# This would produce: "\n# from-line: 17"
function extract-start-line-text-from-sed-param() {
  local sed_param="${1:-}"
  if [ -n "$sed_param" ]; then
    printf '\n# from-line: %s' ${sed_param%%,*}
  fi
}

# Pretty print some yaml
function show-yaml() {
  # Use yq because we like consistent formatting.
  if markdown; then
    local from_line=$(extract-start-line-text-from-sed-param "${3:-}")
    printf '```yaml\n# file: %s%s\n\n%s\n```\n\n' "$1" "$from_line" "$(yq . "$1" | sed -n "${3:-p}")"
  else
    # Use bat so all syntax highlighting uses the same color
    # theme, and so we can show/highlight specific lines.
    show-file "$1" "yq . $1 | bat -n -l yaml ${2:-}"
  fi
}

# Pretty print some rego
function show-rego() {
  # Use opa fmt because we like consistent formatting.
  if markdown; then
    local from_line=$(extract-start-line-text-from-sed-param "${3:-}")
    printf '```rego\n# file: %s%s\n\n%s\n```\n' "$1" "$from_line" "$(ec opa fmt < "$1" | sed -n "${3:-p}")"
  else
    # Use bat for nice syntax highlighting.
    show-file "$1" "ec opa fmt < $1 | bat --color always -n -l rego ${2:-}"
  fi
}

# Output a fancy section heading. Assume you want to add a pause
# at the end of the current section before starting a new one
function h1() {
  if [ "${_first:-1}" = 1 ]; then
    _first=0
  else
    pause
  fi

  local text="$1"
  local line=$(sed 's/./─/g' <<< "$text")

  if markdown; then
    printf '## %s\n\n' "$1"
  else
    # Uncomment to start each section on a clear screen
    #clear

    echo "╭─$line─╮"
    echo "┝ $text ┥"
    echo "╰─$line─╯"
  fi

}

# Show a command, then run it after the user hits enter
function pause-then-run() {
  if markdown; then
    show-then-run "$1"
  else
    pause "$(show-cmd "$1")"
    run-cmd "$1"
  fi
}

# Show a command, then run it immediately
function show-then-run() {
  if markdown; then
    printf '```ec\n%s\n' "\$ $1"
    run-cmd "$1"
    printf '```\n\n'
  else
    show-cmd "$1"
    run-cmd "$1"
  fi
}

# Output some text and wait for the user to press enter
function pause() {
  local default_msg="$(ansi darkgray "Press Enter to continue...")"
  local msg="${1:-$default_msg}"

  if [ "${TRANSCRIPT_MODE:-}" = 1 ]; then
    if [ -n "${1:-}" ]; then
      echo "$msg"
    fi
  else
    read -p "$msg"
  fi
  nl
}

# Eval a command line
function run-cmd() {
  set +e
  eval "$1"
  set -e
  nl
}

# Pretty-print a command line
function show-cmd() {
  printf "%s %s\n" "$(ansi yellow \$)" "$1"
}

# Pretty-print variable names and values
function show-vars() {
  # Find the longest var name size for neat alignment
  local max_width=0
  for v in $@; do
    (( ${#v} > max_width )) && max_width=${#v}
  done

  local label_width=$((max_width + 1))
  for v in $@; do
    printf "%-${label_width}s %s\n" "$v:" "${!v}"
  done
  nl
}

# Pretty-print a message
function show-msg() {
  if markdown; then
    printf "%s\n\n" "$1" | fold -s -w 100
  else
    printf "💬 %s\n\n" "$1" | fold -s -w 100
  fi
}

# Output a line break
function nl() {
  printf "\n"
}

# Output color text
ansi() {
  local code="$1"
  local text="${2:-""}"

  case "$code" in
    reset)        code="0"    ;;
    black)        code="0;30" ;;
    red)          code="0;31" ;;
    green)        code="0;32" ;;
    orange)       code="0;33" ;;
    blue)         code="0;34" ;;
    purple)       code="0;35" ;;
    cyan)         code="0;36" ;;
    lightgray)    code="0;37" ;;
    darkgray)     code="1;30" ;;
    lightred)     code="1;31" ;;
    lightgreen)   code="1;32" ;;
    yellow)       code="1;33" ;;
    lightblue)    code="1;34" ;;
    lightpurple)  code="1;35" ;;
    lightcyan)    code="1;36" ;;
    white)        code="1;37" ;;
  esac

  if [ -n "$text" ]; then
    # Wrap provided text
    printf '\e[%sm%s\e[0m' "$code" "$text"
  else
    # Just emit the code
    printf '\e[%sm' "$code"
  fi
}

# So the generated files end up in their own directory
setup-workdir() {
  cd $(mktemp -d ./tmp-work-XXXX)
}

title() {
  if markdown; then
    printf "%s\ntitle: %s\n" "---" "$1"
    printf "date: %s\n" "$(date +'%Y-%m-%dT%H:%M:%S%:z')"
    printf "author: %s\n" "$2"
    printf "%s\n" "---"
  else
    h1 "$1"
  fi
}

setup-workdir
