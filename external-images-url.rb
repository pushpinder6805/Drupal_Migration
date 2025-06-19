image_links = []

Post.where("raw LIKE '%![](%'").find_each do |post|
  post.raw.scan(/!\[.*?\]\((https?:\/\/[^\)]+)\)/).flatten.each do |url|
    image_links << { post_id: post.id, url: url }
  end
end
