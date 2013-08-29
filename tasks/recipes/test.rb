module Interrogate
  class Recipes
    class Test
      def self.description
        <<-TEXT.strip_heredoc
        test - Build files required for tests
        TEXT
      end

      def self.build_options
        nil
      end

      def self.build(build_options=nil)
        Proc.new do
          output 'test/resources'

          # Javascript files
          input '.' do
            match '**/*.coffee' do
              coffee_script
            end

            match 'app/javascripts/**/*.js' do
              concat 'interrogate.js'
              # uglify
            end

            match 'test/*.js' do
              concat 'compiled_tests.js'
            end
          end
          end
        end
      end

    end
  end
end