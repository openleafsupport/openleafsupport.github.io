#!/usr/bin/env ruby

# Build script: Processes posts and images from _published-articles/ and generates them to _posts/
# Usage: ruby scripts/build_posts.rb

require 'fileutils'
require 'pathname'

SOURCE_DIR = '_published-articles'
TARGET_DIR = '_posts'
IMAGE_EXTENSIONS = %w[.jpg .jpeg .png .webp .gif .svg]

def build_posts
  puts "Building posts from #{SOURCE_DIR}/ to #{TARGET_DIR}/..."

  # Find all markdown files in _published-articles with nested structure (YYYY/MM/DD-title.md)
  posts = Dir.glob("#{SOURCE_DIR}/**/[0-9][0-9]-*.md")

  if posts.empty?
    puts "No posts found in #{SOURCE_DIR}/"
    return
  end

  posts.each do |source_file|
    # Extract date components from the file path (e.g., _published-articles/2025/12/31-title.md)
    path_parts = Pathname.new(source_file).each_filename.to_a

    # Reconstruct: _published-articles/YYYY/MM/DD-title.md
    next unless path_parts.length >= 4

    year = path_parts[-3]
    month = path_parts[-2]
    filename = path_parts[-1]

    # Validate date format (YYYY should be 4 digits, MM should be 2 digits)
    next unless year.match?(/^\d{4}$/) && month.match?(/^\d{2}$/)

    # Create target filename: YYYY-MM-DD-title.md
    target_filename = "#{year}-#{month}-#{filename}"
    target_file = File.join(TARGET_DIR, target_filename)

    # Ensure target directory exists
    FileUtils.mkdir_p(TARGET_DIR)

    # Copy the markdown file (this preserves the original in _published-articles/)
    FileUtils.cp(source_file, target_file)
    puts "✓ Generated: #{target_file}"
  end

  # Copy images from _published-articles/YYYY/MM/ to _posts/YYYY/MM/
  copy_images

  puts "\nBuild complete! Generated #{posts.length} post(s)."
end

def copy_images
  puts "\nCopying images from #{SOURCE_DIR}/ to #{TARGET_DIR}/..."

  # Find all image files in _published-articles with nested structure (YYYY/MM/image.ext)
  images = Dir.glob("#{SOURCE_DIR}/**/*").select do |f|
    File.file?(f) && IMAGE_EXTENSIONS.include?(File.extname(f).downcase)
  end

  if images.empty?
    puts "No images found in #{SOURCE_DIR}/"
    return
  end

  images.each do |source_image|
    # Extract relative path from _published-articles
    # _published-articles/2025/07/image-1.png -> 2025/07/image-1.png
    relative_path = source_image.sub(/^#{Regexp.escape(SOURCE_DIR)}\//, '')
    target_image = File.join(TARGET_DIR, relative_path)
    target_dir = File.dirname(target_image)

    # Create target directory
    FileUtils.mkdir_p(target_dir)

    # Copy the image
    FileUtils.cp(source_image, target_image)
    puts "✓ Copied: #{target_image}"
  end

  puts "✓ Image copy complete! #{images.length} image(s) copied."
end

# Run the build
build_posts
