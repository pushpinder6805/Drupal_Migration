Post.where("raw LIKE '%https://trackscommunity.com/uploads%'").find_each do |post|
  updated_raw = post.raw.gsub(
    %r{https://trackscommunity\.com/uploads},
    'https://track.thetechspectra.com/uploads'
  )

  if updated_raw != post.raw
    post.update!(raw: updated_raw)
    post.rebake!
    puts "✅ Updated post ##{post.id}"
  end
end
