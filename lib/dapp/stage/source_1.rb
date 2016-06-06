module Dapp
  module Stage
    class Source1 < Base
      def image
        super do |image|
          builder.git_artifact_list.each do |git_artifact|
            git_artifact.apply_source_1!(image)
          end
        end
      end

      def signature
        hashsum [builder.stages[:source_1_archive].signature,
                 dependency_file, dependency_file_regex,
                 *builder.app_install_commands, # TODO chef
                 *builder.git_artifact_list.map { |git_artifact| git_artifact.source_1_commit }]
      end

      def dependency_file
        @dependency_file ||= begin
          file_path = Dir[builder.build_path('*')].detect {|x| x =~ dependency_file_regex }
          File.read(file_path) unless file_path.nil?
        end
      end

      def dependency_file?
        !dependency_file.nil?
      end

      def dependency_file_regex
        /.*\/(Gemfile|composer.json|requirement_file.txt)$/
      end
    end # Source1
  end # Stage
end # Dapp