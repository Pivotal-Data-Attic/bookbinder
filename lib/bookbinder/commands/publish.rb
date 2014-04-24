class Cli
  class Publish < BookbinderCommand
    def run(cli_arguments)
      raise Cli::InvalidArguments unless arguments_are_valid?(cli_arguments)

      target_tag    = (cli_arguments[1..-1] - ['--verbose']).pop
      final_app_dir = File.absolute_path('final_app')

      bind_book(cli_arguments, final_app_dir, target_tag)
    end

    def self.usage
      "<local|github> [tag] [--verbose]"
    end

    private

    def bind_book(cli_arguments, final_app_dir, target_tag)
      if target_tag then
        checkout_book_at(target_tag) { generate_site_etc(cli_arguments, final_app_dir, target_tag) }
      else
        generate_site_etc(cli_arguments, final_app_dir)
      end
    end

    def generate_site_etc(cli_args, final_app_dir, target_tag=nil)
      # TODO: general solution to turn all string keys to symbols
      verbosity = cli_args.include?('--verbose')
      location = cli_args[0]

      success = Publisher.new(@logger).publish publication_arguments(verbosity, location, pdf_options, target_tag, final_app_dir)
      success ? 0 : 1
    end

    def pdf_options
      return unless config.has_option?('pdf')
      {
        page: config.pdf['page'],
        filename: config.pdf['filename'],
        header: config.pdf.fetch('header')
      }
    end

    def checkout_book_at(target_tag, &doc_generation)
      temp_workspace     = Dir.mktmpdir
      book               = Book.from_remote(logger: @logger, full_name: config.book_repo,
                                            destination_dir: temp_workspace, ref: target_tag)
      expected_book_path = File.join temp_workspace, book.directory

      @logger.log "Binding \"#{book.full_name.cyan}\" at #{target_tag.magenta}"
      FileUtils.chdir(expected_book_path) { doc_generation.call(config, target_tag) }
    end

    def publication_arguments(verbosity, location, pdf_hash, target_tag, final_app_dir)
      local_repo_dir = location == 'local' ? File.absolute_path('..') : nil

      arguments = {
          sections: config.sections,
          output_dir: File.absolute_path('output'),
          master_middleman_dir: obtain_master_middleman(local_repo_dir),
          final_app_dir: final_app_dir,
          pdf: pdf_hash,
          verbose: verbosity,
          pdf_index: config.pdf_index,
          local_repo_dir: local_repo_dir
      }

      arguments.merge!(template_variables: config.template_variables) if config.respond_to?(:template_variables)
      arguments.merge!(host_for_sitemap: config.public_host)
      arguments.merge!(target_tag: target_tag) if target_tag
      arguments
    end

    def obtain_master_middleman(local_repo_dir)
      if config.has_option?('layout_repo')
        section = {'repository' => {'name' => config.layout_repo}}
        File.join(local_repo_dir, Section.get_instance(@logger, section_hash: section, local_repo_dir: local_repo_dir).directory)
      else
        File.absolute_path('master_middleman')
      end
    end

    def arguments_are_valid?(arguments)
      return false unless arguments.any?

      verbose           = arguments[1] && arguments[1..-1].include?('--verbose')
      tag_provided      = arguments[1] && (arguments[1..-1] - ['--verbose']).any?
      nothing_special   = arguments[1..-1].empty?

      %w(local github).include?(arguments[0]) && (tag_provided || verbose || nothing_special)
    end
  end
end
