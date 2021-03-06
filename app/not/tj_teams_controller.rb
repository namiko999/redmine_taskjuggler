class TjTeamsController < ApplicationController
  unloadable


  def index
    @tj_teams = TjTeam.all
  end

  def detail
    @tj_team = TjTeam.find(params[:id])
    @users = User.where(tj_team_id: params[:id])
  end
  
  def new
    @tj_team = TjTeam.create(:name => params[:tj_team_name])
  end
end
