module Interrogate
  class Recipes
    class All
      def self.description
        <<-TEXT.strip_heredoc
        all - Include all files, this includes everything that comes 
              with Code Mirror
        TEXT
      end

      def self.build_options
        nil
      end

      def self.build(build_options=nil)
        Proc.new do
          output 'compiled'

          # Javascript files
          input 'app' do
            match '**/*.coffee' do
              coffee_script
            end

            match 'javascripts/**/*.js' do
              concat 'interrogate.js'
              # uglify
            end
          end
        end
      end

    end
  end
end