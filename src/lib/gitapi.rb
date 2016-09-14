=begin
    Provides API accessors for operations over github repos
    This module has several methods that interface with Git and github
     Unless otherwise returned specifically with a status,, commands that don't fail return an empty string - ''
=end

module GitApi

  def GitApi.CheckoutNewBranch branch
    puts "Checking out new branch #{branch}..."
    `git checkout -b #{branch}`
  end

  def GitApi.CheckoutExistingBranch branch
    puts "Checking out existing branch #{branch}..."
    `git checkout #{branch}`

    # check if checkout succeeded
    actual_branch = `git rev-parse --abbrev-ref HEAD`

    return actual_branch.chomp! == branch
  end

  def GitApi.DoesBranchExist remote,  branch
    puts "Checking if branch #{branch} existing at #{remote}..."
    `git ls-remote --heads #{remote} #{branch}`
  end

  def GitApi.RebaseLocal branch
    puts "Rebasing #{branch} with checked out branch..."
    `git stash`
    `git rebase #{branch}`
  end

  def GitApi.CheckoutLocal branch
    puts "Checking out local branch: #{branch}..."
    `git checkout #{branch}`
  end

  def GitApi.PushBranch remote, branch
    puts "Pushing #{branch} to #{remote}..."
    `git push #{remote} #{branch}`
  end

  def GitApi.HaveLocalChanges
    `git status -s`
  end

  def GitApi.DeleteLocalBranch branch
    `git branch -D #{branch}`
  end

  def GitApi.DeleteRemoteBranch remote, branch
    status = GitApi.DoesBranchExist remote, branch
    `git push #{remote} :#{branch}` if status.chomp! == Constants::EMPTY
  end

  def GitApi.PullWithRebase remote, branch
    `git pull --rebase #{@repo_url} #{@branch}`
  end

  def GitApi.CommitChanges comment, git_status = ''
    if git_status != Constants::EMPTY
      val = git_status.split("\n")
      val.each { |x|
        value = x.split(' M ').last || x.split('?? ').last
        if (/.csproj/.match(value) || /packages.config/.match(value))
          status = `git add #{value}`
          if status != Constants::EMPTY
            return false
          end
        end
      }
    end

    status = `git commit -m "#{comment}"`
    return status != Constants::EMPTY
  end

  # we do NOT want to switch to parent folder but stay in current repo dir when we exit this method
  def GitApi.CheckoutRepoAfresh repo_url, branch
    repo = GitApi.ProjectNameFromRepo repo_url
    return false if repo == Constants::EMPTY

    # clear repo folder if it already exists
    if File.directory? repo
      puts 'Repository already exists! Cleaning...'
      FileUtils.rm_rf repo
    end

    # clone to local
    puts 'Cloning repo to local...'
    begin
      # also tests for valid repo, this will cout if cmd fails, no need for additional message
      cmd_out = system "git clone #{repo_url}"
      return false if cmd_out.to_s == 'false'
    rescue
      puts "Clone repo for #{repo_url} failed"
      puts $!
      return false
    end

    # checkout requested branch if it's not the default branch checked out when cloned
    Dir.chdir repo
    puts "Checking out requested branch: #{branch}"
    `git fetch`

    cmd_out = GitApi.CheckoutExistingBranch branch

    return cmd_out
  end

  def GitApi.ProjectNameFromRepo repo_url
    puts "Repo Url provided: #{repo_url}. Parsing..."
    repo = Constants::EMPTY
    begin
      uri = Addressable::URI.parse repo_url
    rescue
      puts $!
      puts "repo_url: #{repo_url} parse failed"
      return repo
    end

    if uri.nil?
      puts 'Invalid repo_url provided'
      return repo
    end

    directory = Pathname.new(uri.path).basename
    if directory.nil?
      puts 'No directory provided in repo_url'
      return repo
    end

    repo = directory.to_s.gsub uri.extname, repo
    puts "Repository name parsed: #{repo}"

    repo
  end
end
