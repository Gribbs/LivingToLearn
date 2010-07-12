class EntityWebLinks < ActiveRecord::Migration
  def self.up
    add_column "entities", "web_address", :string
    add_column "entities", "wikipedia_address", :string
  end

  def self.down
    remove_column "entities", "web_address", :string
    remove_column "entities", "wikipedia_address", :string
  end
end
