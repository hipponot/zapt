#!/usr/bin/env ruby
require 'zapt'


shell name:'shell_fail', desc:'This task should fail' do
  command 'false'
end

shell name:'shell_succeed', desc:'This task should succeed' do
  command 'true'
end
