class CsvController < ApplicationController
  def export
    @csvparams = session[:csvobj]
    @csvparams[:attributes] = params[:attributes]
    @csvparams[:username] = current_user.login
    CsvWorker.async_sendata(:csvparams => @csvparams)
    respond_to do |format|
      format.html
    end
  end
end
