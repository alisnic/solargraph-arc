require File.join(Dir.pwd, ARGV.first, 'config/environment')

def process(klass, hash)
  result = {}

  hash.each do |meth, data|
    method = if meth.start_with?(".")
      klass.method(meth[1..-1])
    elsif meth.start_with?("#")
      klass.instance_method(meth[1..-1])
    end

    if data["skip"]
      result[method.source_location.first] ||= []
      result[method.source_location.first] << meth
    end
  end

  result
end

report = process(
  ActiveRecord::Base,
  YAML.load_file("spec/definitions/activerecord5.yml")
)

report.sort_by do |owner, methods|
  -methods.size
end.each do |owner, methods|
  puts "#{owner.to_s} - #{methods.size} methods"
  puts methods.join(", ")
end
