require 'active_support/all'

module Interrogate
  class Recipes
    def self.list
      [
        :all
      ]
    end

    def self.get_recipe(recipe)
      begin
        "Interrogate::Recipes::#{recipe.to_s.camelize}".constantize
      rescue
        raise StandardError, "The recipe #{recipe} does not exist"
      end
    end
  end
end

# Must stay at the bottom
Interrogate::Recipes.list.each do |recipe|
  require_relative "./recipes/#{recipe.to_s}.rb"
end