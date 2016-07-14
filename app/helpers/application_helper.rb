module ApplicationHelper
  def flash_class(level)
    case level
    when :notice then "alert alert-block"
    when :success then "alert alert-success"
    when :error then "alert alert-error"
    when :alert then "alert alert-info"
    end
  end

  def flash_messages!
    [:notice, :error, :success, :alert].each do |key|
      if flash[key]
        @key = key
        @message = flash[key]
      end
    end

    return "" if @message.blank?

    html = <<-HTML
      <div class="#{flash_class(@key)}">
        <strong>#{@message}</strong>
      </div>
    HTML

    html.html_safe
  end
end
