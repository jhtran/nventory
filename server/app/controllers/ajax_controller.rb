class AjaxController < ApplicationController

  def sort_nodes_in_rack
    rack = Rack.find(params[:id])
    rack.rack_node_assignments.each do |assignment|
      new_position = params['node-list'].index(assignment.id.to_s) + 1
      assignment.position = new_position
      assignment.save
    end
    render :nothing => true
  end

end
