class Games < ActiveRecord::Base
  validates :field_id, :plant, :growth, :presence => true
  validates :field_id, :growth, :numericality => true
  validates :growth, :numericality => {:greater_than => 0, :less_than => 6}
  validates :user, :uniqueness => {:scope => :field_id, :message=> "Ячейка занята другим растением"}
end