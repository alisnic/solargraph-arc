require File.join(Dir.pwd, ARGV.first, 'config/environment')

class Model < ActiveRecord::Base
end

def own_instance_methods(klass, test=klass.new)
  (klass.instance_methods(true) - Object.methods)
    .sort
    .reject {|m| m.to_s.start_with?("_") || !test.respond_to?(m) }
    .map {|m| klass.instance_method(m) }
    .select {|m| m.source_location && m.source_location.first.include?("gem") }
end

def own_class_methods(klass)
  (ActiveRecord::Base.methods(true) - Object.methods)
    .sort
    .reject {|m| m.to_s.start_with?("_") || !klass.respond_to?(m) }
    .map {|m| klass.method(m) }
    .select {|m| m.source_location && m.source_location.first.include?("gem") }
end

def build_report(klass, test: klass.new)
  result = {}
  distribution = {}

  own_class_methods(klass).each do |meth|
    distribution[meth.source_location.first] ||= []
    distribution[meth.source_location.first] << ".#{meth.name}"

    result["#{klass.to_s}.#{meth.name}"] = {
      types: ["undefined"],
      skip:  false
    }
  end

  own_instance_methods(klass, test).each do |meth|
    distribution[meth.source_location.first] ||= []
    distribution[meth.source_location.first] << "##{meth.name}"

    result["#{klass.to_s}##{meth.name}"] = {
      types: ["undefined"],
      skip:  false
    }
  end

  pp distribution
  result
end

# report = build_report(ActiveRecord::Base, test: Model.new)
# report = build_report(ActionController::Base)
report = build_report(String)

binding.pry


# File.write("activerecord.yml", result.deep_stringify_keys.to_yaml)

# report = build_report(
#   ActionController::Base,
#   own_class_methods(ActionController::Base),
#   own_instance_methods(ActionController::Base)
# )
# File.write("actioncontroller.yml", report.deep_stringify_keys.to_yaml)
