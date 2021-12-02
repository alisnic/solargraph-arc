require File.join(Dir.pwd, ARGV.first, 'config/environment')

class Model < ActiveRecord::Base
end

instance_methods = (ActiveRecord::Base.instance_methods(true) - Object.methods).sort.reject {|m| m.to_s.start_with?("_") || !Model.new.respond_to?(m) }

class_methods = (ActiveRecord::Base.methods(true) - Object.methods).sort.reject {|m| m.to_s.start_with?("_") || !ActiveRecord::Base.respond_to?(m) }

result = {}

class_methods.each do |meth|
  result[".#{meth}"] = {
    types: ["undefined"],
    skip:  false
  }
end

instance_methods.each do |meth|
  result["##{meth}"] = {
    types: ["undefined"],
    skip:  false
  }
end

File.write("definitions.yml", result.deep_stringify_keys.to_yaml)
