require_relative(ARGV.first + 'config/environment')

# class Model < ActiveRecord::Base
# end

pp ActiveRecord::QueryMethods.instance_methods - Object.methods
