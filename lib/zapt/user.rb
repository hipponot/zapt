require 'etc'

module Zapt

  @user = ENV['SUDO_USER'] || ENV['USER']
  @group = Etc.getgrgid(Etc.getpwnam(@user).gid).name
  class << self
    attr_reader :user
    attr_reader :group
  end

end
