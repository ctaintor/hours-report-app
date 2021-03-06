class ApplicationController < ActionController::Base
  include TheRole::Controller
  around_filter :append_event_tracking_tags, :set_time_zone

  protect_from_forgery with: :exception

  helper_method :current_user

  def access_denied
    flash[:alert] = 'You are not authorized to view this page!'
    redirect_to_back_or_default
  end

  alias_method :role_access_denied, :access_denied

  def login_required
    authenticate_user
  end

  def mixpanel_name_tag
    current_user && current_user.email if current_user
  end

  def mixpanel_distinct_id
    current_user.id if current_user
  end

  private

  def set_time_zone(&block)
    if cookies['timezone'].present?
      timezone = cookies['timezone']
    else
      timezone = Time.zone
    end

    Time.use_zone(timezone, &block)
  end

  def authenticate_user
    redirect_to login_path unless current_user
  end

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def redirect_to_back_or_default(default = root_url)
    if request.env["HTTP_REFERER"].present? and request.env["HTTP_REFERER"] != request.env["REQUEST_URI"]
      redirect_to :back
    else
      redirect_to default
    end
  end

  def check_for_list_owner
    unless (current_user == @user || current_user.admin?)
      access_denied
    end
  end

  def doc_raptor_send(options = {})
    default_options = {
      :name => controller_name,
      :document_type => :xls,
      :test => ! Rails.env.production?,
    }

    options = default_options.merge(options)

    options[:document_content] ||= render_to_string
    ext = options[:document_type].to_sym

    response = DocRaptor.create(options)
    if response.code == 200
      send_data response, :filename => "#{options[:name]}.#{ext}", :type => ext
    else
      render :inline => response.body, :status => response.code
    end
  end
end
