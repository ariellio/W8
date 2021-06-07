require 'active_support'
require 'active_support/core_ext'
require 'erb'
require_relative './session'
require 'byebug'

class ControllerBase
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res)
    @req,@res = req,res
    @already_built_response = false
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # Set the response status code and header
  def redirect_to(url)
    raise 'double render error' if already_built_response?
    res['Location'] = url
    res.status = 302
    @already_built_response = true
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    raise 'double render error' if already_built_response?
    res.write(content)
    res['Content-Type'] = content_type
    @already_built_response = true
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    raise 'double render error' if already_built_response?
    controller_name = self.class.to_s.underscore
    debugger
    path = "views/#{controller_name}/#{template_name}.html.erb"
    file = File.open(path).readlines.map(&:chomp)
    result = []
    file.each do |line|
      front = line.index('<%=')
      if front
        back = line.index('%>') + 2
        replacement = ERB.new(line[front...back]).result(binding)
        result << line[0...front] + replacement + line[back..-1]
      else
        result << line
      end
    end

    result = result.join('\n')

    render_content(result,'text/html')
    @already_built_response = true
  end

  # method exposing a `Session` object
  def session
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
  end
end