require 'woot'
require_relative '../lib/zapt'

ruby :list do
  next
  Woot::Env.setenv('test')
  ec2 = AWS::EC2.new
  regions = ec2.regions.map(&:name)
  regions.each do |region|
    puts "== #{region} =="
    ec2 = AWS::EC2.new :region=>region
    instances = ec2.instances.inject({}) do |m, i| 
      m[i.id] = i.status; m 
    end
    puts instances.inspect
  end
end

ruby :create do
  Woot::Env.setenv('test')
  ec2 = AWS::EC2.new :region=>'us-west-1'
  new_inst = ec2.instances.create(:image_id =>'ami-fe002cbb',
                                  :instance_type => 't1.micro',
                                  :key_name => 'wootmath_ec2_hosts',
                                  :security_group_ids => ['wootmath_dev'])
  new_inst.tags['Name'] = "wootmath_dev_#{ec2.instances.count}"
  puts "Waiting for new instance with id #{new_inst.id} to become available..."
  sleep 1 while new_inst.status == :pending
  puts '...ready'
end
