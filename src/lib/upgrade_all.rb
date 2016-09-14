=begin

Uses configuration specified in a manifest file to process 
cascading upgrades at repository level

=end

class UpgradeAll

  MANIFEST_FILE = 'manifest.json'

  def initialize manifest_path = MANIFEST_FILE

    @manifest = JSON.parse File.read(manifest_path) if File.exist? manifest_path

    @version_map = {}

  end

  def manifest
    @manifest
  end

  def version_map
    @version_map
  end

  def Do input_validator

    puts "\n"
    puts "#{Constants::UPGRADE_PROGRESS}Upgrade All has begun..".bg_green.white

    return false if @manifest.nil?

    # validate manifest
    puts "#{Constants::UPGRADE_PROGRESS}Validating manifest...".bg_green.white
    validation_errors = []
    input_validator.validate_manifest(@manifest) do |error|
      validation_errors << error if !error.nil?
    end
    raise StandardError, validation_error_message(validation_errors) if validation_errors.length > 0

    nuget_targets = []
    upgrader = UpgradePackages.new

    # cycle through dependency tree and kick off upgrades
    puts "#{Constants::UPGRADE_PROGRESS}Navigating projects to perform upgrade operation...".bg_green.white
    dep_tree = DependencyTree.new(@manifest['projects'])
    dep_tree.traverse do |node|

      next if check_success_state node

      puts "#{Constants::UPGRADE_PROGRESS} Processing project #{node.project_name}...".bg_green.white

      # validate project node
      puts "#{Constants::UPGRADE_PROGRESS}Validating project node...".bg_green.white
      input_validator.validate_project_node(node) do |error|
        validation_errors << error if !error.nil?
      end
      raise StandardError, validation_error_message(validation_errors) if validation_errors.length > 0

      # the upgrade
      puts "#{Constants::UPGRADE_PROGRESS} Upgrading project #{node.project_name}...".bg_green.white
      upgrade_status = upgrader.Do node, nuget_targets

      # save node name to use for status update
      node_name = get_node_name node

      # project status set in json
      if upgrade_status
        puts "#{Constants::UPGRADE_PROGRESS} Upgrade of #{node.project_name} succeeded".bg_green.white
        @manifest['projects'][node_name]['metadata']['status'] = Constants::SUCCESS
        Dir.chdir Constants::PARENTDIR
      else
        # either cycle was interrupted, a step in upgrade failed or full cycle successfully completed
        # save the version map and manifest
        puts "#{Constants::UPGRADE_PROGRESS} Upgrade of #{node.project_name} failed".red
        @manifest['projects'][node_name]['metadata']['status'] = Constants::FAILED
        # no more processing after failure
        return false
      end

    end

    # upgrade completed successfully, update status as unprocessed and save version map and manifest, push
    reset_status_unprocessed

    true
  end

  def get_node_name node
    if (node.respond_to?('is_root') && node.is_root == 'true')
      name = Constants::ROOT
    else
      name = node.project_name
    end
    name
  end

  def check_success_state node
    status = node.metadata.status == Constants::SUCCESS
    puts "#{Constants::UPGRADE_PROGRESS} Project #{node.project_name} already in #{Constants::SUCCESS} state. Skipping upgrade...".green.bg_white if status
    status
  end

  def reset_status_unprocessed
    @manifest['projects'].each { |proj|
      proj.each { |item|
        item['metadata']['status'] = Constants::UNPROCESSED if item.class.to_s != 'String'
      }
    }
    @manifest
  end

  def validation_error_message validation_errors
    "One or more validation errors have occurred: #{validation_errors.join(' ')}"
  end

end
