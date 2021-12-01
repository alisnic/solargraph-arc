require_relative(ARGV.first + 'config/environment')

class Model < ActiveRecord::Base
end

(ActiveRecord::QueryMethods.instance_methods - Object.methods).each do |meth|
  puts "#{meth} -> #{Model.send(:meth).class}"
end
