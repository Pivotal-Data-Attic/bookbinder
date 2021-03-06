module Bookbinder
  module Commands
    module BindComponents
      class LayoutPreparer
        def initialize(fs)
          @fs = fs
        end

        attr_reader :fs

        def prepare(output_locations, cloner, config)
          if config.has_option?('layout_repo')
            cloned_repo = cloner.call(source_repo_name: config.layout_repo,
                                      destination_parent_dir: Dir.mktmpdir)

            fs.copy_contents(cloned_repo.path, output_locations.site_generator_home)
          end
          fs.copy_contents(File.absolute_path('master_middleman'), output_locations.site_generator_home)
        end
      end
    end
  end
end
