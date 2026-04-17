# Jekyll plugin to automatically convert post image references to full asset paths
# Converts: ![Alt](image-1.jpeg) -> ![Alt](/assets/post-assets/2025/12/image-1.jpeg)
# Based on the post's location in _posts/YYYY/MM/

module Jekyll
  class PostAssetUrlFilter
    def self.process_post_content(content, post)
      return content unless post.is_a?(Jekyll::Post)

      # Extract year and month from post path
      # Posts are at _posts/YYYY/MM/DD-title/
      post_dir = post.relative_path.split('/')[0..2].join('/')
      year_month = post_dir.split('/')[1..2].join('/')

      # Replace relative image references with full asset paths
      # Pattern: ![Alt](image-X.ext) but NOT: ![Alt](http...) or ![Alt](/...) or ![Alt]({{ ... }})
      content.gsub(/!\[([^\]]*)\]\((?!(?:https?:|\/|{{)[^\)]*\))([^)]+)\)/) do |match|
        alt_text = $1
        image_ref = $2

        # Only process simple filenames (image-1.jpeg, etc.)
        if image_ref.match?(/^[a-zA-Z0-9\-_.]+$/)
          "![#{alt_text}](/assets/post-assets/#{year_month}/#{image_ref})"
        else
          match # Return original if it doesn't match our pattern
        end
      end
    end
  end
end

# Hook into Jekyll's post processing
Jekyll::Hooks.register :posts, :post_init do |post|
  content = post.content
  post.content = Jekyll::PostAssetUrlFilter.process_post_content(content, post)
end
