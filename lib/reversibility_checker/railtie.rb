require "rails"

module ReversibilityChecker
  class Railtie < Rails::Railtie
    rake_tasks do
      load "reversibility_checker/railties/reversible.rake"
    end
  end
end
