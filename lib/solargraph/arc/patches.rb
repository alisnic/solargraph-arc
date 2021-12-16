module Solargraph
  class ApiMap
    # TODO: https://github.com/castwide/solargraph/pull/512
    def get_complex_type_methods complex_type, context = '', internal = false
      # This method does not qualify the complex type's namespace because
      # it can cause conflicts between similar names, e.g., `Foo` vs.
      # `Other::Foo`. It still takes a context argument to determine whether
      # protected and private methods are visible.
      return [] if complex_type.undefined? || complex_type.void?
      result = Set.new
      complex_type.each do |type|
        if type.duck_type?
          result.add Pin::DuckMethod.new(name: type.to_s[1..-1])
          result.merge get_methods('Object')
        else
          unless type.nil? || type.name == 'void'
            visibility = [:public]
            if type.namespace == context || super_and_sub?(type.namespace, context)
              visibility.push :protected
              visibility.push :private if internal
            end
            result.merge get_methods(type.namespace, scope: type.scope, visibility: visibility)
          end
        end
      end
      result.to_a
    end
  end

  class YardMap
    # TODO: remove after https://github.com/castwide/solargraph/pull/509 is merged
    def spec_for_require path
      name = path.split('/').first
      spec = Gem::Specification.find_by_name(name, @gemset[name])

      # Avoid loading the spec again if it's going to be skipped anyway
      #
      return spec if @source_gems.include?(spec.name)
      # Avoid loading the spec again if it's already the correct version
      if @gemset[spec.name] && @gemset[spec.name] != spec.version
        begin
          return Gem::Specification.find_by_name(spec.name, "= #{@gemset[spec.name]}")
        rescue Gem::LoadError
          Solargraph.logger.warn "Unable to load #{spec.name} #{@gemset[spec.name]} specified by workspace, using #{spec.version} instead"
        end
      end
      spec
    end
  end
end
