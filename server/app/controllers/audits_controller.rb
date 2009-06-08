class AuditsController < ApplicationController
  # GET /audits
  # GET /audits.xml
  def index

    default_includes = []
    special_joins = {}
    # Custom sort parameter because we want to see the latest changes first
    params[:sort] = 'created_at_reverse'

    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = Audit
    allparams[:webparams] = params
    allparams[:default_includes] = default_includes
    allparams[:special_joins] = special_joins

    results = SearchController.new.search(allparams)
    flash[:error] = results[:errors].join('<br />') unless results[:errors].empty?
    includes = results[:includes]
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
    includes = process_includes(Audit, params[:include])

    @audit = Audit.find(params[:id],
                            :include => includes)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @audit.to_xml(:include => convert_includes(includes),
                                                   :dasherize => false) }
    end
  end


end
