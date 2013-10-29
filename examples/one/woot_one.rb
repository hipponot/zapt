require_relative '../../lib/zapt'

password = Zapt.ask("Enter wootmath credentials password to get started")

# setup credentials
system do
  commands [
            "wootcloud setup --password=\"#{password}\"", 
           ], user:Zapt.user
end

