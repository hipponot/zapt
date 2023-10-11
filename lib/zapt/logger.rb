require "logger"
require "colored"
class Logger
  attr_accessor :disabled
end
$logger = Logger.new(STDOUT)
$logger.level = Logger::INFO

$logger.formatter = proc{ |level, datetime, progname, msg|
  unless $logger.disabled
    str = "#{level}: #{msg}\n"
    unless $zapt_no_color
      case level
      when 'INFO'
        str.green
      when 'WARN'
        str.yellow
      when 'ERROR'
        str.red
      when 'DEBUG'
        str.green
      when 'TRACE'
        str.green
      end
    else
      str
    end
  end
}
