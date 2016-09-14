=begin

Processes upgrade for a C# code repository

=end

class UpgradePackages

  UPGRADE_BRANCH = 'upgrade'

  def initialize versions = {}
    @versions = versions
  end

  def checkout_upgrade_branch

    # obtain an upgrade branch
    if (GitApi.DoesBranchExist('origin', UPGRADE_BRANCH) != Constants::EMPTY)
      puts 'Checking out existing upgrade branch...'.bg_green.white
      return false if !GitApi.CheckoutExistingBranch(UPGRADE_BRANCH) == Constants::EMPTY
    else
      puts 'Checking out new upgrade branch...'.bg_green.white
      return false if !GitApi.CheckoutNewBranch(UPGRADE_BRANCH) == Constants::EMPTY
    end

    return true
  end

  def Do config_map, nuget_targets

    @config_map = config_map
    @repo_url = @config_map.metadata.repo_url
    @branch = @config_map.metadata.branch

    # checkout repo and branch
    return false if !GitApi.CheckoutRepoAfresh @repo_url, @branch

    # make upgrade branch
    return false if !checkout_upgrade_branch

    # use local nuget path for restore if provided
    set_local_nuget_target nuget_targets

    # this project-package map helps in incremententing only those semvers where package has changed
    @project_packages = get_repository_package_versions

    # replace versions in package config files
    # this should increment semver if the project produces assembly for a nuget package
    puts "#{Constants::UPGRADE_PROGRESS}Replacing package versions...".bg_green.white
    pkg_files = Dir.glob '**/packages.config'
    if !replace_package_versions(pkg_files)
      puts "#{Constants::UPGRADE_PROGRESS}Package version replacement failed.".red
      return false
    end

    # replace versions in project references
    puts "#{Constants::UPGRADE_PROGRESS}Replacing project versions...".bg_green.white
    proj_files = Dir.glob '**/*.csproj'
    if !replace_project_versions(proj_files)
      puts "#{Constants::UPGRADE_PROGRESS}Project version replacement failed.".red
      return false
    end

    # handle semver increment where packages need it
    puts "#{Constants::UPGRADE_PROGRESS}Upgrading semvers...".bg_green.white
    auto_update_semvers
    nuget_targets << Dir.pwd + '/build_artifacts'
    
    # build and test
    output = ''
    output = system 'rake'
    
    if output.to_s == 'false'
      puts "#{Constants::UPGRADE_PROGRESS}Rake Error: There were errors during rake run.".red
      # save state
      GitApi.CommitChanges( 'Versions updated, build failed')

      return false
    end

    # update version map with nuget versions after build success
    update_version_map
    puts "#{Constants::UPGRADE_PROGRESS}Semver upgraded. Version map updated.".bg_green.white

    true
  end

  def set_local_nuget_target nuget_targets
    num_paths = 1;
    nuget_targets_file = Dir.glob '**/.nuget/Nuget.Config'
    doc = Nokogiri::XML(File.read nuget_targets_file[0])
    nuget_targets.each { |target|
      node_parent = doc.at_css 'packageSources'
      node = Nokogiri::XML::Node.new('add', doc)
      node['key'] = "local_nuget_source#{num_paths}"
      node['value'] = target
      node_parent.add_child node
      num_paths += 1
    }
    if num_paths > 1
      File.write nuget_targets_file[0], doc.to_xml
    end
  end

  def get_repository_package_versions

    v = {}
    # each .semver file has list of projects in its metadata whose assemblies will bear the same version specified

    # load all .project files
    semvers = Dir["#{Constants::SEMVER}/**/*#{Constants::SEMVER}"]

    semvers.each { |s|

      # nuget name is .semver file name
      name = s
        .to_s
        .gsub(Constants::SEMVER, '')
        .gsub('/', '')

      # list of projects
      projects = SemVerMetadata.projects_in_metadata s
      
      projects.each { |x|
        v[x] = name
      }

    }

    v
  end

  def replace_package_versions pkg_files

    begin
      is_package_updated = false
      @semvers_to_increment = []

      # iterate each package file, replace version numbers and save
      pkg_files.each{ |file|
        puts "Finding packages in: #{Dir.pwd}/#{file}...".bg_green.white
        doc = Nokogiri::XML File.read(file)
        nodes = doc.xpath "//*[@id]"
        nodes.each { |node|
          if (@versions.has_key?(node['id']))
            node['version'] = @versions[node['id']] 
            is_package_updated = true
          end
        }

        # save the semver this package file's project is constituent of
        if is_package_updated

          File.write file, doc.to_xml
          proj_name = file
                        .sub(/packages.config/, '')
                        .sub(/.csproj/, '')
                        .sub('/', '')
          
          @semvers_to_increment << "./#{Constants::SEMVER}/#{@project_packages[proj_name]}#{Constants::SEMVER}"
          
          is_package_updated = false
        end
      }
    rescue
      puts $!
      return false
    end

    return true

  end

=begin
    Typical block of reference node change looks like:
    Before:
    <Reference Include="MyLibrary, Version=3.0.0.0, Culture=neutral, PublicKeyToken=b8e0e9f2f1e657fa, processorArchitecture=MSIL">
      <HintPath>..\packages\MyLibrary.3.0.14\lib\net45\MyLibrary.dll</HintPath>
      <Private>True</Private>
    </Reference>
    After: (file version removed, hint path version number updated)
    <Reference Include="MyLibrary">
      <HintPath>..\packages\MyLibrary.3.0.15\lib\net45\MyLibrary.dll</HintPath>
      <Private>True</Private>
    </Reference>
=end
  def replace_project_versions proj_files

    begin
      # iterate each package file, replace version numbers and save
      proj_files.each{ |file|
        puts "Updating references in: #{file}...".bg_green.white
        doc = Nokogiri::XML File.read file
        nodes = doc.search 'Reference'
        nodes.each { |node|

          ref_val = node['Include']
          # grab  the identifier
          id = ref_val.split(',')[0]

          # clean out file version
          node['Include'] = id

          # replace version in hint path
          hint_path = node.search 'HintPath'

          if hint_path && hint_path[0] != nil
            hint_path_value = hint_path[0].children.to_s

            # this identifier is not the same as the node['Include'] one.
            hint_path_id = id_from_hint_path hint_path_value

            if @versions.has_key? hint_path_id
              hint_path_parts = hint_path_value.split '\\'
              hint_path_parts[2] = hint_path_id + Constants::DOT + @versions[hint_path_id]
              hint_path[0].children = hint_path_parts.join '\\'
            end
          end
        }
        File.write file, doc.to_xml
      }
    rescue
      puts $!
      return false
    end

    return true

  end

  def id_from_hint_path path
    p = path.split('\\')
    name = p[p.length - 1].split Constants::DOT
    name_without_ver = Constants::EMPTY
    name.all? {|i|
      if i.to_i == 0
        name_without_ver += i.to_s + Constants::DOT
      end
    }
    name_without_ver
      .sub(/.dll/, '')
      .chomp(Constants::DOT)
  end

  def auto_update_semvers
    @semvers_to_increment.each { |s|
      auto_update_semver s
    }
  end

  def auto_update_semver file
    # patch incremented during upgrade
    v = SemVer.new
    v.load file
    v.patch = v.patch + 1
    v.save file
  end

  def update_version_map
    path = File.join(Dir.pwd, '/build_artifacts/*.nupkg')
    nugets = Dir.glob path
    nugets.each { |nuget|
      full_name = File.basename nuget
      full_name = full_name.sub! '.nupkg', ''
      full_name = full_name.sub! '.symbols', '' if full_name.include? '.symbols'
      dot_pos = full_name.index Constants::DOT
      nuget_name = full_name[0..dot_pos-1]
      nuget_version = full_name[dot_pos+1..full_name.length]
      @versions[nuget_name] = nuget_version
    }
  end
end
