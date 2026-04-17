#!/usr/bin/env ruby

# Sync script: Updates featured values in markdown files based on _data/featured_articles.json
# Usage: ruby scripts/sync_featured_articles.rb

require 'json'
require 'fileutils'

SOURCE_DIR = '_published-articles'
JSON_FILE = '_data/featured_articles.json'

def load_featured_config
  return {} unless File.exist?(JSON_FILE)
  JSON.parse(File.read(JSON_FILE))
rescue JSON::ParserError => e
  puts "ERROR: Invalid JSON in #{JSON_FILE}: #{e.message}"
  exit 1
end

def update_featured_in_file(file_path, rank)
  content = File.read(file_path)

  # Check if featured field exists in frontmatter
  if content.match?(/^---.*?^featured:/m)
    # Replace existing featured value
    updated = content.gsub(/^featured:\s*\d+/, "featured: #{rank}")
    File.write(file_path, updated)
    puts "✓ Updated: #{file_path} → featured: #{rank}"
  elsif content.match?(/^---/)
    # Add featured field before closing --- if it doesn't exist
    # Find the position of the closing ---
    match = content.match(/^---\n(.*?)\n---/m)
    if match
      frontmatter = match[1]
      rest = content[(match.offset(0)[1])..-1]

      # Only add if not already present
      unless frontmatter.include?('featured:')
        new_frontmatter = "#{frontmatter}\nfeatured: #{rank}"
        updated = "---\n#{new_frontmatter}\n#{rest}"
        File.write(file_path, updated)
        puts "✓ Added: #{file_path} → featured: #{rank}"
      end
    end
  else
    puts "⚠ Skipped: #{file_path} (no valid frontmatter found)"
  end
end

def remove_featured_from_file(file_path)
  content = File.read(file_path)

  # Only remove if featured field exists
  if content.match?(/^---.*?^featured:/m)
    updated = content.gsub(/^featured:\s*\d+\n/, '')
    File.write(file_path, updated)
    puts "✓ Removed: #{file_path} (featured field)"
  end
end

def sync_featured
  config = load_featured_config

  unless config['featured'].is_a?(Array)
    puts "ERROR: featured_articles.json must contain a 'featured' array"
    exit 1
  end

  featured_files = config['featured'].map { |entry| entry['file'] }
  featured_ranks = config['featured'].each_with_object({}) { |entry, h| h[entry['file']] = entry['rank'] }

  puts "Syncing featured articles from #{JSON_FILE}..."

  # Find all markdown files in _published-articles
  all_files = Dir.glob("#{SOURCE_DIR}/**/[0-9][0-9]-*.md")

  # Update files that are in the featured list
  featured_files.each do |file_path|
    if File.exist?(file_path)
      rank = featured_ranks[file_path]
      update_featured_in_file(file_path, rank)
    else
      puts "⚠ Warning: Featured file not found: #{file_path}"
    end
  end

  # Remove featured field from files that are NOT in the featured list
  all_files.each do |file_path|
    unless featured_files.include?(file_path)
      if File.read(file_path).match?(/^---.*?^featured:/m)
        remove_featured_from_file(file_path)
      end
    end
  end

  puts "\nSync complete!"
end

# Run the sync
sync_featured
