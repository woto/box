class Communicate < ApplicationRecord
  belongs_to :device, optional: true
end
