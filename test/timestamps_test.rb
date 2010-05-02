require 'test_helper'

class TimestampsTest < CassandraObjectTestCase
  def setup
    super
    @customer = Customer.create :first_name => "Michael", :last_name => "Koziarski", :date_of_birth => 28.years.ago.to_date
  end

  test "set created_at attribute" do
    assert @customer.created_at
  end
    
  test "set updated_at attribute" do
    assert @customer.updated_at
  end

  test "change updated_at when object change" do
    updated_time = @customer.updated_at
    @customer.last_name = "WTF"
    @customer.save
    assert_not_equal @customer.updated_at, updated_time
  end

  test "not change updated_at while object not save" do
    updated_time = @customer.updated_at
    @customer.last_name = "WTF"
    assert_equal @customer.updated_at, updated_time
  end
end