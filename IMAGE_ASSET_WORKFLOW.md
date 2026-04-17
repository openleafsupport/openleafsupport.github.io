# Image Asset Workflow

This document explains how post images are managed in the two-stage publishing system.

## Directory Structure

```
_published-articles/              # Source posts with images
  ├── 2025/07/
  │   ├── 11-post-title.md       # Post markdown
  │   └── image-1.png            # Post images (same folder)
  ├── 2025/12/
  │   ├── 31-post-title.md
  │   ├── image-1.jpeg
  │   └── image-2.jpg
  └── ...

_posts/                           # Published posts with images (generated)
  ├── 2025-07-11-post-title.md   # Flat filename for Jekyll
  ├── 2025/
  │   └── 07/
  │       └── image-1.png        # Synced images
  └── ...

assets/post-assets/               # Final image location (for production)
  ├── 2025/07/image-1.png
  ├── 2025/12/image-1.jpeg
  └── ...
```

## Workflow

### 1. **Create a New Post**

Create a folder structure in `_published-articles/`:
```bash
mkdir -p _published-articles/2025/07
```

Create the post file:
```
_published-articles/2025/07/11-My-Post-Title.md
```

Add images to the **same folder** as the markdown file:
```
_published-articles/2025/07/image-1.jpeg
_published-articles/2025/07/image-2.jpg
```

### 2. **Reference Images in Markdown**

In your post, use simple filenames:
```markdown
---
layout: post
title: "My Post Title"
cover_image: "image-2.jpg"  # Just the filename
---

Here's a picture:
![Alt text](image-1.jpeg)  # Just the filename
```

**Not:** `/assets/post-assets/2025/07/image-1.jpeg`  
**Not:** `{{ '/assets/post-assets/2025/07/image-1.jpeg' | relative_url }}`

### 3. **Build Posts and Images**

Run the build script to process posts and copy images:
```bash
ruby scripts/build_posts.rb
```

This:
- Copies posts from `_published-articles/YYYY/MM/DD-title.md` → `_posts/YYYY-MM-DD-title.md`
- Copies images from `_published-articles/YYYY/MM/` → `_posts/YYYY/MM/`

### 4. **Validate**

Run the validation script to check everything:
```bash
bash scripts/validate_blog.sh
```

This:
- Verifies both `_published-articles/` and `_posts/` for completeness
- Syncs images from `_posts/YYYY/MM/` → `assets/post-assets/YYYY/MM/`
- Validates post structure, frontmatter, and image references

### 5. **Build Jekyll**

Build the static site:
```bash
bundle exec jekyll build
```

Jekyll:
- Reads posts from `_posts/YYYY-MM-DD-title.md`
- Uses the Jekyll plugin to convert `![Alt](image-1.jpeg)` → `![Alt](/assets/post-assets/2025/07/image-1.jpeg)`
- Outputs HTML to `_site/`

### 6. **Commit**

Commit both source and published:
```bash
git add _published-articles/ _posts/ assets/
git commit -m "Add new post: My Post Title"
git push
```

## Image Requirements

- **Format:** PNG, JPG, JPEG, GIF, WebP, SVG, AVIF
- **Naming:** Simple names like `image-1.jpeg`, `cover.png`
- **Storage:** Same folder as the markdown file in `_published-articles/`
- **Size:** Shortest side ≥ 800px, longest side ≥ 1000px, max 2.5MB
- **References:** Use simple filenames in markdown (`image-1.jpeg`)

## How It Works

1. **Source of truth:** `_published-articles/` — where you create and edit
2. **Build step:** `ruby scripts/build_posts.rb` copies to `_posts/`
3. **Validation:** `bash scripts/validate_blog.sh` copies to `assets/post-assets/`
4. **Jekyll build:** `bundle exec jekyll build` generates HTML
5. **Jekyll plugin:** Auto-converts simple filenames to full paths

The Jekyll plugin (`_plugins/post_asset_urls.rb`) handles the final path conversion during the build process, so you never have to write full asset paths in markdown.

## Example

**Source post:**
```
_published-articles/2025/07/11-Summer-Reading-List.md
_published-articles/2025/07/image-1.jpeg
_published-articles/2025/07/image-2.jpg
```

**After `ruby scripts/build_posts.rb`:**
```
_posts/2025-07-11-Summer-Reading-List.md
_posts/2025/07/image-1.jpeg
_posts/2025/07/image-2.jpg
```

**After `bash scripts/validate_blog.sh`:**
```
assets/post-assets/2025/07/image-1.jpeg
assets/post-assets/2025/07/image-2.jpg
```

**In generated HTML:**
```html
<img src="/assets/post-assets/2025/07/image-1.jpeg" alt="..." />
```
