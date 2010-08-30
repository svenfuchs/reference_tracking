module ReferenceTracking
  class References < Array
    def initialize(object, methods)
      Tracker.setup(object, self, methods)
    end

    def tags
      map do |object, method| 
        "#{object.class.name.underscore}-#{object.id}#{":#{method}" if method}"
      end.uniq
    end
  end
end