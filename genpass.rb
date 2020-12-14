require 'digest/md5'
require 'active_record'

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection :development

class User < ActiveRecord::Base
end

# Basic infomation
username = 'testdesuo'
rawpasswd = "passdesu"
algorithm = "1"
r = Random.new
salt = Digest::MD5.hexdigest(r.bytes(20))
hashed = Digest::MD5.hexdigest(salt+rawpasswd)

puts "salt = #{salt}"
puts "username = #{username}"
puts "raw password = #{rawpasswd}"
puts "algorithm = #{algorithm}"
puts "hashed passwd = #{hashed}"


# Update database
s = User.new
s.id = username
s.salt = salt
s.hashed = hashed
s.algo = algorithm
s.save

# Display all entires in database
@s = User.all
@s.each do |a|
  puts a.id + "\t" + a.salt + "\t" + a.hashed + "\t" + a.algo
end
