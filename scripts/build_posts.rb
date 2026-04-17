#!/usr/bin/env ruby

# Build script: Processes posts from _published-articles/ and generates them to _posts/
# Usage: ruby scripts/build_posts.rb

require 'fileutils'
require 'pathname'

SOURCE_DIR = '_published-articles'
TARGET_DIR = '_posts'

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

    # Copy the file (this preserves the original in _published-articles/)
    FileUtils.cp(source_file, target_file)
    puts "✓ Generated: #{target_file}"
  end

  puts "\nBuild complete! Generated #{posts.length} post(s)."
end

# Run the build
build_posts
