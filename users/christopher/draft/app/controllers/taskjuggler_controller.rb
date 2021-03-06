class TaskjugglerController < ApplicationController
unloadable

  def export
  end

  def import
  @aFile = File.new(params[:filepath], "r")
  @fields = []
  @aFile.readline.chomp.each(";") do |field|
    @fields.push(field.gsub("\"","").chomp(";"))
  end
  if @fields == ["Id","Start","End","Priority","Effort","Duration","Dependencies"] then @all = "is dandy" end
  @lines = []
  @aFile.each do |dataline|
    line = dataline.chomp.split(";")
    (0..4).each do |i|
      line[i] = line[i].gsub("\"","")
    end
    line[0] = line[0].sub(/^.*\.t([0-9]+)$/,'\1').to_i
    line[1] = line[1].to_date
    line[2] = line[2].to_date
    line[3] = line[3].to_i
    line[4] = line[4].to_f
    #line[5] = line[5].to_f
    #temp = line[6].split(", ")
    #line[6] = []
    #temp.each do |item|
    # line[6].push(item.sub(/^.*\.t([0-9]+)$/,'\1').to_i)
    #end
    #.each .gsub("\"","").chomp(";")
    issue = Issue.find(:first, :conditions => {:id => line[0] })
    issue.start_date = line[1].to_s
    issue.due_date = line[2].to_s
    #@lines.push(issue)
    #issue.priority_id = (line[3] / 100) -1
    issue.estimated_hours = line[4] * 8
    #if line[4] == 0 
      #duration to place here
    #end
# ignore line 6 for the time being, but this may lead to errors when saving
    #issue.save
    #sd = issue.start_date.to_s
    if issue.save
      @lines.push(line)
    else
      @lines.push(["Task #" + line[0].to_s + " not imported due to errors"])
    end
  end
  end

  def index
  @projects = Project.find(:all, :conditions => ["status = 1 AND parent_id IS NOT NULL"], :order => ["parent_id, name"] )
  @users = User.find(:all)
  end

  def initial_export
  ### Initialize necessary variables
  if params[:project_identifier] 
    @Project = Project.find(:first, :conditions => {:identifier => params[:project_identifier]})
    @project_id = @Project.id.to_s
  else
    @Project = Project.find(:first, :conditions => {:id => params[:project_id]})
    @project_id = params[:project_id]
  end
  @FirstIssue = Issue.find(:first, :order => ["start_date"], :conditions => ["start_date IS NOT NULL AND project_id = " + @project_id])
  @LastIssue = Issue.find(:first, :order => ["due_date DESC"],:conditions => {:project_id => @project_id})
  @IssueFullName = {}
  @Issues = Issue.find(:all, :conditions => {:project_id => @project_id})
  @Versions = Version.find(:all,:conditions => {:project_id => @project_id})
  @Cats = IssueCategory.find(:all, :conditions => {:project_id => @project_id} );
  @start_status_id = IssueStatus.find(:first, :conditions => ["is_default=?", true]).id
  @TimeEntries = TimeEntry.find(:all, :conditions => ["spent_on >= '" + @FirstIssue.start_date.to_s + "'"], :order => ['user_id, issue_id'])
  @IssuesSansVersion = Issue.find(:all, :conditions => ["project_id = " + @project_id + " AND fixed_version_id IS NULL"])
  @CustFieldId = {}
  ### Update task juggler
  @TimeEntries.each do |te|
    if not te.issue.start_date
      te.issue.start_date = te.spent_on
    end
    if te.spent_on < te.issue.start_date
      te.issue.start_date = te.spent_on
    end
    if te.issue.due_date and te.spent_on > te.issue.due_date
      te.issue.due_date = te.spent_on
    end
    if te.issue.done_ratio == 0
      te.issue.done_ratio = 10
    end
    if te.issue.status and te.issue.status.is_closed and not te.issue.done_ratio == 100
      te.issue.done_ratio = 100
    end
    te.issue.save
  end
  
  ### Handle init des custom fields
  @CustFieldId['issue'] = {}
  @CustFieldId['issue']['milestone'] = IssueCustomField.find(:first, :conditions => {:name => "milestone"}).id
  @CustFieldId['issue']['allocate_alternative'] = IssueCustomField.find(:first, :conditions => {:name => "allocate_alternative"}).id
  @CustFieldId['issue']['allocate_additional'] = IssueCustomField.find(:first, :conditions => {:name => "allocate_additional"}).id
  @CustFieldId['issue']['allocate_squad'] = IssueCustomField.find(:first, :conditions => {:name => "allocate_squad"}).id
  @CustFieldId['issue']['duration'] = IssueCustomField.find(:first, :conditions => {:name => "duration"}).id
  @CustFieldId['issue']['scheduled']= IssueCustomField.find(:first, :conditions => {:name => "scheduled"}).id
  @CustFieldId['project'] = {}
  @CustFieldId['project']['start_date'] = ProjectCustomField.find(:first, :conditions => {:name => "start_date"}).id
  @CustFieldId['project']['stop_date'] = ProjectCustomField.find(:first, :conditions => {:name => "stop_date"}).id
  @CustFieldId['user'] = {}
  @CustFieldId['user']['squad'] = UserCustomField.find(:first, :conditions => {:name => "squad"}).id
  @CustFieldId['user']['limits'] = UserCustomField.find(:first, :conditions => {:name => "limits"}).id
  ### Resources


  @Resources = @Project.assignable_users
  @ResourceSquadNames = UserCustomField.find(:first, :conditions => {:name => "squad"}).possible_values
  @ResourceSquadNames.push("others")
  @ResourceBySquad = {}
  @ResourceLimits = {} # Hash user_login => custom field "limits"
  if @ResourceSquadNames[0] 
    @ResourceSquadNames.each do |squad_name|
      if squad_name == "" then squad_name = "others" end
      @ResourceBySquad[squad_name] = {}
    end
  end
  @Resources.each do |res|
    squad_custom_value = res.custom_values.find(:first, :conditions => {:custom_field_id => @CustFieldId['user']['squad']})
    if squad_custom_value
      squad_name = squad_custom_value.value
    else
      squad_name = "others"
    end
    if squad_name == "" then squad_name = "others" end
    limits_custom_value = res.custom_values.find(:first, :conditions => {:custom_field_id => @CustFieldId['user']['limits']})
    if limits_custom_value and not limits_custom_value.value == ""
      @ResourceLimits[res.login.sub(".","_").sub("-","_")] = limits_custom_value.value
    end
    if @ResourceBySquad[squad_name]
      @ResourceBySquad[squad_name][res.login.sub(".","_").sub("-","_")] = res.firstname + " " + res.lastname + " <" + res.mail + ">"
    end
  end

  ### Construct index of keys between issues and tasks
  @Issues.each do |issue|
    if issue.fixed_version
      @IssueFullName["t" + issue.id.to_s] = @Project.identifier.sub("-","_")
      @IssueFullName["t" + issue.id.to_s] = @IssueFullName["t" + issue.id.to_s] + ".v" + issue.fixed_version.name.sub(".","_").sub(" ","_").sub("-","_")

      if issue.category
        @IssueFullName["t" + issue.id.to_s] += "." + issue.category.name
      end
      @IssueFullName["t" + issue.id.to_s] = @IssueFullName["t" + issue.id.to_s] + ".t" + issue.id.to_s
    end   
  end
  ### Construct a two-dimensional table of issues in categories in versions
  @IssuesByVersionByCat = {}
  @Versions.each do |version|
    version_name = "v" + version.name.sub(".","_").sub(" ","_").sub("-","_")
    if not @IssuesByVersionByCat[version_name]
      @IssuesByVersionByCat[version_name] = {}
    end
    issues = version.fixed_issues
    ret = self.PutIssuesByCat(issues)
    ret.each_pair do |cat_name, issues|
      @IssuesByVersionByCat[version_name][cat_name] = issues
    end
  end
  end



  def PutIssuesByCat (issues)
    retvar = {}
    issues.each do |issue|
      if issue.category and issue.category.name
        cat_name = issue.category.name
      else
        cat_name = "no_category"
      end
      if not retvar[cat_name]
        retvar[cat_name] = []
      end
      retvar[cat_name].push(issue)
    end
    return retvar
  end

  def test
  
  end

end
