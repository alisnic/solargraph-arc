class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class Model < ActiveRecord::Base
end
Model.find
