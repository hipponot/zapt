require_relative "zapt/version"
require_relative "zapt/delegator"
require_relative "zapt/logger"
require_relative "zapt/user"

# top level require puts the DSL methods into main scope
include Zapt::Delegator

module Zapt

  # friendly errors
  class Error < StandardError; end

  # class instance methods
  class << self

    def is_ec2_build_server?
      !(/Amazon\s+EC2/ =~ `sudo dmidecode -s chassis-asset-tag`.chomp)
    end

    def ip_from_node(node)
      abort("Bad config passed to Zapt.host_ip_from_node") unless node.is_a(Hash) && node.has_key(:internal_ip) && node.has_key(:public_ip)
      ip_addr_key = Zapt.is_ec2_build_server? ? :internal_ip : :public_ip
      node[ip_addr_key]
    end

    def message msg
      unless $zapt_no_color
        puts msg.white_on_black
      else
        puts msg
      end
    end

    attr_accessor :cluster_config

    def error msg
      raise Zapt::Error.new(msg)
    end

    def set_logger_level level
      $logger.level = level
    end

    def load_and_eval filename, *args
      raise Error.new("Can't stat file #{filename}") unless File.exist?(filename)
      proc = Proc.new {}
      eval(File.read(filename), proc.binding, filename)
    end

    def home
      File.expand_path(File.join(File.dirname(__FILE__),'..'))
    end

    def bin
      File.join(Zapt.home, 'bin')
    end

    def ask(statement)
      puts statement.yellow
      gets.tap{|text| text.strip! if text}
    end

    def yes?(prompt = 'Continue?', default = true)
      a = ''
      s = default ? '[Y/n]' : '[y/N]'
      d = default ? 'y' : 'n'
      until %w[y n].include? a
        a = ask("#{prompt} #{s} ") { |q| q.limit = 1; q.case = :downcase }
        a = d if a.length == 0
      end
      a == 'y'
    end

  end
end


