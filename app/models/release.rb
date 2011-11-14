class Release < ActiveRecord::Base
  default_scope order(:sort_order)

  def self.names
    all.map(&:name)
  end

  def self.latest
    first
  end

end
