require 'test_helper'

class PerlCliTest < ActiveSupport::TestCase
  raise "$NVENTORYC not set.  Set this env var to the dir where your nventory client trunk exists" unless ENV["NVENTORYC"]

  def test_params
    # --get
    get = `cd $NVENTORYC/ruby && ./nv --get name=testt`.chomp
    assert_equal( get, 'testtest' )
    # --name (same as --get)
    name = `cd $NVENTORYC/ruby && ./nv --name testt`.chomp
    assert_equal( name, 'testtest' )
    # --get (multiple 'or')
    name = `cd $NVENTORYC/ruby && ./nv --get name=testt,one`.split("\n")
    assert_equal( name.size , 2 )
    assert name.include?('NodeOne')
    assert name.include?('testtest')
    # --exactget (false)
    exactget = `cd $NVENTORYC/ruby && ./nv --exactget name=test`
    assert_not_equal( exactget.chomp , 'testtest' )
    # --exactget
    exactget = `cd $NVENTORYC/ruby && ./nv --exactget name=testtest`
    assert_equal( exactget.chomp , 'testtest' )
    # --regexget
    regexget = `cd $NVENTORYC/ruby && ./nv --regexget name=[a-u]esttest`
    assert_equal( regexget.chomp , 'testtest' )
    # --regexget (false)
    regexget = `cd $NVENTORYC/ruby && ./nv --regexget name=[a-b]esttest`
    assert_not_equal( regexget.chomp , 'testtest' )
    # --exclude
    excludeget = `cd $NVENTORYC/ruby && ./nv --get name=node --exclude name=One`.split("\n")
    assert_equal( excludeget.size , 2 )
    assert_not_equal( excludeget[0], 'node0ne' )
    assert_not_equal( excludeget[1], 'node0ne' )
    # --allfields
    allfieldsget = `cd $NVENTORYC/ruby && ./nv --get name=testtest --allfields`.split("\n")
    assert( allfieldsget.size > 60 )
    assert( allfieldsget.grep(/hardware_profile/).size => 25 )
    assert( allfieldsget.grep(/status\[name\]:\s+inservice/) )
    # --fields
    fieldsget = `cd $NVENTORYC/ruby && ./nv --get name=testtest --fields status[name],hardware_profile[processor_count]`.split("\n")
    assert( fieldsget.size , 3 )
    assert( fieldsget.include?("hardware_profile[processor_count]: 1") )
    assert( fieldsget.include?("status[name]: inservice") )
    # --withaliases
    aliasget = `cd $NVENTORYC/ruby && ./nv --get name=testalias --withaliases`
    assert_equal( aliasget.chomp , 'testtest' )
    # --objecttype --get
    objtypeget = `cd $NVENTORYC/ruby && ./nv --objecttype operating_systems --get name=centos_5`
    assert_equal( objtypeget.chomp , 'centos 5' )
    # --and
    andget = `cd $NVENTORYC/ruby && ./nv --get name=two --and name=three`.split("\n")
    assert_equal( andget.size , 2 )
    assert_equal( andget[0], 'NodeTwo' )
    assert_equal( andget[1], 'NodeTwoThree' )
    # --set
    set = `cd $NVENTORYC/ruby && echo y | ./nv --get name=testtest --set processor_count=9999 --username testuser`
    setget = `cd $NVENTORYC/ruby && ./nv --get name=testtest --fields processor_count`.split("\n")
    assert( setget.include?("processor_count: 9999") )
    # --register
    user = `whoami`.chomp
    if user == 'root'
      hostname = `hostname`.chomp
      register = `cd $NVENTORYC/ruby && ./nv --register`
      afterget = `cd $NVENTORYC/ruby && ./nv --get name=#{hostname} --field name`.split("\n")
      assert_equal( afterget.size , 2 )
      assert( afterget.include?("name: #{hostname}") )
    else
      puts "\n\n******* Skipping --register test, must be ran as root ******\n\n"
    end
    # --set node_groups
    ng_get = `cd $NVENTORYC/ruby && ./nv --ng NodeGroupOne`.split("\n")
    assert_match(/NodeGroupTwo/, ng_get[1])
    assert_match(/NodeOne/, ng_get[4])
    assert_match(/NodeTwo/,ng_get[7])
    # --nodegroup
    ng_get = `cd $NVENTORYC/ruby && ./nv --nodegroup NodeGroupOne`.split("\n")
    assert_match(/NodeGroupTwo/, ng_get[1])
    assert_match(/NodeOne/, ng_get[4])
    assert_match(/NodeTwo/, ng_get[7])
  end

  def test_getfieldnames
    exclude = %w( Node UtilizationMetric Audit HardwareProfile )
    getfieldnames = `cd $NVENTORYC/ruby && ./nv --getfieldnames`.split("\n")
    Node.reflect_on_all_associations.each do |assoc|
      next if exclude.include?(assoc.class_name.to_s)
      next if assoc.class_name.tableize.to_s =~ /_assignment/
      num_attrs = assoc.class_name.constantize.column_names.collect { |column| column unless column =~ /id$/ }.compact.size
      assocname = assoc.class_name.tableize.singularize
      assert( getfieldnames.grep(/#{assocname}/).size => num_attrs )
    end
  end

  def test_get_obj_fieldnames
    getfieldnames = `cd $NVENTORYC/ruby && ./nv --objecttype node_groups --getfieldnames`.split("\n")
    exclude = %w( UtilizationMetric Audit HardwareProfile NodeGroup Node )
    NodeGroup.reflect_on_all_associations.each do |assoc|
      next if exclude.include?(assoc.class_name.to_s)
      next if assoc.class_name.tableize.to_s =~ /_assignment/
      num_attrs = assoc.class_name.constantize.column_names.collect { |column| column unless column =~ /(id|_at)$/ }.compact.size
      assocname = assoc.class_name.tableize.singularize
      assert( getfieldnames.grep(/#{assocname}/).size => num_attrs )
    end
  end


  def test_get_ngn
    # --get_ngn
    get_ngn = `cd $NVENTORYC/ruby && ./nv --get_ngn NodeGroupOne`.split("\n")
    assert_equal( get_ngn[0] , 'NodeOne' )
    assert_equal( get_ngn[1] , 'NodeTwo' )
    # aka --get_nodegroup_nodes
    get_ngn = `cd $NVENTORYC/ruby && ./nv --get_nodegroup_nodes NodeGroupOne`.split("\n")
    assert_equal( get_ngn[0] , 'NodeOne' )
    assert_equal( get_ngn[1] , 'NodeTwo' )
    # aka --nodegroupexpanded
    get_nge = `cd $NVENTORYC/ruby && ./nv --nodegroupexpanded NodeGroupOne`.split("\n")
    assert_equal( get_nge[0] , 'NodeOne' )
    assert_equal( get_nge[1] , 'NodeTwo' )
  end

  def test_createnodegroup
    create_ng = `cd $NVENTORYC/ruby && ./nv --createnodegroup 1newgroup,2newgroup`
    list = create_ng.split("\n")
    result = false if list.size != 0
    objtypeget = `cd $NVENTORYC/ruby && ./nv --objecttype node_groups --get name=newgroup`
    list = objtypeget.split("\n")
    result = false unless list.size == 2
    result = false unless list[0] == '1newgroup'
    result = false unless list[1] == '2newgroup'
    result = true unless result == false
    assert result
  end

  def test_addtonodegroup
    addtonodegroup = `cd $NVENTORYC/ruby && echo y|./nv --get name=testtest --addtonodegroup NodeGroupThree,NodeGroupFour --username testuser`.split("\n")
    assert( addtonodegroup.empty? )
    get_nge = `cd $NVENTORYC/ruby && ./nv --nodegroupexpanded NodeGroupThree`.split("\n")
    assert( get_nge.include?('testtest') )
    get_nge = `cd $NVENTORYC/ruby && ./nv --nodegroupexpanded NodeGroupFour`.split("\n")
    assert( get_nge.include?('testtest') )
  end

  def test_removefromnodegroup
    addtonodegroup = `cd $NVENTORYC/ruby && echo y|./nv --get name=testtest --addtonodegroup NodeGroupThree,NodeGroupFour --username testuser`.split("\n")
    get_nge = `cd $NVENTORYC/ruby && ./nv --nodegroupexpanded NodeGroupThree`.split("\n")
    assert( get_nge.include?('testtest') )
    get_nge = `cd $NVENTORYC/ruby && ./nv --nodegroupexpanded NodeGroupFour`.split("\n")
    assert( get_nge.include?('testtest') )
    removefromnodegroup = `cd $NVENTORYC/ruby && echo y|./nv --get name=testtest --removefromnodegroup NodeGroupThree,NodeGroupFour --username testuser`.split("\n")
    get_nge = `cd $NVENTORYC/ruby && ./nv --nodegroupexpanded NodeGroupThree`.split("\n")
    assert_equal( get_nge.size , 1 ) 
    assert_equal( get_nge[0] , 'No matching objects' )
    get_nge = `cd $NVENTORYC/ruby && ./nv --nodegroupexpanded NodeGroupFour`.split("\n")
    assert_equal( get_nge.size , 1 )
    assert_equal( get_nge[0] , 'No matching objects' )
  end

  def test_addcomment
    addcomment = `cd $NVENTORYC/ruby && echo y|./nv --get name=testtest --addcomment "this is a test ignore" --username testuser`.split("\n")
    assert_equal( addcomment.size , 1 )
    assert_equal( addcomment[0] , 'testtest' )
    getcomments = `cd $NVENTORYC/ruby && echo y|./nv --get name=testtest --fields comments[comment]`.split("\n")
    assert_equal( getcomments[1] , 'comments[comment]: this is a test ignore' )
  end

  def test_delete
    exactget = `cd $NVENTORYC/ruby && ./nv --exactget name=testdelete`.split("\n")
    assert_equal( exactget.size , 1 )
    delete = `cd $NVENTORYC/ruby && echo y|./nv --get name=testdelete --delete --username=testuser`.split("\n")
    assert_equal( delete.size , 1 )
    exactget = `cd $NVENTORYC/ruby && ./nv --exactget name=testdelete`.split("\n")
    assert_equal( exactget.size , 1 ) 
    assert( exactget.include?('No matching objects') )
  end

  def test_multi_assocs
    multiget = `cd $NVENTORYC/ruby && ./nv --get node_group[name]=NodeGroupOne --name=On --get ip_addresses[address]=192.168 --exactget status[name]=inservice`.split("\n")
    assert_equal( multiget.size, 1 )
    assert_equal( multiget[0], 'NodeOne' )
  end

end
