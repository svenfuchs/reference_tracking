module ReferenceTracking
  class References < Array
    def initialize(object, methods)
      Tracker.setup(object, self, methods)
    end

    def tags
      map { |object, method| "#{object.class.name.underscore}-#{object.id}" }.uniq
    end
  end
end