require 'open-uri'
require 'fileutils'

BASE_DIR = Rails.root.join("public", "uploads", "imported_images")
BASE_URL = "/uploads/imported_images"

FileUtils.mkdir_p(BASE_DIR)

Post.where("raw LIKE '%![](%'").find_each do |post|
  modified = false
  updated_raw = post.raw.gsub(/!\[(.*?)\]\((https?:\/\/[^\s)]+)\)/) do |match|
    alt_text = Regexp.last_match(1)
    old_url = Regexp.last_match(2)

    begin
      uri = URI.parse(old_url)
      ext = File.extname(uri.path)
      basename = File.basename(uri.path, ext)
      filename = "#{basename}_#{post.id}#{ext}"
      filepath = BASE_DIR.join(filename)

      unless File.exist?(filepath)
        puts "Downloading #{old_url} → #{filepath}"
        URI.open(old_url, "rb") do |image_data|
          File.open(filepath, "wb") { |f| f.write(image_data.read) }
        end
      end

      new_url = "#{BASE_URL}/#{filename}"
      modified = true
      "![#{alt_text}](#{new_url})"
    rescue => e
      puts "⚠️ Failed to download #{old_url}: #{e.message}"
      match # leave original unchanged
    end
  end

  if modified
    post.update!(raw: updated_raw)
    post.rebake!
    puts "✅ Updated post ##{post.id}"
  end
end
