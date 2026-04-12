#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$ROOT_DIR/_config.yml"
CATEGORY_FILE="$ROOT_DIR/_data/blog_categories.yml"
PUBLIC_ASSET_DIR="$ROOT_DIR/assets/post-assets"
BEGIN_MARKER="  # BEGIN POST ASSET INCLUDES"
END_MARKER="  # END POST ASSET INCLUDES"
MIN_IMAGE_SHORT_SIDE=800
MIN_IMAGE_LONG_SIDE=1000
MAX_IMAGE_BYTES=2500000
DEFAULT_FEATURED_POSTS_LIMIT=6

if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
  RED="$(tput setaf 1)"; YELLOW="$(tput setaf 3)"; GREEN="$(tput setaf 2)"
  BLUE="$(tput setaf 4)"; CYAN="$(tput setaf 6)"; BOLD="$(tput bold)"; RESET="$(tput sgr0)"
else
  RED=""; YELLOW=""; GREEN=""; BLUE=""; CYAN=""; BOLD=""; RESET=""
fi

info() { printf '%b\n' "${BLUE}${BOLD}INFO${RESET}  $*"; }
warn() { printf '%b\n' "${YELLOW}${BOLD}WARN${RESET}  $*"; }
error() { printf '%b\n' "${RED}${BOLD}ERROR${RESET} $*" >&2; }
ok() { printf '%b\n' "${GREEN}${BOLD}OK${RESET}    $*"; }
step() { printf '%b\n' "${CYAN}${BOLD}STEP${RESET}  $*"; }

CONTENT_SCAN_PATHS=(index.html 404.html README.md _posts _layouts _data _config.yml)
IMAGE_EXT_REGEX='\.(png|jpg|jpeg|gif|webp|svg|avif)$'

TMP_ASSETS="$(mktemp)"
TMP_CONFIG="$(mktemp)"
TMP_ALLOWED="$(mktemp)"
trap 'rm -f "$TMP_ASSETS" "$TMP_CONFIG" "$TMP_ALLOWED"' EXIT

cd "$ROOT_DIR"

trim() {
  local value="$1"
  value="${value#${value%%[![:space:]]*}}"
  value="${value%${value##*[![:space:]]}}"
  printf '%s' "$value"
}

extract_cover_image() {
  awk '/^---[[:space:]]*$/ { dashes++; next } dashes == 1 && /^cover_image:[[:space:]]*/ { sub(/^cover_image:[[:space:]]*/, ""); gsub(/^"|"$/, ""); gsub(/^\047|\047$/, ""); print; exit } dashes >= 2 { exit }' "$1"
}

extract_featured() {
  awk '/^---[[:space:]]*$/ { dashes++; next } dashes == 1 && /^featured:[[:space:]]*/ { sub(/^featured:[[:space:]]*/, ""); gsub(/^"|"$/, ""); gsub(/^\047|\047$/, ""); print; exit } dashes >= 2 { exit }' "$1"
}

extract_featured_posts_limit() {
  awk '/^featured_posts_limit:[[:space:]]*/ { sub(/^featured_posts_limit:[[:space:]]*/, ""); gsub(/[[:space:]]+$/, ""); print; exit }' "$CONFIG_FILE"
}

extract_categories() {
  awk '
    function trim(v) { sub(/^[[:space:]]+/, "", v); sub(/[[:space:]]+$/, "", v); gsub(/^"|"$/, "", v); gsub(/^\047|\047$/, "", v); return v }
    /^---[[:space:]]*$/ { dashes++; next }
    dashes == 1 && /^categories:[[:space:]]*\[/ { line=$0; sub(/^categories:[[:space:]]*\[/, "", line); sub(/\][[:space:]]*$/, "", line); n=split(line, parts, /,/); for (i=1;i<=n;i++) { item=trim(parts[i]); if (item != "") print item } exit }
    dashes == 1 && /^categories:[[:space:]]*$/ { in_categories=1; next }
    dashes == 1 && in_categories {
      if ($0 ~ /^[[:space:]]*-[[:space:]]+/) { line=$0; sub(/^[[:space:]]*-[[:space:]]+/, "", line); line=trim(line); if (line != "") print line; next }
      in_categories=0
    }
    dashes >= 2 { exit }
  ' "$1"
}

extract_inline_image_refs() {
  perl -ne 'while(/!\[[^\]]*\]\(\{\{\s*["\047]([^"\047]+)["\047]\s*\|\s*relative_url\s*\}\}\)/g){print "$1\n"} while(/!\[[^\]]*\]\(([^)]+)\)/g){$r=$1; next if $r =~ /\{\{/; print "$r\n"}' "$1"
}

has_line() { grep -Fq "$2" "$1"; }
file_exists() { [[ -f "$ROOT_DIR/$1" ]]; }
category_allowed() { grep -Fxq "$1" "$TMP_ALLOWED"; }
allowed_categories_list() { paste -sd ', ' "$TMP_ALLOWED"; }

is_content_file() {
  local path="$1"
  [[ "$path" == "index.html" || "$path" == "404.html" || "$path" == "README.md" || "$path" == "_config.yml" || "$path" == _posts/* || "$path" == _layouts/* || "$path" == _data/* ]]
}

is_post_markdown() {
  local path="$1"
  [[ "$path" == _posts/*.md || "$path" == _posts/*/*.md || "$path" == _posts/*/*/*.md ]]
}

is_post_image() {
  local path="$1"
  [[ "$path" == _posts/* ]] && [[ "$path" =~ $IMAGE_EXT_REGEX ]]
}

validate_image_asset() {
  local asset_path="$1"
  local size_bytes width height short_side long_side

  size_bytes="$(stat -f '%z' "$asset_path")"
  read -r width height <<< "$(sips -g pixelWidth -g pixelHeight "$asset_path" 2>/dev/null | awk '/pixelWidth:/{w=$2}/pixelHeight:/{h=$2} END{print w, h}')"

  if [[ -z "${width:-}" || -z "${height:-}" ]]; then
    error "$asset_path could not be inspected for dimensions."
    return 1
  fi

  if (( width < height )); then
    short_side=$width
    long_side=$height
  else
    short_side=$height
    long_side=$width
  fi

  if (( short_side < MIN_IMAGE_SHORT_SIDE || long_side < MIN_IMAGE_LONG_SIDE )); then
    error "$asset_path is too small (${width}x${height}). Minimum standard: shortest side >= ${MIN_IMAGE_SHORT_SIDE}px and longest side >= ${MIN_IMAGE_LONG_SIDE}px."
    return 1
  fi

  if (( size_bytes > MAX_IMAGE_BYTES )); then
    error "$asset_path is too large (${size_bytes} bytes). Maximum standard: ${MAX_IMAGE_BYTES} bytes (~2.5 MB)."
    return 1
  fi

  ok "$asset_path meets image standards (${width}x${height}, ${size_bytes} bytes)"
  return 0
}

sync_assets_and_config() {
  step "Syncing post-local assets"
  find _posts -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.webp' -o -iname '*.svg' -o -iname '*.avif' \) | LC_ALL=C sort > "$TMP_ASSETS"
  awk '/^- name:[[:space:]]*/ { sub(/^- name:[[:space:]]*/, ""); print }' "$CATEGORY_FILE" | LC_ALL=C sort > "$TMP_ALLOWED"

  if ! has_line "$CONFIG_FILE" "$BEGIN_MARKER" || ! has_line "$CONFIG_FILE" "$END_MARKER"; then
    error "_config.yml is missing the post asset include markers."
    exit 1
  fi

  local asset_count allowed_count
  asset_count="$(wc -l < "$TMP_ASSETS" | tr -d ' ')"
  allowed_count="$(wc -l < "$TMP_ALLOWED" | tr -d ' ')"
  info "Found $asset_count post asset file(s) and $allowed_count approved categor$( [[ "$allowed_count" == "1" ]] && echo 'y' || echo 'ies' )."
  [[ "$asset_count" == "0" ]] && warn "No post-local image assets were found under _posts/."

  rm -rf "$PUBLIC_ASSET_DIR"
  mkdir -p "$PUBLIC_ASSET_DIR"
  while IFS= read -r asset_path; do
    [[ -z "$asset_path" ]] && continue
    public_path="$PUBLIC_ASSET_DIR/${asset_path#_posts/}"
    mkdir -p "$(dirname "$public_path")"
    cp "$asset_path" "$public_path"
  done < "$TMP_ASSETS"
  info "Synced post assets into assets/post-assets/"

  awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" -v assets_file="$TMP_ASSETS" '
    BEGIN { while ((getline line < assets_file) > 0) { assets[++count] = line } }
    { if ($0 == begin) { print; for (i=1;i<=count;i++) print "  - " assets[i]; skip=1; next }
      if ($0 == end) { skip=0; print; next }
      if (!skip) print }
  ' "$CONFIG_FILE" > "$TMP_CONFIG"
  cp "$TMP_CONFIG" "$CONFIG_FILE"
  info "Updated the generated post asset include block in _config.yml"
}

validate_book_review_content() {
  local file="$1"
  info "Running Book Reviews content checks for $file"

  if ! grep -q '^---' "$file"; then
    warn "$file is missing front matter (---)."
  else
    ok "Front matter found"
  fi

  local field
  for field in title description categories cover_image; do
    if ! grep -q "^$field:" "$file"; then
      warn "$file is missing field: $field"
    else
      ok "$field present"
    fi
  done

  local section
  for section in "## Summary" "## My Thoughts" "## What Stayed With Me" "## Final Review"; do
    if ! grep -q "$section" "$file"; then
      warn "$file is missing section: $section"
    else
      ok "Found section: $section"
    fi
  done

  if ! grep -Eiq 'rating[^0-9]*[0-9]+([.][0-9]+)?/10' "$file"; then
    warn "$file has no recognizable rating line. Recommended format: Rating: X/10 or Rating: X.X/10"
  else
    ok "Rating format looks good"
  fi

  local word_count
  word_count="$(wc -w < "$file" | tr -d ' ')"
  if [[ "$word_count" -lt 300 ]]; then
    warn "$file has a low word count ($word_count words)"
  else
    info "$file word count: $word_count"
  fi

  if grep -q '“.*”' "$file"; then
    info "$file contains a quote"
  else
    warn "$file contains no smart-quote excerpt. Optional, but recommended."
  fi
}

validate_post_file() {
  local md_file="$1"
  local errors=0
  local md_dir repo_path cover_image bundle_name file_name ref raw_ref category featured_value featured_normalized
  md_dir="$(dirname "$md_file")"
  bundle_name="$(basename "$md_dir")"

  info "Validating: $md_file"

  local categories=()
  while IFS= read -r category; do categories+=("$category"); done < <(extract_categories "$md_file")
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

  featured_value="$(trim "$(extract_featured "$md_file")")"
  featured_normalized="$(printf '%s' "$featured_value" | tr '[:upper:]' '[:lower:]')"
  if [[ -z "$featured_value" ]]; then
    error "$md_file is missing the featured field. Set featured: true or featured: false explicitly."
    errors=1
  elif [[ "$featured_normalized" != "true" && "$featured_normalized" != "false" ]]; then
    error "$md_file has invalid featured value '$featured_value'. Use featured: true or featured: false."
    errors=1
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
        elif [[ "$repo_path" == _posts/* ]]; then
          file_name="$(basename "$repo_path")"
          error "$md_file uses cover_image '$cover_image'. Use cover_image: '$file_name' and let the script publish it to /assets/post-assets/$bundle_name/."
          errors=1
        fi
        ;;
      *)
        repo_path="$md_dir/$cover_image"
        if ! file_exists "$repo_path"; then
          error "$md_file has relative cover_image '$cover_image' but '$repo_path' does not exist."
          errors=1
        fi
        ;;
    esac
  fi

  while IFS= read -r raw_ref; do
    ref="$(trim "$raw_ref")"
    [[ -z "$ref" ]] && continue
    case "$ref" in
      http://*|https://*|data:*|mailto:*|\#*) continue ;;
      /*)
        repo_path="${ref#/}"
        if ! file_exists "$repo_path"; then
          error "$md_file references missing inline image '$ref'."
          errors=1
        elif [[ "$repo_path" == _posts/* ]]; then
          file_name="$(basename "$repo_path")"
          error "$md_file references '$ref'. Use {{ '/assets/post-assets/$bundle_name/$file_name' | relative_url }} instead."
          errors=1
        fi
        ;;
      *)
        if [[ -f "$md_dir/$ref" ]]; then
          error "$md_file uses relative inline image '$ref'. Use ![Alt]({{ '/assets/post-assets/$bundle_name/$ref' | relative_url }}) instead."
        else
          error "$md_file references missing inline image '$ref'."
        fi
        errors=1
        ;;
    esac
  done < <(extract_inline_image_refs "$md_file")

  if printf '%s\n' "${categories[@]}" | grep -Fxq 'Book Reviews'; then
    validate_book_review_content "$md_file"
  else
    info "Skipping Book Reviews-specific content checks for $md_file"
  fi

  return "$errors"
}

sync_assets_and_config

FEATURED_POSTS_LIMIT="$(trim "$(extract_featured_posts_limit)")"
if [[ -z "$FEATURED_POSTS_LIMIT" ]]; then
  FEATURED_POSTS_LIMIT="$DEFAULT_FEATURED_POSTS_LIMIT"
elif ! [[ "$FEATURED_POSTS_LIMIT" =~ ^[0-9]+$ ]]; then
  error "featured_posts_limit in _config.yml must be a whole number."
  exit 1
fi

USE_STAGED_ONLY=0
if [[ "${1:-}" == "--staged" ]]; then
  USE_STAGED_ONLY=1
  shift
fi

FILES=()
CONTENT_FILES=()
IMAGE_FILES=()

if (( USE_STAGED_ONLY == 1 )); then
  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    [[ ! -e "$path" ]] && continue

    if is_post_markdown "$path"; then
      FILES+=("$path")
    fi

    if is_content_file "$path"; then
      CONTENT_FILES+=("$path")
    fi

    if is_post_image "$path"; then
      IMAGE_FILES+=("$path")
    fi
  done < <(git diff --cached --name-only --diff-filter=ACMR)
elif [[ "$#" -gt 0 ]]; then
  for arg in "$@"; do
    if [[ ! -f "$arg" ]]; then
      error "File not found: $arg"
      exit 1
    fi
    FILES+=("$arg")
    if is_content_file "$arg"; then
      CONTENT_FILES+=("$arg")
    fi
    if is_post_image "$arg"; then
      IMAGE_FILES+=("$arg")
    fi
  done
else
  while IFS= read -r md_file; do FILES+=("$md_file"); done < <(find _posts -type f -name '*.md' | LC_ALL=C sort)
  while IFS= read -r content_file; do CONTENT_FILES+=("$content_file"); done < <(find index.html 404.html README.md _posts _layouts _data _config.yml -type f 2>/dev/null | LC_ALL=C sort)
  while IFS= read -r image_file; do IMAGE_FILES+=("$image_file"); done < <(find _posts -type f | grep -E "$IMAGE_EXT_REGEX" | LC_ALL=C sort)
fi

if (( USE_STAGED_ONLY == 1 )) && [[ "${#FILES[@]}" -eq 0 && "${#CONTENT_FILES[@]}" -eq 0 && "${#IMAGE_FILES[@]}" -eq 0 ]]; then
  info "No staged website/blog content changes detected. Skipping targeted validation."
  exit 0
fi

if (( USE_STAGED_ONLY == 0 )) && [[ "${#FILES[@]}" -eq 0 ]]; then
  warn "No markdown files found to validate."
  exit 0
fi

overall_fail=0
if [[ "${#CONTENT_FILES[@]}" -gt 0 ]]; then
  em_dash_matches="$(grep -In '—' "${CONTENT_FILES[@]}" 2>/dev/null || true)"
else
  em_dash_matches=""
fi
if [[ -n "$em_dash_matches" ]]; then
  error "Em dash characters (—) are not allowed in website or blog content. Replace them with a normal hyphen (-)."
  while IFS= read -r match; do
    [[ -z "$match" ]] && continue
    printf '%b\n' "${RED}  -> ${match}${RESET}" >&2
  done <<< "$em_dash_matches"
  overall_fail=1
else
  info "No em dashes found in website or blog content."
fi

step "Validating post image standards"
if [[ "${#IMAGE_FILES[@]}" -eq 0 ]]; then
  info "No changed post images to validate."
else
  for asset_path in "${IMAGE_FILES[@]}"; do
    [[ -z "$asset_path" ]] && continue
    if ! validate_image_asset "$asset_path"; then
      overall_fail=1
    fi
  done
fi

featured_count=0
while IFS= read -r md_file; do
  featured_value="$(trim "$(extract_featured "$md_file")")"
  featured_normalized="$(printf '%s' "$featured_value" | tr '[:upper:]' '[:lower:]')"
  if [[ "$featured_normalized" == "true" ]]; then
    featured_count=$((featured_count + 1))
  fi
done < <(find _posts -type f -name '*.md' | LC_ALL=C sort)

if [[ "$featured_count" -gt "$FEATURED_POSTS_LIMIT" ]]; then
  error "No more than $FEATURED_POSTS_LIMIT blog posts can be featured at once. Current featured count: $featured_count."
  overall_fail=1
else
  info "Featured posts count: $featured_count/$FEATURED_POSTS_LIMIT"
fi

for md_file in "${FILES[@]}"; do
  printf '%b\n' "${CYAN}----------------------------------${RESET}"
  if ! validate_post_file "$md_file"; then
    overall_fail=1
  fi
done
printf '%b\n' "${CYAN}----------------------------------${RESET}"

if [[ "$overall_fail" -ne 0 ]]; then
  error "Some checks failed. Please review the output above."
  exit 1
fi

ok "All critical checks passed!"
warn "If jekyll serve is already running, restart it now so updated post assets and _config.yml includes take effect."