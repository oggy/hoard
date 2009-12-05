require 'hoard/base'

module Hoard
  class << self
    def init(*args)
      (0..2).include?(args.length) or
        raise ArgumentError, "wrong number of arguments (#{args.length} for 0..2)"
      options = args.last.is_a?(Hash) ? args.pop : {}
      @hoard = type_to_class(args.first || :base).new(options)
    end

    attr_accessor :hoard

    private  # -------------------------------------------------------

    def type_to_class(type)
      type = type.to_s
      name = type.gsub(/(?:_|\A)(.)/){$1.capitalize}
      const_get(name)
    end
  end
end
