# OpenLeaf

Thoughts on reading, attention, and deliberate living.

**OpenLeaf** is a free, ad-free, local-first reading app inspired by Project Gutenberg and built for people who want to read deeply in a distracted age.

## Site

This repository powers [openleafsupport.github.io](https://openleafsupport.github.io) — the public home for OpenLeaf essays, product updates, and the ideas behind the app.

Built with [Jekyll](https://jekyllrb.com/) and hosted on GitHub Pages.

## Running locally

```bash
bundle install
bundle exec jekyll serve
```

Then visit `http://localhost:4000`.

## Writing posts with local images

OpenLeaf supports post folders inside `_posts/` so each writing can keep its markdown and images together.

Example structure:

```text
_posts/2026-05-01-my-new-post/
_posts/2026-05-01-my-new-post/2026-05-01-my-new-post.md
_posts/2026-05-01-my-new-post/image.png
_posts/2026-05-01-my-new-post/quote-card.jpg
```

### Required front matter

- Add an explicit category from the approved list:
  - `Reflections`
  - `Book Reviews`
  - `Updates`
  - `Announcements`
- Use a relative cover image when the cover lives in the same post folder:

```yaml
categories:
  - Reflections
cover_image: "image.png"
```

### Inline images inside the post body

Use the published `/_posts/...` path with `relative_url`:

```md
![Quote card]({{ '/_posts/2026-05-01-my-new-post/quote-card.jpg' | relative_url }})
```

Do not use a plain relative markdown image path like `![Alt](quote-card.jpg)`.

### Sync and validate before commit

Run:

```bash
./scripts/sync_post_assets.sh
```

This script will:

- regenerate the `_config.yml` post asset `include:` block
- validate that every post has an explicit approved category
- validate `cover_image` paths
- validate inline image references

If the script exits with an error, fix the reported post before committing.

If `jekyll serve` is already running, restart it after this script finishes. Jekyll does not hot-reload `_config.yml`, so post-local images will stay broken until the server is restarted.

## Contact

<openleaf.support@gmail.com>
