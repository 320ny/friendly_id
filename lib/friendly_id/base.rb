module FriendlyId
  # Class methods that will be added to ActiveRecord::Base.
  module Base

    def friendly_id(*args)
      base    = args.shift
      options = args.extract_options!
      @friendly_id_config.use options.delete :use
      @friendly_id_config.set options.merge :base => base
      before_save do |record|
        record.instance_eval {@current_friendly_id = friendly_id}
      end
      include Model
    end

    def friendly_id_config
      @friendly_id_config
    end
  end
end
