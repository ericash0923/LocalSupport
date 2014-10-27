require 'custom_errors'

class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :store_location, :assign_footer_page_links

  include CustomErrors

  # To prevent infinite redirect loops, only requests from white listed
  # controllers are available in the "after sign-in redirect" feature
  def white_listed
    %w(
        application
        contributors
        organisations
        pages
    )
  end

  def request_controller_is(white_listed)
    white_listed.include? request.params['controller']
  end

  def request_verb_is_get?
    request.env['REQUEST_METHOD'] == 'GET'
  end

  # Stores the URL if permitted
  def store_location
    if request_controller_is(white_listed) && request_verb_is_get?
      session[:previous_url] = request.path
    end
  end

  # Devise hook
  # Returns the users to the page they were viewing before signing in
  def after_sign_in_path_for(resource)
    set_flash_warning_reminder_to_update_details resource
    return edit_user_path id: current_user.id if session[:pending_organisation_id]
    return session[:previous_url] if session[:previous_url]
    return organisation_path(Organisation.find(current_user.pending_organisation_id)) if current_user.pending_organisation_id
    return organisation_path(current_user.organisation) if current_user.organisation
    root_path
  end

  # Devise Invitable hook
  # Since users are invited to be org admins, we're delivering them to their page
  def after_accept_path_for(resource)
    return organisation_path(current_user.organisation) if current_user.organisation
    root_path
  end


  def allow_cookie_policy
    response.set_cookie 'cookie_policy_accepted', {
        value: 'true',
        path: '/',
        expires: 1.year.from_now.utc
    }
    #respond_to do |format|
    #  format.html redirect_to root_path
    #  format.json { render :nothing => true, :status => 200 }
    #end

    redirect_to request.referer || '/'
  end

  private

  # Enforces admin-only limits
  # http://railscasts.com/episodes/20-restricting-access
  def authorize
    unless admin?
      flash[:error] = t('authorize.admin')
      redirect_to root_path
      false
    end
  end

  def admin?
    current_user.try :admin?
  end

  def assign_footer_page_links
    @footer_page_links = Page.visible_links
  end

  def set_flash_warning_reminder_to_update_details usr
    if usr.organisation && usr.organisation.not_updated_recently?
      msg = "You have not updated your details in over a year! Please click #{view_context.link_to('here', edit_organisation_path(usr.organisation))} to update now.".html_safe
      if flash[:warning]
        flash[:warning] << msg
      else
        flash[:warning] = msg
      end
    end
  end
end
