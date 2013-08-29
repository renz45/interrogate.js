module Interrogate
  class Recipes
    class Demo
      def self.description
        <<-TEXT.strip_heredoc
        demo - Build files required for demo app
        TEXT
      end

      def self.build_options
        nil
      end

      def self.build(build_options=nil)
        Proc.new do
          output 'demo_app'

          # Javascript files
          input '.' do
            match 'app/**/*.coffee' do
              coffee_script
            end

            match 'app/javascripts/**/*.js' do
              concat 'interrogate.js'
              # uglify
            end
          end
        end
      end

    end
  end
end