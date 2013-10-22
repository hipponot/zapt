require_relative 'tasks'
module Zapt

  # including this module monkeypatches main to delegate like
  # named methods to Application
  module Delegator
    # Generate delegate methods
    instance_methods = Tasks.instance_methods
    methods = instance_methods.map{ |m| Tasks.instance_method(m)}.select{|m| m.owner == Zapt::Tasks}
    methods.each do |m|
      define_method(m.name) do |*args, &block|
        Delegator.target.send(m.name, *args, &block)
      end
    end

    private

    class << self
      attr_accessor :target
    end
    self.target = Tasks.new
  end
end
