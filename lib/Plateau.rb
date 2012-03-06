require 'mustache'
require 'maruku'
require 'yaml'
require 'rss/maker'


class Plateau

  def initialize

  end
  
  def init_dir(name="plateau")
    version = "0.0.2"
    @gem_path = Gem.path[0]+"/gems/plateau-"+version
    @resources_path = Gem.path[0]+"/gems/plateau-"+version+"/resources"
    system("tar -xzvf #{@resources_path}/Plateau.tar.gz")
    system("mv Plateau #{name}")
  end
  
  def build 
    inhale
    #...
    exhale
  end
  
  def load_templates
    #read templates
    Mustache.template_path = "./themes/#{@site_config['theme']}"
    @templates = {}
    Dir.glob("./themes/#{@site_config['theme']}/*.mustache").each { |file_path|
      filename = file_path.split('/').last.split('.mustache').first
      file = File.read(file_path)
      @templates[filename] = file
    }
  end
  
  def load_config
    @site_config =YAML::load( File.open("plateau.yml" ) )
  end
  
  def inhale
    load_config
    load_templates

    @time_start = Time.now


    #Read Pages
    puts "Reading Pages"
    @pages = []
    @page_dirs = Dir.glob("./content/pages/*")
    @page_dirs.each_index {|index|
      file_path = @page_dirs[index]
      post_name = file_path.split('/').last
      if post_name.include?(" ") then
        new_file_path = file_path.gsub(' ','_')
        puts file_path + " renamed to " + new_file_path
        system("mv '#{file_path}' #{new_file_path}")
        file_path = new_file_path
        post_name = post_name.gsub(" ","_")
      end
      extras = []
      Dir.glob("#{file_path}/*.js").each { |script| 
        script_string = %Q{<script type="text/javascript" src="#{script.split("/").last}" ></script>\n}
        extras << script_string
      }  
      Dir.glob("#{file_path}/*.css").each { |stylesheet| 
        style_string = %Q{<link rel="stylesheet" href="#{stylesheet.split("/").last}" >\n}
        extras << style_string
      }
      
      page_meta = {
        'title' => @site_config['title']
      }
      begin
        page_meta = YAML::load( File.open( "#{file_path}/meta.yml" ) )
        if page_meta['title'] then page_meta['title'] = "#{@site_config['title']} - #{page_meta['title']}" end
      rescue Exception => e
      end
      
      if File.exists? "#{file_path}/index.html" then
        post_markup = File.read("#{file_path}/index.html")
        mod_date    = File.ctime("#{file_path}/index.html")
      else
        begin
          markdown_file_path = Dir.glob("#{file_path}/*.md")[0]
          post_markdown = File.read(markdown_file_path)
          mod_date = File.ctime(markdown_file_path)
          mku = Maruku.new(post_markdown)
          post_markup = mku.to_html
        rescue Exception => e
          puts "No markdown or index.html file for #{post_name}"
          break
        end
      end

      post = {
        'markdown'    => post_markdown,
        'markup'      => post_markup,
        'path'        => "/#{post_name}/",
        'mod_date'    => mod_date,
        'extras'      => extras.join,
        'slug'        => post_name,
        'meta'        => page_meta
      }
      @pages << post
    }
    
    
    #Read Posts
    puts "Reading Posts"
    @posts = []
    @posts_by_tag = {}
    
    @post_dirs = Dir.glob("./content/posts/*")
    @post_dirs.each_index { |index|
      file_path = @post_dirs[index]
      post_name = file_path.split('/').last
      if post_name.include?(" ") then
        new_file_path = file_path.gsub(' ','_')
        puts file_path + " renamed to " + new_file_path
        system("mv '#{file_path}' #{new_file_path}")
        file_path = new_file_path
        post_name = post_name.gsub(" ","_")
      end
      post_meta = {}

      begin
        post_meta = YAML::load( File.open( "#{file_path}/meta.yml" ) )      
      rescue Exception => e
        puts "No post meta.yml (or malformed yaml) for #{post_name}"
        break
      end
      if post_meta['status'] != "published" then
        puts "Set #{post_name}'s status to 'published' in its meta.yml to publish it"
        break
      end
      if post_meta['date'].class != Time then 
        puts "#{post_name} needs a correctly formatted date (yyyy-mm-dd hh:mm:ss +0)" 
        break
      end
      if post_meta['title'] == nil then 
        puts "#{post_name} needs a title" 
        break
      end

      if post_meta['tags'].class == Array then
        tag_hashes = []
        post_meta['tags'].each {|tag|
          tag_hashes << {'tag' => tag, 'slug'=>tag.gsub(" ","_")}
        }
        post_meta['tags'] = tag_hashes
      else
        post_meta['tags'] = []
      end

      if File.exists? "#{file_path}/index.html" then
        post_markup = File.read("#{file_path}/index.html")
        mod_date    = File.ctime("#{file_path}/index.html")
      else
        begin
          markdown_file_path = Dir.glob("#{file_path}/*.md").delete_if{|x| x.match("lede")}[0]
          post_markdown = File.read(markdown_file_path)
          mod_date = File.ctime(markdown_file_path)
          mku = Maruku.new(post_markdown)
          post_markup = mku.to_html
        rescue Exception => e
          puts "No markdown or index.html file for #{post_name}"
          break
        end
      end
      
      if File.exists?("#{file_path}/lede.md") then
        post_lede_markdown = File.read("#{file_path}/lede.md")
      end
      
      extras = [];
      Dir.glob("#{file_path}/*.js").each { |script| 
        script_string = %Q{<script type="text/javascript" src="#{script.split("/").last}" ></script>\n}
        extras << script_string
      }  
      Dir.glob("#{file_path}/*.css").each { |stylesheet| 
        style_string = %Q{<link rel="stylesheet" href="#{stylesheet.split("/").last}" >\n}
        extras << style_string
      }
      post = post_meta.merge({
        'markdown'       => post_markdown,
        'markup'         => post_markup,
        'lede_markdown'  => post_lede_markdown,
        'mod_date'       => mod_date,
        'slug'           => post_name,
        'path'           => "/posts/#{post_name}/",
        'extras'         => extras.join,
        'date_string'    => post_meta['date'].strftime("%Y/%m/%d"),
        'date'           => post_meta['date'],
        'date_object'    => {
          'Y' => post_meta['date'].strftime("%Y"),
          'F' => post_meta['date'].strftime("%F"),
          'H' => post_meta['date'].strftime("%H"),
          'T' => post_meta['date'].strftime("%T"),
          'm' => post_meta['date'].strftime("%m"),
          'B' => post_meta['date'].strftime("%B"),
          'b' => post_meta['date'].strftime("%b"),
          'd' => post_meta['date'].strftime("%d"),
          'e' => post_meta['date'].strftime("%e"),
          'j' => post_meta['date'].strftime("%j"),
          'k' => post_meta['date'].strftime("%k"),
          'M' => post_meta['date'].strftime("%M"),
          'S' => post_meta['date'].strftime("%S"),
          'z' => post_meta['date'].strftime("%z"),
          'Z' => post_meta['date'].strftime("%Z"),
          'A' => post_meta['date'].strftime("%A"),
          'a' => post_meta['date'].strftime("%a"),
          'w' => post_meta['date'].strftime("%w"),
          'u' => post_meta['date'].strftime("%u")
        }
      })
      post_meta['tags'].each { |tag| 
        t = tag['tag']
        @posts_by_tag[t] = [] unless @posts_by_tag.has_key?(t)
        @posts_by_tag[t] << post
      }
      @posts << post
    }
    # @posts.sort_by!{ |post| post['date'] }.reverse!
    @posts.sort! {|x,y| y['date'] <=> x['date'] }#.reverse!
  end
  
  def exhale
    
    #Setup directories
    system("rm -Rf ./site_build")
    Dir.mkdir("./site_build/")
    Dir.mkdir("./site_build/posts")
    Dir.mkdir("./site_build/frontend")
    
    
    #Copy Frontend Resources
    Dir.glob("./themes/#{@site_config['theme']}/*.{jpg,gif,png,mov,m4v,swf,svg,css,js,mpg,flv,mpeg,jpeg,wmv,wma,zip,tar,gz}") {|file|
      file_name = file.split("/").last
      system("cp #{file} ./site_build/frontend/#{file_name}")
    }
    
    
    #Write Pages
    @pages.each_index { |index| 
      puts "Rendering page #{index+1} of #{@pages.length}"
      page = @pages[index]
      Dir.mkdir("./site_build/#{page['slug']}")
      page_html = Mustache.render(@templates['main'],{:page_content=>page['markup'],:section=>page['slug'],:extras=>page['extras']}.merge(@site_config).merge(page['meta']))
      page_html = make_resources_absolute(page_html,"../")
      File.open("./site_build/#{page['slug']}/index.html", 'w') {|f| f.write(page_html) }
      copy_support_files("./content/pages/#{page['slug']}/","./site_build/#{page['slug']}")
    }


    #Write Posts
    @posts.each_index { |index|
      puts "Rendering post #{index+1} of #{@posts.length}"
      post = @posts[index]
      Dir.mkdir("./site_build/posts/#{post['slug']}")
      if post['lede_markdown'] then post['lede'] = Maruku.new(post['lede_markdown']).to_html end
      post_inner_html = Mustache.render(@templates['post'],post)
      page_html = Mustache.render(@templates['main'],@site_config.merge({
        :page_content => post_inner_html,
        :section =>'posts',
        :title => (@site_config['title'] + " - " + post['title'])
      }))
      page_html = make_resources_absolute(page_html,"../../")
      File.open("./site_build/posts/#{post['slug']}/index.html", 'w') {|f| f.write(page_html) }
      copy_support_files("./content/posts/#{post['slug']}","./site_build/posts/#{post['slug']}")
    }
    
    
    #Write Post Pages
    post_pages = [[]]
    current_post_count = 0
    current_page = 0
    @posts.each {|post|
      current_post_count = current_post_count + 1
      post_pages[current_page] << post.clone
      if current_post_count == @site_config['posts_per_page']  
        current_post_count = 0
        post_pages << []
        current_page=current_page+1
      end
    }
    post_pages.delete_if{|x|x==[]}
    post_pages.each_index{|index|
        puts "Rendering blog page #{index+1} of #{post_pages.length}"
        posts = post_pages[index]
        posts.each{ |post|
          post['extras'] = make_links_absolute(post['extras'],"../posts/#{post['slug']}/")        
          post['markup'] = make_links_absolute(post['markup'],"../posts/#{post['slug']}/")
        }
        unless index == post_pages.length-1 then nxt = index+1 end
        unless index == 0 then prv = index-1 end
        if index == 1 then
          prev_page_url = "/posts"
        else
          prev_page_url = "/posts/#{prv}"
        end
        posts_html = Mustache.render(@templates['posts'],{
          :posts=>posts,
          :current_page=>index,
          :next=>nxt,
          :next_page_url=>"/posts/#{nxt}",
          :prev=>prv,
          :prev_page_url=>prev_page_url
        })
        post_page_html = Mustache.render(@templates['main'],{:page_content=>posts_html,:section=>'posts'}.merge(@site_config))

        if index == 0 then 
          filename = "./site_build/posts/index.html" 
          path_to_root = "../"
        else
          Dir.mkdir("./site_build/posts/#{index}")    
          filename = "./site_build/posts/#{index}/index.html" 
          path_to_root = "../../"
        end
        post_page_html = make_resources_absolute(post_page_html,path_to_root)
        File.open(filename, 'w') {|f| f.write(post_page_html) }
    }
     

    #Write Post Index
    puts "Rendering post index"
    Dir.mkdir("./site_build/posts/archive")
    posts_index_html = Mustache.render(@templates['posts_index'],{
      :posts => @posts
    })
    html = Mustache.render(@templates['main'],{:page_content=>posts_index_html,:section=>'posts'}.merge(@site_config))
    html = make_resources_absolute(html,"../../")
    File.open("./site_build/posts/archive/index.html", 'w') {|f| f.write(html) }
  
  
    #Copy root files
    Dir.glob("./content/*.{jpg,gif,png,mov,m4v,swf,svg,css,js,mpg,flv,mpeg,jpeg,wmv,wma,zip,tar,gz}").each{|f|
      system("cp '#{f}' './site_build/#{f.split('/').last}'")
    }
  
  
    #Write Tag Pages
    puts "Rendering tag indexes"
    Dir.mkdir("./site_build/posts/tagged")
    @posts_by_tag.each_key { |tag|
      post_array = @posts_by_tag[tag]
      tag_slug   = tag.gsub(" ","_")
      Dir.mkdir("./site_build/posts/tagged/#{tag_slug}")
      tags_page_html = Mustache.render(@templates['posts_tagged'],{
        :posts => post_array,
        :tag => tag
      })
      html = Mustache.render(@templates['main'],{:page_content=>tags_page_html,:section=>'posts'}.merge(@site_config))
      html = make_resources_absolute(html,"../../../")
      File.open("./site_build/posts/tagged/#{tag_slug}/index.html", 'w') {|f| f.write(html) }
    }
    
    
    #Write Home Page
    begin
      home_page_html = File.read("./site_build/#{@site_config['home_page']}/index.html")  
      home_page_html = make_links_absolute(home_page_html,"#{@site_config['home_page']}/")
      home_page_html.gsub!("../","")
      File.open("./site_build/index.html", 'w') { |f| f.write(home_page_html) }
    rescue Exception => e
      puts "Could not write home page, sure /@site_config['home_page']/ exists?"
    end


    #Write sitemap.xml
    puts "Rendering Sitemap.xml"
    sitemap = ""
    sitemap << "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    sitemap << "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n"
    @pages.each {|p|
      sitemap << "<url>\n<loc>#{@site_config['url']}#{p['path']}</loc>\n<lastmod>#{p['mod_date'].strftime("%Y-%m-%d")}</lastmod>\n</url>\n"
    }
    @posts.each {|p|
      sitemap << "<url>\n<loc>#{@site_config['url']}#{p['path']}</loc>\n<lastmod>#{p['mod_date'].strftime("%Y-%m-%d")}</lastmod>\n</url>\n"
    }
    sitemap << "</urlset>"
    File.open("./site_build/sitemap.xml","w") do |f|
      f.write(sitemap)
    end
    
    #Write RSS
    puts "Writing RSS"
    rss = ""
    rss << %Q{<?xml version="1.0" encoding="UTF-8"?>\n}
    rss << %Q{<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">\n}
    rss << "<channel>\n"
    rss << "<title>#{@site_config['title']}</title>\n"
    rss << "<link>#{@site_config['url']}</link>\n"
    rss << %Q{<atom:link href="#{@site_config['url']}/rss.xml" rel="self" type="application/rss+xml" />\n}
    rss << "<description>#{@site_config['description']}</description>\n"
    @posts.each {|p|
      rss << "<item>\n"
      rss << "<title>#{p['title']}</title>\n"
      rss << "<link>#{@site_config['url']}#{p['path']}</link>\n"
      rss << "<guid>#{@site_config['url']}#{p['path']}</guid>\n"
      rss << "<pubDate>#{p['date'].strftime("%a, %d %b %Y %H:%M:%S %Z")}</pubDate>\n"
          if p['lede'] then
            puts "rss item has lede"
            description = p['lede']
          else
            description = p['markup']
          end
      rss << "<description><![CDATA[\n#{make_links_absolute(description,@site_config['url']+p['path'])}]]></description>\n"
      rss << "</item>\n"      
    }
    rss << "</channel>\n"
    rss << "</rss>"
    File.open("./site_build/rss.xml","w") do |f|
      f.write(rss)
    end    

    system("rm -Rf ./site")      
    system("mv site_build site") 
    
    build_time = Time.now - @time_start
    puts "Built in #{build_time} seconds"
    
  end
  
  def make_preview
    post_dir = Dir.getwd
    Dir.chdir("../")
    post_type =  Dir.getwd.split("/").last
    Dir.chdir("../../")
    load_config
    load_templates
    Dir.chdir(post_dir)
    markdown_file_path = Dir.glob("./*.md").delete_if{|x| x.match("lede")}[0]
    post_markdown = File.read(markdown_file_path)
    mku = Maruku.new(post_markdown)
    post_markup = mku.to_html
    extras = [];
    Dir.glob("./*.js").each { |script| 
      script_string = %Q{<script type="text/javascript" src="#{script.split("/").last}" ></script>\n}
      extras << script_string
    }  
    Dir.glob("./*.css").each { |stylesheet| 
      style_string = %Q{<link rel="stylesheet" href="#{stylesheet.split("/").last}" >\n}
      extras << style_string
    }
    if post_type == "pages" then 
      page_html = Mustache.render(@templates['main'],{
        :page_content => post_markup,
        :extras       => extras.join("")
      }.merge(@site_config))
    end
    if post_type == "posts" then 
      post_meta = {}
      begin
        post_meta = YAML::load( File.open( "meta.yml" ) )      
      rescue Exception => e
        puts "No post meta.yml (or malformed yaml)"
        return false
      end
      if post_meta['date'].class != Time then 
        puts "Post needs a correctly formatted date (yyyy-mm-dd hh:mm:ss +0)"
        return false
      end
      if post_meta['title'] == nil then 
        puts "Post needs a title" 
        return false
      end
      page_inner_html = Mustache.render(@templates['post'],{
        :markup => post_markup,
        :extras => extras.join("")
      }.merge(post_meta))
      page_html = Mustache.render(@templates['main'],{:page_content=>page_inner_html}.merge(@site_config))
    end
    page_html = page_html.gsub(/frontend\//){|src| 
      src = "../../../themes/#{@site_config['theme']}/"
      src
    }
    File.open("./preview.html", 'w') {|f| f.write(page_html) }
    puts "Rendered preview.html"
  end
  
  def copy_support_files(path_from,path_to)
    Dir.glob("#{path_from}/*.{jpg,gif,png,mov,m4v,swf,svg,css,js,mpg,flv,mpeg,jpeg,wmv,wma,zip,tar,gz}").each { |file| 
      file_name = file.split("/").last
      system("cp #{file} #{path_to}/#{file_name}")
    }
  end
  
  def make_links_absolute(html,path)
    abs_html = html.gsub(/src=.+ /){|src| 
      unless src.index('http') == 5 || src.index('/') == 5 then src.insert(5,path) end
      src
    }
    abs_html = abs_html.gsub(/href=.+ /){|src| 
      unless src.index('http') == 6 || src.index('/') == 6 || src.index('#') == 6 then src.insert(6,path) end
      src
    }
    return abs_html
  end
  
  def make_resources_absolute(html,path_to_root="/")
    absolute_html = html.gsub(/frontend\//){|src| 
      src = path_to_root+src
      src
    }
    return absolute_html
  end
  

end