# rubocop:disable Rails/Output

class RMT::CLI::Import < RMT::CLI::Base

  desc 'data PATH', 'Read SCC data from given path'
  def data(path)
    needs_path(path) do
      RMT::SCC.new(options).import(path)
    end
  end

  desc 'repos PATH', 'Mirror repos from given path'
  def repos(path)
    needs_path(path) do
      repos = Repository.where(mirroring_enabled: true)
      if repos.empty?
        warn 'There are no repositories marked for mirroring.'
        return
      end

      base_dir = RMT::DEFAULT_MIRROR_DIR

      repos.each do |repository|
        repository.external_url.sub!(/.*(?=SUSE)/, "file://#{path}/") # FIXME: this probably won't work for some repos
        begin
          puts "Mirroring repository #{repository.name} from #{path} to #{base_dir}"
          RMT::Mirror.from_repo_model(repository).mirror
          repository.refresh_timestamp!
        rescue RMT::Mirror::Exception => e
          warn e.to_s
        end
      end
    end
  end

end
