=begin
    Generates and returns a unique list of all packages and their versions for a given repository
    *in projects where packages* are built from.
        Example:
        {
            "Framework" => {
              "Company.Contracts" => "10.0.0",
              "Log4Net" => "4.3.0"
              ...
            },
            "Reports" => {
              "Company.ReportWizard" => "2.10.0"  
            }
        }
        
    This can be maintained static by parsing once and saving to a github repo or can be done realtime.
    Processing time is minimal, git repo checkout time may actually be longer.
    
    1. Checkout repo
    2. Scan packages.config files for packages and versions and store in array
    3. Uniquefy list to a hash map and return
=end

class VersionMap

  def version_map repo_url, branch
    return if repo_url.to_s.strip.length == 0
    return if branch.to_s.strip.length == 0

    return if !GitApi.CheckoutRepoAfresh repo_url, branch

    # load any old/existing versions
    old_versions = {}
    if File.exists? Constants::VERSION_MAP_FILE
      old_versions = JSON.parse File.read(Constants::VERSION_MAP_FILE)
    end

    # versions hash merged with existing
    versions = {}
    versions = old_versions.merge(versions)

    # load semvers by project. semver file name maps to project by convention
    if Dir.exist?(Constants::SEMVER)  #the folder where multiple semvers of repo exist
      versions = update_semver_package_versions versions
    else
      raise "#{Constants::SEMVER} directory not found"
    end

    # grab packages within packages.config file by projects that have semvers defined
    projects = versions.keys
    projects.each { |p|
      pkg_file = Dir.glob "./#{p}/packages.config"

      next if pkg_file[0].nil?

      puts "Finding packages in: #{pkg_file[0]}".bg_green.white
      
      doc = Nokogiri::XML File.read(pkg_file[0])
      nodes = doc.xpath "//*[@id]"
      nodes.each { |node|
        if (!versions[node['id']].nil? && node['version'] != versions[node['id']])
          puts "======Error: Package #{node['id']} with version #{node['version']} has a different pre-exisiting version: #{versions[node['id']]}".red
        end
        versions[node['id']] = node['version']
      }

      # we don't need {project => version} element
      versions.delete p
    }

    Dir.chdir Constants::PARENTDIR
    File.write Constants::VERSION_MAP_FILE, versions.to_json

    versions

  end

  def update_semver_package_versions versions

    temp = get_repository_package_versions
    temp = temp.merge(versions)

    temp
  end

  def get_repository_package_versions

    v = {}
    # each .projects file has list of projects whose assemblies will bear the same version specified in the .semver file of same name

    # load all semver files
    semvers = Dir["#{Constants::SEMVER}/**/*#{Constants::SEMVER}"]

    semvers.each { |s|

      # nuget name is semver file name
      name = s
        .to_s
        .gsub(Constants::SEMVER, '')
        .gsub('/', '')

      # list of projects in metadata
      projects = SemVer.projects_in_metadata

      # get the nuget version, which is the same for all projects loaded from .projects above
      nuget_version = get_version "#{Dir.pwd}/#{Constants::SEMVER}/#{name}.semver"

      projects.each { |x|
        v[x] = nuget_version
      }

      v[name] = nuget_version
    }

    v
  end

  def get_version file
    v = SemVer.new
    v.load file    
    "#{ XSemVer::SemVer.new(v.major, v.minor, v.patch).format "%M.%m.%p"}"
  end
end


#vm = VersionMap.new
#versions = vm.version_map "http://", "master"
