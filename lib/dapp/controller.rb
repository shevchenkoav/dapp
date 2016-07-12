module Dapp
  class Controller
    include CommonHelper

    attr_reader :opts, :patterns

    def initialize(cli_options:, patterns: nil)
      @opts = cli_options
      @opts[:log_indent] = 0

      @patterns = patterns || []
      @patterns << '*' unless @patterns.any?

      build_confs
    end

    def build
      @build_confs.each { |build_conf|
        log build_conf._name
        with_log_indent { Application.new(conf: build_conf, opts: opts).build_and_fixate! }
      }
    end

    def list
      @build_confs.each do |build_conf|
        log build_conf._name
      end
    end

    def show
      @build_confs.each do |build_conf|
        log build_conf._name
        with_log_indent { log JSON.pretty_generate(build_conf.to_h) }
      end
    end

    def push(repo)
      raise "Several applications isn't available for push command!" unless @build_confs.one?
      log @build_confs.first.name
      with_log_indent { Application.new(conf: @build_confs.first, opts: opts, ignore_git_fetch: true).push!(repo) }
    end

    def smartpush(repo_prefix)
      @build_confs.each do |build_conf|
        log build_conf._name
        tag_name = File.join(repo_prefix, build_conf._name)
        with_log_indent { Application.new(conf: build_conf, opts: opts, ignore_git_fetch: true).push!(tag_name) }
      end
    end

    def flush_build_cache
      @build_confs.each do |build_conf|
        log build_conf._name
        app = Application.new(conf: build_conf, opts: opts, ignore_git_fetch: true)
        FileUtils.rm_rf app.build_cache_path
      end
    end

    def self.flush_stage_cache
      shellout('docker rmi $(docker images --format="{{.Repository}}:{{.Tag}}" dapp)')
      shellout('docker rmi $(docker images -f "dangling=true" -q)')
    end

    private

    def build_confs
      @build_confs ||= begin
        dappfiles = []
        if File.exist? dappfile_path
          dappfiles << dappfile_path
        elsif File.exist? dapps_path
          dappfiles += Dir.glob(File.join([dapps_path, '*', 'Dappfile'].compact))
        end
        dappfiles.flatten.uniq!
        apps = dappfiles.map { |dappfile| apps(dappfile, app_filters: patterns) }.flatten

        if apps.empty?
          STDERR.puts "Error: No such app: '#{patterns.join(', ')}' in #{dappfile_path}"
          exit 1
        else
          apps
        end
      end
    end

    def apps(dappfile_path, app_filters:)
      config = Config::Main.new(dappfile_path: dappfile_path) do |conf|
        log "Processing dappfile '#{dappfile_path}'"
        conf.instance_eval File.read(dappfile_path), dappfile_path
      end
      config._apps.select { |app| app_filters.any? { |pattern| File.fnmatch(pattern, app._name) } }
    end

    def dappfile_path
      @dappfile_path ||= File.join [opts[:dir], 'Dappfile'].compact
    end

    def dapps_path
      @dapps_path ||= File.join [opts[:dir], '.dapps'].compact
    end
  end # Controller
end # Dapp