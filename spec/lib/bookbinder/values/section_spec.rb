require_relative '../../../../lib/bookbinder/values/section'

module Bookbinder
  describe Section do
    describe "repo path" do
      it "wraps the input in a Pathname, for easier manipulation" do
        expect(Section.new('some/path/to/repo').
               path_to_repository.join('or/something')).
        to eq(Pathname('some/path/to/repo/or/something'))
      end

      it "even wraps a nil repo path, so that e.g. file existence checks fail" do
        expect(Section.new.path_to_repository.join('foo')).
          to eq(Pathname('foo'))
      end
    end

    describe '#subnav_template' do
      let(:repo) { Section.new('directory',
                               'full name',
                               dir_name = nil,
                               subnav_template_name) }

      context 'when the incoming template does not look like a partial file' do
        let(:subnav_template_name) { 'my_template' }

        it 'is unchanged' do
          expect(repo.subnav_template).to eq('my_template')
        end
      end

      context 'when the incoming template looks like a partial file' do
        let(:subnav_template_name) { '_my_tem.erbplate.erb' }

        it 'is trimmed' do
          expect(repo.subnav_template).to eq('my_tem.erbplate')
        end
      end

      context 'when the incoming template is not defined' do
        let(:subnav_template_name) { nil }

        it 'is nil' do
          expect(repo.subnav_template).to be_nil
        end
      end

    end

    describe '#subnav' do
      let(:section) do
        Section.new('directory', 'full name', 'desired_dir', subnav_template, subnav_name)
      end

      context 'when the section provides a subnav name but no template' do
        let(:subnav_name){ 'some_subnav_name' }
        let(:subnav_template){ nil }

        it 'uses the subnav name' do
          expect(section.subnav).to eq({ 'desired_dir' => subnav_name })
        end
      end

      context 'when the section provides both a subnav name and a template' do
        let(:subnav_name){ 'some_subnav_name' }
        let(:subnav_template){ 'some_subnav_template' }

        it 'uses the subnav template' do
          expect(section.subnav).to eq({ 'desired_dir' => subnav_template })
        end
      end

      context 'when the section provides a template but no subnav name' do
        let(:subnav_name){ nil }
        let(:subnav_template){ 'some_subnav_template' }

        it 'uses the subnav template' do
          expect(section.subnav).to eq({ 'desired_dir' => subnav_template })
        end
      end

      context 'when the section provides neither a template nor a subnav name' do
        let(:subnav_name){ nil }
        let(:subnav_template){ nil }

        it 'uses the subnav template' do
          expect(section.subnav).to eq({ 'desired_dir' => 'default' })
        end
      end
    end

    it "is a mistake to ask for a path to a preprocessor attribute when Section not applicable to preprocessor" do
      expect { Section.new.path_to_preprocessor_attribute('foo') }.
        to raise_error(Errors::ProgrammerMistake)
    end
  end
end
