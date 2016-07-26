# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  html = %(#{html_tag.gsub(/class=".*?"/, "class='form-control error'")}).html_safe
  html
end
