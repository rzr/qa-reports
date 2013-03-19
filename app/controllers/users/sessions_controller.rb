require 'uri'

class Users::SessionsController < Devise::SessionsController
  before_filter :save_path, :only => :new

  private

  def save_path
    # Prevent redirect loop by not setting the return_to value if it would
    # redirect back to the sign_in page
    # TODO: Redirectin go referrer is baad. Should be so that login link
    # gives next in e.g. query string, and if entering directly to a page
    # requiring authentication the request uri is set to the query string param
    begin
      session[:return_to] = request.referrer unless URI::parse(request.referrer).path == '/users/sign_in'
    rescue URI::InvalidURIError
      session[:return_to] = nil
    end
  end

  def after_sign_in_path_for(resource)
    session[:return_to].nil? ? '/' : session[:return_to]
  end
end
