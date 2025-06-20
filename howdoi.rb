# frozen_string_literal: true

require "mysql2"
require "htmlentities"
require "open-uri"
require "reverse_markdown"
require File.expand_path(File.dirname(__FILE__) + "/base.rb")

class ImportScripts::DrupalHowDoI < ImportScripts::Base
  DRUPAL_DB = ENV["DRUPAL_DB"] || "drupal"
  BATCH_SIZE = 100
  CATEGORY_ID = 10 # Change if needed

  def initialize
    super

    @htmlentities = HTMLEntities.new

    @client = Mysql2::Client.new(
      host: "68.169.58.111",
      username: "pushpinder",
      port: "3306",
      password: "discourse-future",
      database: DRUPAL_DB,
      encoding: "utf8"
    )
  end

  def execute
    import_how_do_i_articles
  end

  def import_how_do_i_articles
    how_do_i_nodes = mysql_query(<<~SQL)
      SELECT n.nid, n.title, b.body_value, n.uid, n.created
      FROM node n
      JOIN field_data_body b ON n.nid = b.entity_id
      WHERE n.type = 'how_do_i'
    SQL

    how_do_i_nodes.each do |node|
      user_id = user_id_from_imported_user_id(node["uid"]) || -1
      title = @htmlentities.decode(node["title"]).strip
      raw_html = node["body_value"].to_s

      raw_html = process_images(raw_html, user_id)
      markdown = ReverseMarkdown.convert(raw_html).strip

      if markdown.empty? || markdown.length < 10
        puts "Skipping node ##{node['nid']} - '#{title}' because the body is empty or too short."
        next
      end

      tags = [Tag.find_or_create_by(name: "how-do-i")]

      topic = Topic.create!(
        title: title,
        category_id: CATEGORY_ID,
        user_id: user_id,
        tags: tags
      )

     begin
  PostCreator.create!(
    Discourse.system_user,
    topic_id: topic.id,
    raw: markdown
  )
rescue => e
  puts "Failed to create post for node ##{node['nid']} - '#{title}': #{e.class} - #{e.message}"
end


      puts "Imported How Do I ##{node['nid']} - '#{title}' with tag 'how-do-i'"
    end
  end

  def process_images(html, user_id)
  doc = Nokogiri::HTML.fragment(html)
  doc.css("img").each do |img|
    src = img["src"]
    next unless src && src =~ /^https?:\/\//

    begin
      file = URI.open(src)
      filename = File.basename(URI.parse(src).path)
      tempfile = Tempfile.new(filename)
      tempfile.binmode
      tempfile.write(file.read)
      tempfile.rewind

      upload = UploadCreator.new(tempfile, filename).create_for(user_id)

      if upload&.persisted?
        img["src"] = upload.url
      else
        img.remove
      end
    rescue => e
      puts "Failed to upload image #{src}: #{e.message}"
      img.remove
    ensure
      tempfile.close! if tempfile
    end
  end
  doc.to_html
end


  def mysql_query(sql)
    @client.query(sql, cache_rows: true)
  end
end

ImportScripts::DrupalHowDoI.new.perform if __FILE__ == $0
