require 'rubygems'

gem 'sinatra', '~> 0.3'
gem 'haml', '~> 2.0'

require 'sinatra'
require 'haml'

#require 'parse_tree'
#require 'ruby2ruby'
#require 'parse_tree_extensions'


__DIR__ = File.dirname(__FILE__)
require __DIR__+'/lib/dirdb/dirdb'
require 'ostruct'
require 'pp'

class Post < OpenStruct
  include DirDB::Resource
  
  glob '*.haml'
  
  index :by_slug do |post|
    post.slug
  end

  index :by_published_at do |post|
    post.published_at
  end
  
  lookup :slugs do |article|
    article.slug
  end
  
  def self.scan_file(path)
    info = {}
    IO.foreach(path) do |line|
      if line[/^\s*-#\s*([^:]*):\s*(.*)$/]
        info[$1.to_sym] = $2
      end
    end

    # info[:slug] = File.basename(path,'haml').sub(/^\d+_/,'').gsub('_',' ').gsub('.','')

    pt = info[:published_at] = if info[:published_at]
      DateTime.parse(info[:published_at])
    else
      File.ctime(path)
    end

    info[:url] = "/%04d/%02d/%s" % [ pt.year,pt.month,info[:slug] ]
    
    [info]
  end

  def self.grouped_by_month
    order = []
    months = {}

    all(:by_published_at).each do |post|
      key = post.published_at.strftime("%Y%m")
      unless months.key?(key)
        order << [post.published_at,key]
        months[key] = []
      end

      months[key] << post
    end

    [order,months]
  end
end

Post.path = __DIR__+'/posts'

# Add Ruby 1.9's xmlschema method
class Date
  def xmlschema
    strftime("%Y-%m-%dT%H:%M:%S%Z")
  end unless defined?(xmlschema)
end

helpers do
  include Haml::Helpers

  def partial(name,options={})
    haml(:"_#{name}", options.update(:layout => false))
  end

  def thrown_content
    @thrown_content ||= Hash.new {|h,k| h[k] = ''}
  end

  def throw_content(name,&block)
    thrown_content[name.to_sym] << capture_haml(&block)
  end

  def catch_content(name)
    thrown_content[name.to_sym]
  end

  def absoluteify_links(html)
    html.
      gsub(/href=(["'])(\/.*?)(["'])/, 'href=\1http://smartbomb.com.au\2\3').
      gsub(/src=(["'])(\/.*?)(["'])/, 'src=\1http://smartbomb.com.au\2\3')
  end
  def strip_tags(html)
    html.gsub(/<\/?[^>]*>/, "")
  end
  def post_html(post)
    haml(post.read, :layout => false)
  end

end

get '/' do
  @post = Post.all(:by_published_at).last
  @posts = Post.all.reverse[1..5]
  haml :index
end

get '/posts.atom' do
  content_type 'application/atom+xml'
  @posts = Post.all.reverse[0..15]
  haml :feed, :layout => false
end

get '/archives' do
  @months,@posts = Post.grouped_by_month
  haml :archive
end

get '/:year/:month/:day/:slug' do
  url = '/' + params.values_at(:year,:month,:slug).join('/')
  redirect url, 301
end

get '/:year/:month/:slug' do
  @post = Post.first(:slugs, params[:slug])
  haml :post
end

get '/:stylesheet.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass params[:stylesheet].to_sym
end
