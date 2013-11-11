require 'etc'

module Zapt

  @user = Etc.getlogin
  @group = Etc.getgrgid(Etc.getpwnam(@user).gid).name
  class << self
    attr_reader :user
    attr_reader :group
  end

end
