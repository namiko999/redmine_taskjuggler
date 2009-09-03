require 'redmine'

Redmine::Plugin.register :redmine_tj_status do
  name 'Redmine Tj Status plugin'
  author 'Chris Mann'
  description 'This plug exports project status into TaskJuggler and will import the dates too !'
  version '0.0.1'
  #menu :application_menu, :tjstatus, { :controller => 'tjstatus', :action => 'index' }, :caption => 'Task Juggler'
  permission :tjstatus, {:tjstatus => [:index, :export, :initial_export]}, :public => true
  menu :project_menu, :tjstatus, { :controller => 'tjstatus', :action => 'test' }, :caption => 'Task Juggler File', :after => :activity, :param => :project_identifier
end