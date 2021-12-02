require File.join(Dir.pwd, ARGV.first, 'config/environment')

class Model < ActiveRecord::Base
end

def own_instance_methods(klass, test=klass.new)
  (klass.instance_methods(true) - Object.methods)
    .sort
    .reject {|m| m.to_s.start_with?("_") || !test.respond_to?(m) }
end

def own_class_methods(klass)
  (ActiveRecord::Base.methods(true) - Object.methods)
    .sort
    .reject {|m| m.to_s.start_with?("_") || !klass.respond_to?(m) }
end

def build_report(class_methods, instance_methods)
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

  result
end

report = build_report(
  own_class_methods(ActiveRecord::Base),
  own_instance_methods(ActiveRecord::Base, Model.new)
)

# File.write("activerecord.yml", result.deep_stringify_keys.to_yaml)

report = build_report(
  own_class_methods(ActionController::Base),
  own_instance_methods(ActionController::Base)
)
File.write("actioncontroller.yml", report.deep_stringify_keys.to_yaml)
