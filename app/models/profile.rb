class Profile < ActiveRecord::Base
  default_scope order(:sort_order)

  def self.names
    order("sort_order ASC").select(:name).map(&:name)
  end

  def self.first
    order("sort_order ASC").first
  end
end
