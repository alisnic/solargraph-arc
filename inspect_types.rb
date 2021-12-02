require_relative(ARGV.first + 'config/environment')

class Model < ActiveRecord::Base
end

(ActiveRecord::QueryMethods.instance_methods(true) - Object.methods).each do |meth|
  next if meth.to_s.end_with?("=")

  begin
    puts "#{meth} \t-> #{Model.send(meth).class}"
  rescue => error
    puts "#{meth} \t-> #{error}"
  end
end
