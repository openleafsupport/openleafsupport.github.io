# Jekyll Plugins

## Post Asset URLs Plugin

Automatically converts simplified post image references to full asset paths during Jekyll build.

### Purpose

Simplifies markdown syntax for images in blog posts by automatically resolving relative image references to their full paths based on the post's location.

### How It Works

**Without Plugin** (verbose):
```markdown
![Alt text]({{ '/assets/post-assets/2025/12/image-1.jpeg' | relative_url }})
```

**With Plugin** (simplified):
```markdown
![Alt text](image-1.jpeg)
```

### Requirements

- Post structure: `_posts/YYYY/MM/DD-title.md`
- Images stored in same folder as markdown: `_posts/YYYY/MM/image-1.jpeg`
- Jekyll will sync images to: `assets/post-assets/YYYY/MM/image-1.jpeg`

### Plugin Logic

The plugin:
1. Extracts the year and month from the post's file path
2. Finds all image references using the pattern `![Alt](image.ext)`
3. Converts them to full paths: `![Alt](/assets/post-assets/YYYY/MM/image.ext)`
4. Ignores URLs (http://, https://, data:, mailto:, #) and Jekyll Liquid filters

### Validation

The validation script (`scripts/validate_blog.sh`) recognizes both formats:
- **Full paths**: `/assets/post-assets/YYYY/MM/image.ext` (verified to exist)
- **Simplified paths**: `image.ext` (verified to exist in post folder, will be auto-resolved)

### Example

Post at: `_posts/2025/12/31-My-Post.md`
With image: `_posts/2025/12/image-1.jpeg`

Markdown:
```markdown
![My image](image-1.jpeg)
```

Build output becomes:
```markdown
![My image](/assets/post-assets/2025/12/image-1.jpeg)
```

### Files

- `post_asset_urls.rb` - Jekyll plugin that processes post content during build
