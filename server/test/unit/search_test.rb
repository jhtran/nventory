require File.dirname(__FILE__) + '/../test_helper'

class SearchTest < ActiveRecord::TestCase
  
  def test_initialize
    result = Search.new({:mainmodel => Node, :webparams => {'name' => 'irvnventory1'}})
    assert_instance_of Search,result
  end

  def test_search
    data = Search.new({:mainmodel => Node, :webparams => {'name' => 'nventory'}}).search
    # basic default search
    assert data[:errors].empty?, "search hash returned errors"
    assert data[:requested_includes].empty?, "should return empty requested includes"
    assert_instance_of WillPaginate::Collection,data[:search_results], 'search results returned mismatch obj type'
    assert_nil data[:csvobj]
    Node.default_includes.each do |include|
      assert data[:includes].include?(include)
    end
    assert_equal 2,data[:search_results].size, "# of results returned mismatch"
    # exact search
    data = Search.new({:mainmodel => Node, :webparams => {'exact_name' => 'nventory'}}).search
    assert data[:search_results].empty?, "# of results returned mismatch"
    data = Search.new({:mainmodel => Node, :webparams => {'exact_name' => 'irvnventory1'}}).search
    assert_equal 1,data[:search_results].size, "# of results returned mismatch"
    # search all records
    data = Search.new({:mainmodel => Node, :webparams => {'name' => ''}}).search
    assert_equal 2,data[:search_results].size, "# of results returned mismatch"
  end
end
