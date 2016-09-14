=begin
    Defines a simple dependency tree in a hash map and allows accessing top and Constants::NEXT item in the tree.
    - The keys 'Constants::ROOT, Constants::NEXT, Constants::PREVIOUS and Constants::PROJECTNAME_NAME' are self-descriptive
    - Constants::ROOT's Constants::PREVIOUS is always nil, so are all leaf node Constants::NEXT
    {
        "Constants::ROOT" => {
            "Constants::PROJECTNAME" => "Ontology", 
            "Constants::NEXT" => "FhirWalker", 
            "Constants::PREVIOUS" => nil, 
            "metadata" => "[json or another hash]" 
        },
        "FhirWalker" => {
            "Constants::PROJECTNAME" => "Portal", 
            "Constants::NEXT" => "EventTracking", 
            "Constants::PREVIOUS" => "Ontology", 
            "metadata" => "[json or another hash]" 
        }
    }
=end


class DependencyTree

  def initialize dependency_map
    @dependency_map = dependency_map
  end

  def root
    return nil if @dependency_map.nil? || @dependency_map.class.to_s != Constants::HASH || @dependency_map.empty?

    if @dependency_map.has_key?(Constants::ROOT)
      if @dependency_map[Constants::ROOT].has_key? Constants::PROJECTNAME
        root_node = Hashit.new @dependency_map[Constants::ROOT]
        root_node
      end
    end
  end

  def next_node current
    return nil if current.to_s.strip.length == 0
    return nil if @dependency_map.nil? || @dependency_map.class.to_s != Constants::HASH || @dependency_map.empty?

    current = Constants::ROOT  if @dependency_map[Constants::ROOT][Constants::PROJECTNAME] == current
    if @dependency_map[current].has_key? Constants::NEXT
      next_node = @dependency_map[current][Constants::NEXT]
      next_node = @dependency_map[next_node]
      next_node = Hashit.new next_node if !next_node.nil?
    end
  end

  def previous_node current
    return nil if current.to_s.strip.length == 0
    return nil if @dependency_map.nil? || @dependency_map.class.to_s != Constants::HASH || @dependency_map.empty?

    if @dependency_map[current].has_key? Constants::PREVIOUS
      prev_node = @dependency_map[current][Constants::PREVIOUS]
      if @dependency_map[Constants::ROOT][Constants::PROJECTNAME] == prev_node
        prev_node = @dependency_map[Constants::ROOT]
      else
        prev_node = @dependency_map[prev_node]
      end
      return nil if prev_node.nil?
      return Hashit.new prev_node
    end
  end

  def traverse
    current = Constants::ROOT
    current = @dependency_map[current]
    current = Hashit.new current
    yield current
    while current != nil
      begin
        current = next_node current.project_name
      rescue
        #puts $!
        current = nil
      end
      yield current unless current.nil?
    end
  end

end
