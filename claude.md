# Claude Code Instructions

## CRITICAL RULES

1. **NEVER auto-commit** — User commits only
2. **NO unnecessary .md files** — Only code/config/data files
3. **Never edit `_posts/`** — Auto-generated, always overwritten
4. **JSON is source of truth** — All articles in `_data/featured_articles.json`
5. **NO emoticons** — Not in claude.md, not in any file in this repo

## Folder Structure

- `_published-articles/YYYY/MM/DD-title.md` [EDIT] Source articles
- `_published-articles/YYYY/MM/image-*.ext` [EDIT] Images with simple names
- `_data/featured_articles.json` [EDIT] Featured config
- `_posts/YYYY-MM-DD-title.md` [AUTO] Auto-generated
- `_posts/YYYY/MM/image-*.ext` [AUTO] Auto-copied
- `assets/post-assets/YYYY/MM/` [AUTO] Auto-synced

## Workflow

1. Create/edit post: `_published-articles/YYYY/MM/DD-title.md`
2. Add images: Same folder (simple names: `image-1.jpeg`, `image-2.jpeg`)
3. Manage featured (optional): Edit `_data/featured_articles.json`
   - Add `"rank": 1-6` to feature
   - Remove `rank` to unfeature
4. Run scripts:

```bash
ruby scripts/sync_featured_articles.rb
ruby scripts/build_posts.rb
bash scripts/validate-and-sync.sh
```

5. Preview: `bundle exec jekyll serve --port 4000`
6. User commits: `git add _published-articles/ _posts/ _data/ && git commit -m "..."`

## Image Markdown

```markdown
CORRECT: ![Alt text](image-1.jpeg)
WRONG: ![Alt text](/assets/post-assets/2025/07/image-1.jpeg)
```

Jekyll plugin auto-converts simple names to full paths.

## Scripts

- `build_posts.rb`: Copy posts to `_posts/`, images to `_posts/YYYY/MM/`
- `sync_featured_articles.rb`: Sync `featured: X` from JSON to markdown
- `validate-and-sync.sh`: Validate, auto-add missing articles, sync images, rebuild posts

## Quick Tasks

- **Add article**: Create in `_published-articles/YYYY/MM/`, add images, run scripts
- **Feature**: Edit JSON, add `"rank": 1-6`, run sync script
- **Unfeature**: Edit JSON, remove `rank`, run sync script
- **Reorder**: Edit JSON, change ranks (1-6, unique), run sync script

## Avoid

- Editing `_posts/` (overwritten)
- Full paths in markdown
- Creating docs without asking
- Auto-committing
- Manual `featured:` edits
- Using emoticons anywhere in this repo
