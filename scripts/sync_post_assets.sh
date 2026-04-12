#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$ROOT_DIR/_config.yml"
CATEGORY_FILE="$ROOT_DIR/_data/blog_categories.yml"
BEGIN_MARKER="  # BEGIN POST ASSET INCLUDES"
END_MARKER="  # END POST ASSET INCLUDES"

if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
  COLOR_RED="$(tput setaf 1)"
  COLOR_YELLOW="$(tput setaf 3)"
  COLOR_GREEN="$(tput setaf 2)"
  COLOR_BLUE="$(tput setaf 4)"
  COLOR_BOLD="$(tput bold)"
  COLOR_RESET="$(tput sgr0)"
else
  COLOR_RED=""
  COLOR_YELLOW=""
  COLOR_GREEN=""
  COLOR_BLUE=""
  COLOR_BOLD=""
  COLOR_RESET=""
fi

info() {
  printf '%b\n' "${COLOR_BLUE}${COLOR_BOLD}INFO${COLOR_RESET}  $*"
}

warn() {
  printf '%b\n' "${COLOR_YELLOW}${COLOR_BOLD}WARN${COLOR_RESET}  $*"
}

error() {
  printf '%b\n' "${COLOR_RED}${COLOR_BOLD}ERROR${COLOR_RESET} $*" >&2
}

success() {
  printf '%b\n' "${COLOR_GREEN}${COLOR_BOLD}OK${COLOR_RESET}    $*"
}

TMP_ASSETS="$(mktemp)"
TMP_CONFIG="$(mktemp)"
TMP_ALLOWED_CATEGORIES="$(mktemp)"
trap 'rm -f "$TMP_ASSETS" "$TMP_CONFIG" "$TMP_ALLOWED_CATEGORIES"' EXIT

cd "$ROOT_DIR"

info "Scanning post assets under _posts/"

find _posts -type f \( \
  -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o \
  -iname '*.webp' -o -iname '*.svg' -o -iname '*.avif' \
\) | LC_ALL=C sort > "$TMP_ASSETS"

awk '/^- name:[[:space:]]*/ { sub(/^- name:[[:space:]]*/, ""); print }' "$CATEGORY_FILE" | LC_ALL=C sort > "$TMP_ALLOWED_CATEGORIES"

if ! grep -Fq "$BEGIN_MARKER" "$CONFIG_FILE" || ! grep -Fq "$END_MARKER" "$CONFIG_FILE"; then
  error "_config.yml is missing the post asset include markers."
  exit 1
fi

asset_count="$(wc -l < "$TMP_ASSETS" | tr -d ' ')"
allowed_count="$(wc -l < "$TMP_ALLOWED_CATEGORIES" | tr -d ' ')"
info "Found $asset_count post asset file(s) and $allowed_count approved categor$( [[ "$allowed_count" == "1" ]] && echo 'y' || echo 'ies' )."
if [[ "$asset_count" == "0" ]]; then
  warn "No post-local image assets were found under _posts/."
fi

awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" -v assets_file="$TMP_ASSETS" '
BEGIN {
  while ((getline line < assets_file) > 0) {
    assets[++count] = line
  }
}
{
  if ($0 == begin) {
    print
    for (i = 1; i <= count; i++) {
      print "  - " assets[i]
    }
    skip = 1
    next
  }
  if ($0 == end) {
    skip = 0
    print
    next
  }
  if (!skip) print
}
' "$CONFIG_FILE" > "$TMP_CONFIG"

cp "$TMP_CONFIG" "$CONFIG_FILE"

info "Updated the generated post asset include block in _config.yml"

trim() {
  local value="$1"
  value="${value#${value%%[![:space:]]*}}"
  value="${value%${value##*[![:space:]]}}"
  printf '%s' "$value"
}

file_exists() {
  local repo_path="$1"
  [[ -f "$ROOT_DIR/$repo_path" ]]
}

asset_included() {
  local repo_path="$1"
  grep -Fxq "$repo_path" "$TMP_ASSETS"
}

extract_cover_image() {
  awk '
    /^---[[:space:]]*$/ { dashes++; next }
    dashes == 1 && /^cover_image:[[:space:]]*/ {
      sub(/^cover_image:[[:space:]]*/, "")
      gsub(/^"|"$/, "")
      gsub(/^\047|\047$/, "")
      print
      exit
    }
    dashes >= 2 { exit }
  ' "$1"
}

extract_inline_image_refs() {
  perl -ne 'while(/!\[[^\]]*\]\(\{\{\s*["\047]([^"\047]+)["\047]\s*\|\s*relative_url\s*\}\}\)/g){print "$1\n"} while(/!\[[^\]]*\]\(([^)]+)\)/g){$r=$1; next if $r =~ /\{\{/; print "$r\n"}' "$1"
}

extract_categories() {
  awk '
    function trim(v) {
      sub(/^[[:space:]]+/, "", v)
      sub(/[[:space:]]+$/, "", v)
      gsub(/^"|"$/, "", v)
      gsub(/^\047|\047$/, "", v)
      return v
    }
    /^---[[:space:]]*$/ { dashes++; next }
    dashes == 1 && /^categories:[[:space:]]*\[/ {
      line = $0
      sub(/^categories:[[:space:]]*\[/, "", line)
      sub(/\][[:space:]]*$/, "", line)
      n = split(line, parts, /,/)
      for (i = 1; i <= n; i++) {
        item = trim(parts[i])
        if (item != "") print item
      }
      exit
    }
    dashes == 1 && /^categories:[[:space:]]*$/ {
      in_categories = 1
      next
    }
    dashes == 1 && in_categories {
      if ($0 ~ /^[[:space:]]*-[[:space:]]+/) {
        line = $0
        sub(/^[[:space:]]*-[[:space:]]+/, "", line)
        line = trim(line)
        if (line != "") print line
        next
      }
      in_categories = 0
    }
    dashes >= 2 { exit }
  ' "$1"
}

category_allowed() {
  local category="$1"
  grep -Fxq "$category" "$TMP_ALLOWED_CATEGORIES"
}

allowed_categories_list() {
  paste -sd ', ' "$TMP_ALLOWED_CATEGORIES"
}

errors=0

while IFS= read -r md_file; do
  md_dir="$(dirname "$md_file")"

  categories=()
  while IFS= read -r category; do
    categories+=("$category")
  done < <(extract_categories "$md_file")
  if [[ "${#categories[@]}" -eq 0 ]]; then
    error "$md_file is missing an explicit categories list. Allowed categories: $(allowed_categories_list)."
    errors=1
  else
    for category in "${categories[@]}"; do
      if ! category_allowed "$category"; then
        error "$md_file uses invalid category '$category'. Allowed categories: $(allowed_categories_list)."
        errors=1
      fi
    done
  fi

  cover_image="$(trim "$(extract_cover_image "$md_file")")"
  if [[ -n "$cover_image" ]]; then
    case "$cover_image" in
      http://*|https://*) ;;
      /*)
        repo_path="${cover_image#/}"
        if ! file_exists "$repo_path"; then
          error "$md_file has cover_image '$cover_image' but the file does not exist."
          errors=1
        elif [[ "$repo_path" == _posts/* ]] && ! asset_included "$repo_path"; then
          error "$md_file has cover_image '$cover_image' but it is not included in _config.yml."
          errors=1
        fi
        ;;
      *)
        repo_path="$md_dir/$cover_image"
        if ! file_exists "$repo_path"; then
          error "$md_file has relative cover_image '$cover_image' but '$repo_path' does not exist."
          errors=1
        elif ! asset_included "$repo_path"; then
          error "$md_file has relative cover_image '$cover_image' but '$repo_path' is not included in _config.yml."
          errors=1
        fi
        ;;
    esac
  fi

  while IFS= read -r raw_ref; do
    ref="$(trim "$raw_ref")"
    [[ -z "$ref" ]] && continue

    case "$ref" in
      http://*|https://*|data:*|mailto:*|\#*)
        continue
        ;;
      /*)
        repo_path="${ref#/}"
        if ! file_exists "$repo_path"; then
          error "$md_file references missing inline image '$ref'."
          errors=1
        elif [[ "$repo_path" == _posts/* ]] && ! asset_included "$repo_path"; then
          error "$md_file references '$ref' but it is not included in _config.yml."
          errors=1
        fi
        ;;
      *)
        suggested="{{ '/${md_dir#./}/$ref' | relative_url }}"
        if [[ -f "$md_dir/$ref" ]]; then
          error "$md_file uses relative inline image '$ref'. Use ![Alt]($suggested) instead."
        else
          error "$md_file references missing inline image '$ref'."
        fi
        errors=1
        ;;
    esac
  done < <(extract_inline_image_refs "$md_file")
done < <(find _posts -type f -name '*.md' | LC_ALL=C sort)

if [[ "$errors" -ne 0 ]]; then
  error "Post asset sync completed, but validation failed."
  exit 1
fi

success "Post asset sync completed successfully. Included $asset_count image file(s)."
warn "If jekyll serve is already running, restart it now so the updated _config.yml include list takes effect."