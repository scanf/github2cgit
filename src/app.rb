require 'fileutils'
require_relative '../src/cgit.rb'
require_relative '../src/github_data_source.rb'
require_relative '../src/process.rb'

include Cgit

class App
  attr_accessor :user
  attr_accessor :local_git_directory
  attr_accessor :cgit_repositories_rcpath

  def initialize(user, directory, config_path)
    @user = user
    @local_git_directory = directory
    @cgit_repositories_rcpath = config_path
  end

  def run

    cgit_repositories = repos_from([
      GithubDataSource.new(user, "starred", cgit_repositories_rcpath,
      local_git_directory),
      GithubDataSource.new(user, "repos", cgit_repositories_rcpath,
                           local_git_directory)])

# Write config and clone all of the stuff

    tmp_path = "#{cgit_repositories_rcpath}.tmp"
    config_file = File.open(tmp_path, 'w')
    cgit_repositories.each  do |repo|
      local_path = "#{local_git_directory}/#{repo.owner}/#{repo.name}.git" # is this right?
      if File.directory?(local_path)
        runInBackground("cd #{local_path} && git remote update &")
      else
        runInBackground("git clone --mirror --quiet #{repo.git_url} #{local_path} &")
      end
      config_file.write(repo.to_string(local_git_directory))
    end

    config_file.close unless config_file.nil?
    FileUtils.mv(tmp_path, cgit_repositories_rcpath)
  end

  def repos_from(sources)
    repos = []
    sources.each do |repo|
      repos += map_to_cgit_repos(repo.repositories())
    end
    repos.uniq { |repo| repo.git_url }
  end
end