require "rails_helper"

describe Result do
  it { should belong_to :gateway }
  it { should validate_presence_of :gateway }
end
