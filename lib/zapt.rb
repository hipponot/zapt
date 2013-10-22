require_relative "zapt/version"
require_relative "zapt/delegator"
require_relative "zapt/logger"

# top level require puts the DSL methods into main scope
include Zapt::Delegator
