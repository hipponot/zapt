require_relative "zapt/version"
require_relative "zapt/delegator"
require_relative "zapt/logger"
require_relative "zapt/user"
require_relative "zapt/cli"


require 'json'

# top level require puts the DSL methods into main scope
include Zapt::Delegator

module Zapt

  # friendly errors
  class Error < StandardError; end

  # class instance methods
  class << self

    attr_writer :ui

    def is_ec2_build_server?
      # Kernel.system because apparently zapt has an overridden system that prints red ERROR:
      Kernel.system("which ec2metadata > /dev/null")
    end

    # ! Sorry ya'll need to copy paste this to vega sitedb.rb and break the dependency
    # ! between vega & zapt
    # !
    # ! If you change this then change sitedb.rb version as well
    $IS_AWS_CACHE = nil
    def is_aws_vpn?
      # Rate limit - max 1 request per 2 minutes
      now = Time.now.to_f
      if ($IS_AWS_CACHE == nil) then
        $IS_AWS_CACHE = JSON.parse File.read("/tmp/.is.aws.cache") rescue nil
      end
      cache_hit = ($IS_AWS_CACHE != nil && now - $IS_AWS_CACHE["ts"] < 120) rescue false
      return $IS_AWS_CACHE["result"] if cache_hit

      result = `dig +short myip.opendns.com @resolver1.opendns.com`.chomp == "35.85.111.35" ||
               `dig +short myip.opendns.com @resolver1.opendns.com`.chomp == "2601:280:5c80:42ea:2c71:eb00:23b4:1b09" ||
               `curl -s ifconfig.co`.chomp == "35.85.111.35" ||
               `curl -s ifconfig.co`.chomp == "2601:280:5c80:42ea:2c71:eb00:23b4:1b09" ||
               `curl -s http://checkip.amazonaws.com`.chomp == "35.85.111.35" ||
               `curl -s http://ifconfig.me`.chomp == "35.85.111.35"
      $IS_AWS_CACHE = { "ts" => now, "result" => result }
      File.open("/tmp/.is.aws.cache", "w") { |f| f.puts JSON.generate $IS_AWS_CACHE } rescue nil
      return result
    end

    def ip_from_node(node)
      abort("Bad config passed to Zapt.host_ip_from_node") unless node.is_a?(Hash) && node.has_key?(:internal_ip) && node.has_key?(:public_ip)
      if Zapt.is_ec2_build_server? || is_aws_vpn?
        ip_addr_key = :internal_ip
      else
        ip_addr_key = :public_ip
      end
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
