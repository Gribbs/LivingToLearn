module NetzkeComponentExtend

#############
# Toolbars
#############


def route_toolbars
  format='iphone'

  js_method :to_logout, <<-JS
    function(){
      window.location="/logout.#{format}";
    }
  JS

  @toolbars_routed= true
end

################
# Initialize
################

  def netzke( view, config = {} )
    configr= Configurator.new(config,view)
    yield(configr) if block_given?
    config= configr.contents
    config[:class_name]= self
    config[:user_signed_in]= view.user_signed_in?
    config[:current_user]= view.current_user

    config[:notice]= view.notice
    config[:alert]= view.alert

    return view.send(:netzke, :touch, config)
  end

end
