require 'zapt'


shell name:'hello_world', desc:'task that echo\'s hello world to the console' do
  commands [
            'echo hello world'
           ], user:Zapt.user
end

shell name:'hello_hello', desc:'task that echo\'s hello hello to the console' do
  commands [
            'echo hello hello'
           ], user:Zapt.user
end

