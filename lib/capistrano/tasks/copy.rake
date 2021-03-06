namespace :copy do

  archive_name = "archive.tar.gz"
  include_dir  = fetch(:include_dir) || "*"
  # Defalut to :all roles
  tar_roles = fetch(:tar_roles, :all)

  tar_verbose = fetch(:tar_verbose, true) ? "v" : ""

  desc "Archive files to #{archive_name}"
  file archive_name do
    exclude_dir  = Array(fetch(:exclude_dir, %w(.git log spec tmp)))
    #exclude_args = exclude_dir.map { |dir| "--exclude '#{dir}'"}
    file_list = FileList[include_dir].exclude(*exclude_dir.concat([archive_name]))
    sh "tar -c#{tar_verbose}zf #{archive_name} #{file_list}"
  end

  desc "Deploy #{archive_name} to release_path"
  task :deploy => archive_name do |t|
    tarball = t.prerequisites.first

    on roles(tar_roles) do
      # Make sure the release directory exists
      puts "==> release_path: #{release_path} is created on #{tar_roles} roles <=="
      execute :mkdir, "-p", release_path

      # Create a temporary file on the server
      tmp_file = capture("mktemp")

      # Upload the archive, extract it and finally remove the tmp_file
      upload!(tarball, tmp_file)
      execute :tar, "-xzf", tmp_file, "-C", release_path
      execute :rm, tmp_file
    end
  end

  task :clean do |t|
    # Delete the local archive
    File.delete archive_name if File.exists? archive_name
  end

  after 'deploy:finished', 'copy:clean'

  task :create_release => :deploy
  task :check
  task :set_current_revision

end
