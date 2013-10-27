require_relative "zapt/version"
require_relative "zapt/delegator"
require_relative "zapt/logger"
require_relative "zapt/user"
require_relative "zapt/etc"

# top level require puts the DSL methods into main scope
include Zapt::Delegator

at_exit { $logger.info('...tasks have been Zapt') }
