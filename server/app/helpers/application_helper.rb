# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  # borrowed from Simply Restful (would rather not import the whole plugin) 
  def dom_id(record, prefix = nil) 
    prefix ||= 'new' unless record.id 
    [ prefix, singular_class_name(record), record.id ].compact * '_'
  end
  
  def singular_class_name(record_or_class)
    class_from_record_or_class(record_or_class).name.underscore.tr('/', '_')
  end
  
  def sort_td_class_helper(param)
    result = 'class="sortup"' if params[:sort] == param
    result = 'class="sortdown"' if params[:sort] == param + "_reverse"
    return result
  end
  
  def sort_link_helper(text, param)
    key = param
    key += "_reverse" if params[:sort] == param
    options = {
        :url => {:action => 'index', :params => params.merge({:sort => key, :page => nil})},
        :method => :get
    }
    html_options = {
      :title => "Sort by this field",
      :href => url_for(:action => 'index', :params => params.merge({:sort => key, :page => nil}))
    }
    link_to(text, options, html_options)
  end  
  
  def dashboard_pulldown_form_for_model(search_class, collection)
    model_class = collection.first.class
    return '<form action="' + search_class.to_s.tableize + '" method="get">' +
    '&nbsp;&nbsp;&nbsp;<select style="width:20em;" id="exact_'+model_class.to_s.underscore+'" name="exact_'+model_class.to_s.underscore+'" onchange="if (this.value != \'\') this.form.submit();">' +
    '<option value="">By: ' + model_class.to_s.underscore.titleize + '</option>' +
    options_from_collection_for_select(collection, 'name', 'name') +
    '</select>' +
    '</form>'
  end
  
  def logged_in_account
    Account.find(session[:account_id])
  end
  
  private
  def class_from_record_or_class(record_or_class)
    record_or_class.is_a?(Class) ? record_or_class : record_or_class.class
  end
  
end
