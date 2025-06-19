require 'open-uri'
require 'fileutils'

image_links.each do |entry|
  url = entry[:url]
  filename = File.basename(URI.parse(url).path)
  local_path = "public/uploads/imported_images/#{filename}"

  begin
    FileUtils.mkdir_p("public/uploads/imported_images/")
    URI.open(url) do |image|
      File.open(local_path, "wb") { |f| f.write(image.read) }
    end

    entry[:new_url] = "/uploads/imported_images/#{filename}"
    puts "Downloaded #{url} => #{entry[:new_url]}"
  rescue => e
    puts "Failed to download #{url}: #{e.message}"
  end
end
