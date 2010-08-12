require 'test_helper'

class PerlCliTest < ActiveSupport::TestCase

  def test_get
    # --get
    get = `cd $NVENTORYC/perl && ./nv --get name=vnventory1`
    assert_equal( 'irvnventory1',get.chomp )
  end
  
  def test_name
    # --name (same as --get)
    name = `cd $NVENTORYC/perl && ./nv --name testte`
    assert_equal( name.chomp , 'testtest' )
  end

  def test_multi_or_get
    # --get (multiple 'or')
    name = `cd $NVENTORYC/perl && ./nv --get name=testte,one`.split("\n")
    assert_equal( name.size , 2 )
    assert name.include?('NodeOne')
    assert name.include?('testtest')
  end

  def test_exactget_false
    # --exactget (false)
    exactget = `cd $NVENTORYC/perl && ./nv --exactget name=test`
    assert_not_equal( exactget.chomp , 'testtest' )
  end

  def test_exactget
    # --exactget
    exactget = `cd $NVENTORYC/perl && ./nv --exactget name=testtest`
    assert_equal( exactget.chomp , 'testtest' )
  end

  def test_regexget
    # --regexget
    regexget = `cd $NVENTORYC/perl && ./nv --regexget name=[a-u]esttest`
    assert_equal( regexget.chomp , 'testtest' )
  end

  def test_regexget_false
    # --regexget (false)
    regexget = `cd $NVENTORYC/perl && ./nv --regexget name=[a-b]esttest`
    assert_not_equal( regexget.chomp , 'testtest' )
  end

  def test_exclude
    # --exclude
    excludeget = `cd $NVENTORYC/perl && ./nv --get name=node --exclude name=One`.split("\n")
    assert_equal( excludeget.size , 2 )
    assert_not_equal( excludeget[0], 'node0ne' )
    assert_not_equal( excludeget[1], 'node0ne' )
  end

  def test_allfields
    # --allfields
    allfieldsget = `cd $NVENTORYC/perl && ./nv --get name=testtest --allfields`.split("\n")
    assert( allfieldsget.size > 60 )
    assert( allfieldsget.grep(/hardware_profile/).size => 25 )
    assert( allfieldsget.grep(/status\[name\]:\s+inservice/) )
  end

  def test_fields
    # --fields
    fieldsget = `cd $NVENTORYC/perl && ./nv --get name=testtest --fields status[name],hardware_profile[processor_count]`.split("\n")
    assert( fieldsget.size , 3 )
    assert( fieldsget.include?("hardware_profile[processor_count]: 1") )
    assert( fieldsget.include?("status[name]: inservice") )
  end

  def test_withaliases
    # --withaliases
    aliasget = `cd $NVENTORYC/perl && ./nv --get name=testalias --withaliases`
    assert_equal( aliasget.chomp , 'testtest' )
  end

  def test_objecttype
    # --objecttype --get
    objtypeget = `cd $NVENTORYC/perl && ./nv --objecttype operating_systems --get name=centos_5`
    assert_equal( objtypeget.chomp , 'centos 5' )
  end

  def test_and
    # --and
    andget = `cd $NVENTORYC/perl && ./nv --get name=two --and name=three`.split("\n")
    assert_equal( andget.size , 1 )
    assert_equal( andget[0], 'NodeTwoThree' )
  end

  def test_set
    # --set
    set = `cd $NVENTORYC/perl && echo y | ./nv --get name=testtest --set processor_count=9999 --username testuser`
    setget = `cd $NVENTORYC/perl && ./nv --get name=testtest --fields processor_count`.split("\n")
    assert( setget.include?("processor_count: 9999") )
  end

  def test_register
    # --register
    user = `whoami`.chomp
    if user == 'root'
      hostname = `hostname`.chomp
      register = `cd $NVENTORYC/perl && ./nv --register`
      afterget = `cd $NVENTORYC/perl && ./nv --get name=#{hostname} --field name`.split("\n")
      assert_equal( afterget.size , 2 )
      assert( afterget.include?("name: #{hostname}") )
    else
      puts "\n\n******* Skipping --register test, must be ran as root ******\n\n"
    end
  end

  def test_set_node_groups
    # --set node_groups
    ng_get = `cd $NVENTORYC/perl && ./nv --ng NodeGroupOne`.split("\n")
    assert_match(/NodeGroupTwo/, ng_get[1])
    assert_match(/NodeOne/, ng_get[4])
    assert_match(/NodeTwo/,ng_get[7])
  end

  def test_nodegroup
    # --nodegroup
    ng_get = `cd $NVENTORYC/perl && ./nv --nodegroup NodeGroupOne`.split("\n")
    assert_match(/NodeGroupTwo/, ng_get[1])
    assert_match(/NodeOne/, ng_get[4])
    assert_match(/NodeTwo/, ng_get[7])
  end

  def test_getfieldnames
    exclude = %w( Node UtilizationMetric Audit HardwareProfile )
    getfieldnames = `cd $NVENTORYC/perl && ./nv --getfieldnames`.split("\n")
    Node.reflect_on_all_associations.each do |assoc|
      next if exclude.include?(assoc.class_name.to_s)
      next if assoc.class_name.tableize.to_s =~ /_assignment/
      num_attrs = assoc.class_name.constantize.column_names.collect { |column| column unless column =~ /id$/ }.compact.size
      assocname = assoc.class_name.tableize.singularize
      assert( getfieldnames.grep(/#{assocname}/).size => num_attrs )
    end
  end

  def test_get_obj_fieldnames
    getfieldnames = `cd $NVENTORYC/perl && ./nv --objecttype node_groups --getfieldnames`.split("\n")
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
    get_ngn = `cd $NVENTORYC/perl && ./nv --get_ngn NodeGroupOne`.split("\n")
    assert_equal( get_ngn[0] , 'NodeOne' )
    assert_equal( get_ngn[1] , 'NodeTwo' )
    # aka --get_nodegroup_nodes
    get_ngn = `cd $NVENTORYC/perl && ./nv --get_nodegroup_nodes NodeGroupOne`.split("\n")
    assert_equal( get_ngn[0] , 'NodeOne' )
    assert_equal( get_ngn[1] , 'NodeTwo' )
    # aka --nodegroupexpanded
    get_nge = `cd $NVENTORYC/perl && ./nv --nodegroupexpanded NodeGroupOne`.split("\n")
    assert_equal( get_nge[0] , 'NodeOne' )
    assert_equal( get_nge[1] , 'NodeTwo' )
  end

  def test_createnodegroup
    create_ng = `cd $NVENTORYC/perl && ./nv --createnodegroup 1newgroup,2newgroup`
    list = create_ng.split("\n")
    result = false if list.size != 0
    objtypeget = `cd $NVENTORYC/perl && ./nv --objecttype node_groups --get name=newgroup`
    list = objtypeget.split("\n")
    result = false unless list.size == 2
    result = false unless list[0] == '1newgroup'
    result = false unless list[1] == '2newgroup'
    result = true unless result == false
    assert result
  end

  def test_addtonodegroup
    objtypeget = `cd $NVENTORYC/perl && ./nv --objecttype node_groups --get name=four`.split("\n")
    assert_equal(objtypeget[0], 'NodeGroupFour')
    addtonodegroup = `cd $NVENTORYC/perl && echo y|./nv --get name=testtest --addtonodegroup NodeGroupThree,NodeGroupFour --username testuser`.split("\n")
    assert_equal(addtonodegroup[3], 'Command completed successfully')
    get_nge = `cd $NVENTORYC/perl && ./nv --nodegroupexpanded NodeGroupThree`.split("\n")
    result = false unless get_nge.include?('testtest')
    get_nge = `cd $NVENTORYC/perl && ./nv --nodegroupexpanded NodeGroupFour`.split("\n")
    result = false unless get_nge.include?('testtest')
    result = true unless result == false
    assert result
  end

  def test_removefromnodegroup
    addtonodegroup = `cd $NVENTORYC/perl && echo y|./nv --get name=testtest --addtonodegroup NodeGroupThree,NodeGroupFour --username testuser`.split("\n")
    get_nge = `cd $NVENTORYC/perl && ./nv --nodegroupexpanded NodeGroupThree`.split("\n")
    result = false unless get_nge.include?('testtest')
    get_nge = `cd $NVENTORYC/perl && ./nv --nodegroupexpanded NodeGroupFour`.split("\n")
    result = false unless get_nge.include?('testtest')
    removefromnodegroup = `cd $NVENTORYC/perl && echo y|./nv --get name=testtest --removefromnodegroup NodeGroupThree,NodeGroupFour --username testuser`.split("\n")
    get_nge = `cd $NVENTORYC/perl && ./nv --nodegroupexpanded NodeGroupThree`.split("\n")
    result = false unless get_nge.size == 1 && get_nge[0] == 'No matching objects'
    get_nge = `cd $NVENTORYC/perl && ./nv --nodegroupexpanded NodeGroupFour`.split("\n")
    result = false unless get_nge.size == 1 && get_nge[0] == 'No matching objects'
    result = true unless result == false
    assert result
  end

  def test_addcomment
    addtonodegroup = `cd $NVENTORYC/perl && echo y|./nv --get name=testtest --addcomment "this is a test ignore" --username testuser`.split("\n")
    result = false unless addtonodegroup.size == 2
    result = false if addtonodegroup[0] != 'testtest'
    result = false if addtonodegroup[1] !~ /This will update 1 entry, continue\?  \[y\/N\]:/
    getcomments = `cd $NVENTORYC/perl && echo y|./nv --get name=testtest --fields comments[comment]`.split("\n")
    result = false if getcomments[1] != 'comments[comment]: this is a test ignore'
    result = true unless result == false
    assert result
  end

  def test_delete
    exactget = `cd $NVENTORYC/perl && ./nv --exactget name=testdelete`.split("\n")
    assert_equal( exactget.size , 1 )
    delete = `cd $NVENTORYC/perl && echo y|./nv --get name=testdelete --delete --username=testuser`.split("\n")
    assert_equal( delete.size , 5 )
    exactget = `cd $NVENTORYC/perl && ./nv --exactget name=testdelete`.split("\n")
    assert_equal( exactget.size , 1 ) 
    assert( exactget.include?('No matching objects') )
  end

  def test_multi_assocs
    multiget = `cd $NVENTORYC/perl && ./nv --get node_group[name]=NodeGroupOne --name=On --get ip_addresses[address]=192.168 --exactget status[name]=inservice`.split("\n")
    assert_equal( multiget.size, 1 )
    assert_equal( multiget[0], 'NodeOne' )
  end

  def test_datacenter_rack
    getnr = `cd $NVENTORYC/perl && ./nv --get name=testtest --fields rack`.split("\n")
    assert_equal( getnr.size, 2 )
    assert_equal( getnr[1] , 'node_rack_node_assignment[node_rack][name]: testrack1' )
    getdc = `cd $NVENTORYC/perl && ./nv --get name=testtest --fields datacenter`.split("\n")
    assert_equal( getdc.size, 2 )
    assert_equal( getdc[1] , 'node_rack_node_assignment[node_rack][datacenter_node_rack_assignment][datacenter][name]: testdatacenter1' )
  end

end
