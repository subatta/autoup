require_relative '../lib/dependency_tree'
require_relative '../lib/constants'
require_relative '../lib/hash_extensions'
require 'test/unit'

class TestDependencyTree < Test::Unit::TestCase

  ONTOLOGY = 'Ontology'
  FHIRWALKER = 'FhirWalker'
  FHIRSERVICE = 'FhirService'

  def test_empty_tree_returns_nil_for_root
    depends = DependencyTree.new nil
    assert_equal(nil, depends.root)
  end

  def test_empty_tree_returns_nil_for_next_if_current_nil
    depends = DependencyTree.new nil
    assert_equal(nil, depends.next_node(nil))
  end

  def test_empty_tree_returns_nil_for_next
    depends = DependencyTree.new nil
    assert_equal(nil, depends.next_node('src'))
  end

  def test_empty_tree_returns_nil_for_previous_if_current_nil
    depends = DependencyTree.new nil
    assert_equal(nil, depends.previous_node(nil))
  end

  def test_empty_tree_returns_nil_for_previous
    depends = DependencyTree.new nil
    assert_equal(nil, depends.previous_node('src'))
  end

  def test_tree_returns_nil_for_root_previous
    depends = DependencyTree.new(Constants::ROOT => {Constants::PROJECTNAME => ONTOLOGY, Constants::PREVIOUS => nil})
    assert_equal(nil, depends.previous_node(Constants::ROOT))
  end

  def test_root_node_found
    depends = DependencyTree.new(Constants::ROOT => {Constants::PROJECTNAME => ONTOLOGY})
    assert_equal(ONTOLOGY, depends.root.project_name)
  end

  def test_next_node_found
    depends = DependencyTree.new(Constants::ROOT => {Constants::PROJECTNAME => ONTOLOGY, Constants::NEXT => FHIRWALKER}, FHIRWALKER => {Constants::PROJECTNAME => FHIRWALKER, Constants::NEXT => ''})
    assert_equal(FHIRWALKER, depends.next_node(Constants::ROOT).project_name)
  end

  def test_prev_node_found
    depends = DependencyTree.new(Constants::ROOT => {Constants::PROJECTNAME => ONTOLOGY, Constants::NEXT => FHIRWALKER}, FHIRWALKER => {Constants::PROJECTNAME => FHIRWALKER, Constants::NEXT => '', Constants::PREVIOUS => ONTOLOGY})
    assert_equal(ONTOLOGY, depends.previous_node(FHIRWALKER).project_name)
  end

  def test_root_node_not_found
    depends = DependencyTree.new(Constants::ROOT => {Constants::PROJECTNAME => ONTOLOGY})
    assert_not_equal(Constants::ROOT, depends.root)
  end

  def test_next_node_not_found
    depends = DependencyTree.new(Constants::ROOT => {Constants::PROJECTNAME => ONTOLOGY, Constants::NEXT => FHIRSERVICE})
    assert_not_equal(FHIRWALKER, depends.next_node(Constants::ROOT))
  end

  def test_prev_node_not_found
    depends = DependencyTree.new(Constants::ROOT => {Constants::PROJECTNAME => FHIRWALKER, Constants::PREVIOUS => Constants::ROOT, Constants::NEXT => FHIRSERVICE})
    assert_not_equal(ONTOLOGY, depends.previous_node(Constants::ROOT))
  end

  def test_traverse
    depends = DependencyTree.new(
      Constants::ROOT => {
        Constants::PROJECTNAME => ONTOLOGY,
        Constants::PREVIOUS => nil,
        Constants::NEXT => FHIRWALKER
      },
      FHIRWALKER => {
        Constants::PROJECTNAME => FHIRWALKER,
        Constants::PREVIOUS => Constants::ROOT,
        Constants::NEXT => FHIRSERVICE
      }
    )

    expected = [ONTOLOGY, FHIRWALKER]
    actual = []
    depends.traverse do |node|
      actual << node.project_name if !node.nil?
    end

    assert_equal expected, actual
  end
end
