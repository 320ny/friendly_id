module FriendlyId::SluggableClassMethods

  def self.extended(base)

    class << base
      alias_method_chain :find_one, :friendly
      alias_method_chain :find_some, :friendly
      alias_method_chain :validate_find_options, :friendly
    end

  end

  # Finds a single record using the friendly_id, or the record's id.
  def find_one_with_friendly(id_or_name, options)
    
    scope = options.delete(:scope)
    return find_one_without_friendly(id_or_name, options) if id_or_name.is_a?(Fixnum)

    find_options = {:select => "#{self.table_name}.*"}
    find_options[:joins] = :slugs unless options[:include] && [*options[:include]].flatten.include?(:slugs)

    name, sequence = Slug.parse(id_or_name)

    find_options[:conditions] = {
      "#{Slug.table_name}.name"     => name,
      "#{Slug.table_name}.scope"    => scope,
      "#{Slug.table_name}.sequence" => sequence
    }

    result = with_scope(:find => find_options) { find_initial(options) }

    if result
      result.finder_slug_name = id_or_name
    else
      result = find_one_without_friendly id_or_name, options
    end

    result

  end

  # Finds multiple records using the friendly_ids, or the records' ids.
  def find_some_with_friendly(ids_and_names, options)
    
    scope = options.delete(:scope)
    slugs = []
    ids = []
    ids_and_names.each do |id_or_name|
      name, sequence = Slug.parse id_or_name
      slug = Slug.find(:first, :readonly => true, :conditions => {
        :name           => name,
        :scope          => scope,
        :sequence       => sequence,
        :sluggable_type => base_class.name
      })
      # If the slug was found, add it to the array for later use. If not, and
      # the id_or_name is a number, assume that it is a regular record id.
      slug ? slugs << slug : (ids << id_or_name if id_or_name =~ /\A\d*\z/)
    end
    
    results = []
     
    find_options = {:select => "#{self.table_name}.*"}
    find_options[:joins] = :slugs unless options[:include] && [*options[:include]].flatten.include?(:slugs)
    find_options[:conditions] = "#{quoted_table_name}.#{primary_key} IN (#{ids.empty? ? 'NULL' : ids.join(',')}) "
    find_options[:conditions] << "OR #{Slug.quoted_table_name}.#{Slug.primary_key} IN (#{slugs.to_s(:db)})"

    results = with_scope(:find => find_options) { find_every(options) }
    
    # calculate expected size, taken from active_record/base.rb
    expected_size = options[:offset] ? ids_and_names.size - options[:offset] : ids_and_names.size
    expected_size = options[:limit] if options[:limit] && expected_size > options[:limit]
    
    if results.size != expected_size
      raise ActiveRecord::RecordNotFound, "Couldn't find all #{ name.pluralize } with IDs (#{ ids_and_names * ', ' }) AND #{ sanitize_sql options[:conditions] } (found #{ results.size } results, but was looking for #{ expected_size })"
    end

    # assign finder slugs
    slugs.each do |slug|
      results.select { |r| r.id == slug.sluggable_id }.each do |result|
        result.send(:finder_slug=, slug)
      end
    end
    results
  end

  def validate_find_options_with_friendly(options) #:nodoc:
    options.assert_valid_keys([:conditions, :include, :joins, :limit, :offset,
      :order, :select, :readonly, :group, :from, :lock, :having, :scope])
  end

end
