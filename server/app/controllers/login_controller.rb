class LoginController < ApplicationController
  # Ensure that login activity occurs over SSL since the user is
  # transmitting his password to us.  This functionality courtesy of
  # the ssl_requirement plugin, which is enabled in application.rb
  if MyConfig.redirect_login_to_ssl
    ssl_required :login
  end

  def index
    unless session[:sso] == true
      redirect_to :action => "login" and return
    else
      redirect_to :controller => 'dashboard' and return
    end
  end
  
  def login
    if session[:sso] == true
      redirect_to :controller => 'dashboard' and return
    end
    session[:account_id] = nil
    if request.post? 
      account = Account.authenticate(params[:login], params[:password])
      if (account)
        session[:account_id] = account.id
        uri = session[:original_uri] 
        session[:original_uri] = nil 
        redirect_to(uri || { :controller => 'dashboard' })
      else 
        flash[:error] = "Invalid login/password combination"
        session[:account_id] = nil
        redirect_to :controller => 'login', :action => 'login'
      end
    end 
  end

  def sso
    if @sso = sso_auth
      redirect_to :controller => 'dashboard' and return
    end
  end
  
  def logout
    session[:account_id] = nil 
    flash[:notice] = "Logged out" 
    redirect_to(:action => "login") and return
  end
  
end
