require 'etc'

module Zapt

  @user = Etc.getlogin
  @group = Etc.getgrgid(Etc.getpwnam(@user).gid).name
  $logger.info "Zapt user: #{@user}"
  $logger.info "Zapt user's primary group: #{@group}"
  class << self
    attr_reader :user
    attr_reader :group
  end

end
