module ReferenceTracking
  class IvarProxy
    instance_methods.each { |m| undef_method(m) unless %w(__send__ __id__ inspect).include?(m) }

    def initialize(owner, name, object, references)
      @owner      = owner
      @name       = name
      @object     = object
      @references = references
    end

    def respond_to?(method)
      @object.respond_to?(method)
    end

    def method_missing(method, *args, &block)
      respond_to?(method) ? __track__(method, *args, &block) : super
    end

    def __track__(method, *args, &block)
      @references << [@object, nil]
      @owner.instance_variable_set(@name, @object)
      @object.send(method, *args, &block)
    end
  end
end