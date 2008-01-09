namespace :friendly_id do
  desc "Make slugs for a particular model."
  task :make_slugs => :environment do
    raise 'USAGE: rake friendly_id:make_slugs MODEL=MyModelName' if ENV["MODEL"].nil?
    klass = Object.const_get(ENV["MODEL"])
    if !klass.respond_to? :find_using_friendly_id
      raise "Class \"#{klass.to_s}\" doesn't appear to be using slugs"
    end
    records = klass.find(:all, :include => :slugs, :conditions => "slugs.id IS NULL")
    records.each do |r|
      r.set_slug
      r.save!
      puts "#{klass.to_s}(#{r.id}) friendly_id set to \"#{r.slug.name}\""
    end
  end
  
  desc "Kill obsolete slugs older than 45 days."
  task :remove_old_slugs => :environment do
    if ENV["DAYS"].nil?
      @days = 45
    else
      @days = ENV["DAYS"].to_i
    end
    slugs = Slug.find(:all, :conditions => ["created_at < ?", DateTime.now - @days.days])
    slugs.each do |s|
      s.destroy if !s.is_most_recent?
    end
  end
end