# Jekyll plugin to automatically convert post image references to full asset paths
# Converts: ![Alt](image-1.jpeg) -> ![Alt](/assets/post-assets/2025/12/image-1.jpeg)
# Finds the image folder by extracting date from post's date attribute

module Jekyll
  class PostAssetUrlGenerator
    def self.process_post_content(content, post)
      # Extract year and month from post's date
      return content unless post.date

      year = post.date.strftime('%Y')
      month = post.date.strftime('%m')

      # Replace image references: ![Alt](image.ext) -> ![Alt](/assets/post-assets/YYYY/MM/image.ext)
      # But only if they're simple filenames (not URLs or Liquid syntax)
      content.gsub(/!\[([^\]]*)\]\(([^)]+)\)/) do |match|
        alt_text = $1
        image_ref = $2

        # Skip if already a full path, URL, or Liquid syntax
        if image_ref.start_with?('/') || image_ref.include?('http') || image_ref.include?('{{') || image_ref.include?('}}')
          match
        # Process simple filenames (image-1.jpeg, cover.jpg, etc.)
        elsif image_ref.match?(/^[a-zA-Z0-9\-_.]+$/)
          "![#{alt_text}](/assets/post-assets/#{year}/#{month}/#{image_ref})"
        else
          match
        end
      end
    end
  end
end

# Hook into Jekyll's post processing
Jekyll::Hooks.register :posts, :pre_render do |post|
  post.content = Jekyll::PostAssetUrlGenerator.process_post_content(post.content, post)
end
