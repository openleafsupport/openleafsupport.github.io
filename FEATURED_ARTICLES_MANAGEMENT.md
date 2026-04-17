# Featured Articles Management

This document explains how to manage featured articles using a centralized JSON configuration.

## Overview

Instead of manually editing `featured: 1` in each post's frontmatter, you manage featured articles through a single JSON file (`_data/featured_articles.json`). This provides:

- **Centralized management** — All featured articles in one place
- **Easy reordering** — Change ranks without editing multiple markdown files
- **Automatic synchronization** — Sync scripts keep markdown files in sync with JSON
- **Built-in validation** — Catch errors like duplicate ranks or invalid values

## File: `_data/featured_articles.json`

Location: `/Users/apal/personal-codebase/openleafsupport.github.io/_data/featured_articles.json`

Format:
```json
{
  "featured": [
    {
      "rank": 1,
      "file": "_published-articles/2025/07/11-Why-Reading-Matters-More-Than-Doomscrolling-for-Your-Attention.md"
    },
    {
      "rank": 2,
      "file": "_published-articles/2026/01/01-How-to-Build-a-Reading-Habit-Without-Forcing-It-(That-Actually-Lasts).md"
    },
    {
      "rank": 3,
      "file": "_published-articles/2025/12/31-How-I-Encouraged-My-4-Year-Old-to-Choose-Books-Over-Screens.md"
    }
  ]
}
```

### Rules

1. **Rank Range**: Must be between 1-6 (supports up to 6 featured articles)
2. **Unique Ranks**: No two articles can have the same rank
3. **Valid Paths**: File paths must point to actual markdown files in `_published-articles/`
4. **Optional**: Not all articles need to be featured. Only featured articles appear in the JSON

## Workflow

### 1. Add an Article to Featured List

Edit `_data/featured_articles.json`:
```json
{
  "rank": 4,
  "file": "_published-articles/2026/02/21-A-Good-Girl's-Guide-to-Murder-Book-Review-Smart-Addictive-and-Dark.md"
}
```

### 2. Sync Featured Values to Markdown Files

Run the sync script:
```bash
ruby scripts/sync_featured_articles.rb
```

This script:
- Reads `_data/featured_articles.json`
- Updates all featured articles with `featured: <rank>` in their frontmatter
- Removes `featured:` field from articles NOT in the JSON

### 3. Validate Configuration

Run the validation script:
```bash
bash scripts/validate_blog.sh
```

This checks:
- ✅ Valid JSON syntax
- ✅ All ranks are between 1-6
- ✅ No duplicate ranks
- ✅ All referenced files exist

### 4. Build and Commit

```bash
ruby scripts/build_posts.rb      # Generate posts to _posts/
bash scripts/validate_blog.sh    # Validate everything
bundle exec jekyll build         # Build the site
git add _published-articles/ _posts/ _data/featured_articles.json
git commit -m "Update featured articles"
git push
```

## Examples

### Reorder Featured Articles

Current order:
```json
{"rank": 1, "file": "article-A.md"},
{"rank": 2, "file": "article-B.md"},
{"rank": 3, "file": "article-C.md"}
```

Swap B and C:
```json
{"rank": 1, "file": "article-A.md"},
{"rank": 2, "file": "article-C.md"},
{"rank": 3, "file": "article-B.md"}
```

Run: `ruby scripts/sync_featured_articles.rb` — Done!

### Remove an Article from Featured

Delete the entry from JSON:
```json
{"rank": 1, "file": "article-A.md"},
{"rank": 2, "file": "article-C.md"}
// article-B was removed
```

Run: `ruby scripts/sync_featured_articles.rb` — The `featured:` field is automatically removed from article-B.md

### Feature a New Article

1. Add entry to JSON with next available rank:
   ```json
   {"rank": 4, "file": "_published-articles/2026/04/12-New-Post.md"}
   ```

2. Run: `ruby scripts/sync_featured_articles.rb`

3. The new post gets `featured: 4` automatically added to its frontmatter

## Markdown File Behavior

### Before Sync
```markdown
---
layout: post
title: "My Post"
featured: 1
---
```

### JSON Configuration
```json
{"rank": 3, "file": "...my-post.md"}
```

### After Sync
```markdown
---
layout: post
title: "My Post"
featured: 3
---
```

### Article Not in JSON
If an article is NOT in the featured list:
- If it has `featured: X` in markdown, it's removed
- If it has no `featured:` field, nothing happens

## Scripts

### `scripts/sync_featured_articles.rb`

Synchronizes `_data/featured_articles.json` with markdown files:
- Adds/updates `featured:` values in featured articles
- Removes `featured:` from non-featured articles
- Preserves other frontmatter fields

Usage: `ruby scripts/sync_featured_articles.rb`

### `scripts/validate_blog.sh` (enhanced)

Validates the featured articles configuration:
- Checks JSON syntax
- Validates rank values (1-6)
- Detects duplicate ranks
- Validates file paths

This runs automatically as part of blog validation.

## Validation Errors

### Invalid Rank
```
ERROR Invalid featured rank: 7. Must be between 1-6.
```
**Fix**: Update rank to 1-6

### Duplicate Rank
```
ERROR Duplicate featured rank: 3. Each featured article must have a unique rank (1-6).
```
**Fix**: Assign unique rank to each article

### Invalid JSON
```
ERROR Invalid JSON in _data/featured_articles.json
```
**Fix**: Check JSON syntax (missing comma, bracket, quote, etc.)

## Tips

- **Edit the JSON file** to change featured articles — never manually edit `featured:` in markdown
- **Run sync script** after each JSON change
- **Validate before building** to catch configuration errors early
- **Commit the JSON file** to git for version control
- **Maximum 6 featured articles** per the limit defined in the system

## FAQ

**Q: Can I manually edit the `featured:` field in markdown?**
A: It's not recommended. If you do, the sync script will override it next time you run it. Always use the JSON file as your source of truth.

**Q: What if I feature 4 articles but have `featured_posts_limit: 6` in `_config.yml`?**
A: That's fine! The limit is the maximum. You can feature fewer articles than the limit.

**Q: Can I skip rank 2 and use ranks 1, 3, 5?**
A: Yes, as long as ranks are unique and between 1-6. The homepage will display them in order: 1, 3, 5.

**Q: Do I need to run sync after every change?**
A: Yes, always run `ruby scripts/sync_featured_articles.rb` after editing the JSON file.
