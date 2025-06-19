Post.where("raw LIKE '%![](/uploads/imported_images/%'").find_each do |post|
  updated_raw = post.raw.gsub(
    %r{!\[(.*?)\]\(/uploads/imported_images/([^\)]+)\)},
    '![\1](https://track.thetechspectra.com/uploads/imported_images/\2)'
  )

  if updated_raw != post.raw
    post.update!(raw: updated_raw)
    post.rebake!
    puts "✅ Updated post ##{post.id}"
  end
end
