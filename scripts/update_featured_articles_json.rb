#!/usr/bin/env ruby

# Script to update featured_articles.json with all articles from _published-articles/
# Adds missing articles without a rank property
# Preserves existing rank values for articles that already have them
# Usage: ruby scripts/update_featured_articles_json.rb

require 'json'
require 'pathname'

SOURCE_DIR = '_published-articles'
JSON_FILE = '_data/featured_articles.json'

def load_featured_config
  return { 'featured' => [] } unless File.exist?(JSON_FILE)
  JSON.parse(File.read(JSON_FILE))
rescue JSON::ParserError => e
  puts "ERROR: Invalid JSON in #{JSON_FILE}: #{e.message}"
  exit 1
end

def get_all_articles
  # Find all markdown files in nested structure (YYYY/MM/DD-title.md)
  articles = Dir.glob("#{SOURCE_DIR}/**/[0-9][0-9]-*.md").map do |file|
    # Normalize path for comparison
    File.expand_path(file)
  end.sort

  articles
end

def extract_date_from_path(file_path)
  # Extract YYYY/MM from path like _published-articles/2025/07/11-title.md
  parts = Pathname.new(file_path).each_filename.to_a
  return { year: parts[-3], month: parts[-2] } if parts.length >= 3
  nil
end

def update_featured_json
  config = load_featured_config
  all_articles = get_all_articles

  # Create a map of existing articles with their ranks
  existing_map = {}
  config['featured'].each do |entry|
    file_path = entry['file']
    existing_map[File.expand_path(file_path)] = entry['rank']
  end

  # Build new featured array
  new_featured = []
  all_articles.each do |article_path|
    entry = { 'file' => article_path.sub("#{Dir.pwd}/", '') }

    # Preserve existing rank if it exists
    if existing_map[article_path]
      entry['rank'] = existing_map[article_path]
    end
    # Otherwise, no rank property (user will assign later)

    new_featured << entry
  end

  # Update config
  config['featured'] = new_featured

  # Write back to JSON
  File.write(JSON_FILE, JSON.pretty_generate(config))

  puts "✓ Updated #{JSON_FILE}"
  puts "  Total articles: #{new_featured.length}"

  # Report articles with and without ranks
  with_rank = new_featured.select { |e| e['rank'] }.length
  without_rank = new_featured.length - with_rank

  puts "  With rank: #{with_rank}"
  puts "  Without rank (pending): #{without_rank}"

  if without_rank > 0
    puts "\n⚠ Unranked articles (assign rank 1-6 to feature):"
    new_featured.each do |entry|
      unless entry['rank']
        file = entry['file']
        puts "  - #{file}"
      end
    end
  end
end

# Run the update
update_featured_json
