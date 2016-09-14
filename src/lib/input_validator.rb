class InputValidator

  def initialize
    @simple_validator = SimpleValidator.new
  end

  def test_mode
    @test_mode = true
  end

  # We should do more specific test of which environment variables are we expecting or which metatdata are we expecting
  #if project publishes nuget we need to check if major /minor/patch incrmeented but not all 3

  def validate_version_map version_map
    if version_map.nil? || version_map.class.to_s != Constants::HASH
      yield 'Version map must be a non-empty ' + Constants::HASH
    end
  end

  def validate_manifest m

    manifest = Hashit.new m
    puts 'Validating upgrade manifest...'.bg_green.white

    if manifest.nil? || manifest.class.to_s != 'Hashit'
      yield 'Config map must be a non-nil class of type Hashit'
    end

    node_name = 'manifest'
    yield @simple_validator.method_exists manifest, 'version_source', node_name
    yield @simple_validator.method_value_not_nil manifest, 'version_source', node_name
    yield @simple_validator.method_exists manifest.version_source, 'repo_url', node_name
    yield @simple_validator.method_value_not_nil_or_empty manifest.version_source, 'repo_url', node_name
    yield @simple_validator.method_exists manifest.version_source, 'branch', node_name
    yield @simple_validator.method_value_not_nil_or_empty manifest.version_source, 'branch', node_name
    yield @simple_validator.method_exists manifest, 'projects', node_name
    yield @simple_validator.method_value_not_nil manifest, 'projects', node_name
  end

  def validate_project_node project

    node_name = 'project'

    yield @simple_validator.method_exists project, 'next', node_name
    #yield @simple_validator.method_value_not_nil_or_empty project, 'next', node_name

    yield @simple_validator.method_exists project, 'previous', node_name
    #yield @simple_validator.method_value_not_nil_or_empty project, 'previous', node_name

    node_name = 'project.metadata'
    yield @simple_validator.method_exists project.metadata, 'repo_url', node_name
    yield @simple_validator.method_value_not_nil_or_empty project.metadata, 'repo_url', node_name

    yield @simple_validator.method_exists project.metadata, 'branch', node_name
    yield @simple_validator.method_value_not_nil_or_empty project.metadata, 'branch', node_name

    yield @simple_validator.method_exists project.metadata, 'status', node_name
    yield @simple_validator.method_value_not_nil_or_empty project.metadata, 'status', node_name

  end

end

# nil return is treated as no error
class SimpleValidator

  CANNOT_CONTINUE = '. Cannot continue!'
  IS_MISSING = ' is missing'

  def method_exists object, method, name
    begin
      if !object.respond_to? method
        "#{name}\'s method: *#{method}*" + IS_MISSING
      end
    rescue
      nil
    end
  end

  def method_value_not_nil_or_empty object, method, name
    begin
      value = object.send method
      if value == nil || value.to_s.strip.length == 0
        "#{name}\'s *#{method}* value is empty or" + IS_MISSING
      end
    rescue
      nil
    end
  end

  def method_value_not_nil object, method, name
    begin
      value = object.send method
      if value == nil
        "#{name}\'s *#{method}* value" + IS_MISSING
      end
    rescue
      nil
    end
  end
end
