#!/bin/bash
set -euo pipefail

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

# Pretty print some yaml
function show-yaml() {
  # Use yq because we like consistent formatting.
  # Use bat so all syntax highlighting uses the same color
  # theme, and so we can show/highlight specific lines.
  show-file "$1" \
    "yq . $1 | bat -n -l yaml ${2:-}"
}

# Pretty print some rego
function show-rego() {
  # Use opa fmt because we like consistent formatting.
  # Use bat for nice syntax highlighting.
  show-file "$1" \
    "ec opa fmt < $1 | bat -n -l rego ${2:-}"
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

  # Uncomment to start each section on a clear screen
  #clear

  echo "╭─$line─╮"
  echo "┝ $text ┥"
  echo "╰─$line─╯"
}

# Show a command, then run it after the user hits enter
function pause-then-run() {
  pause "$(show-cmd "$1")"
  run-cmd "$1"
}

# Show a command, then run it immediately
function show-then-run() {
  show-cmd "$1"
  run-cmd "$1"
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
  printf "💬 %s\n\n" "$1" | fold -s -w 100
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

setup-workdir
