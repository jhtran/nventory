class AuditsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /audits
  # GET /audits.xml
  def index
    special_joins = {}
    # Custom sort parameter because we want to see the latest changes first
    params[:sort] = 'created_at_reverse'

    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = Audit
    allparams[:webparams] = params
    allparams[:special_joins] = special_joins

    results = Search.new(allparams).search
    flash[:error] = results[:errors].join('<br />') unless results[:errors].empty?
    includes = results[:includes]
    results[:requested_includes].each_pair{|k,v| includes[k] = v}
    @objects = results[:search_results]

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:include => convert_includes(includes),
                                                   :dasherize => false) }
    end
  end

  # GET /audits/1
  # GET /audits/1.xml
  def show
    @audit = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @audit.to_xml(:include => convert_includes(includes),
                                                   :dasherize => false) }
    end
  end


end
