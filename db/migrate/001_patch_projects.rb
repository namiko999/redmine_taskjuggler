class PatchProjects < ActiveRecord::Migration
  def change
    add_column :projects, :tj_activated, :boolean
    add_column :projects, :tj_version, :string
    add_column :projects, :tj_dailyworkinghours, :integer
    add_column :projects, :tj_period,  :string
    add_column :projects, :tj_currency,  :string
    add_column :projects, :tj_now,  :string
    add_column :projects, :tj_numberformat,  :string
    add_column :projects, :tj_timingresolution,  :string
    add_column :projects, :tj_timeformat, :string
  end
end
