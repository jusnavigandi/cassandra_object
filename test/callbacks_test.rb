require 'test_helper'

class CallbacksTest < CassandraObjectTestCase
  def setup
    super
  end

  context "a newly created record" do
    setup do
      @customer = Customer.create! :first_name    => "Tom",
                                   :last_name     => "Ward",
                                   :date_of_birth => Date.parse("1977/12/04")
    end

    should "have had after_create called" do
      assert @customer.after_create_called?
    end

    should "have had all callbacks called" do
      assert_equal [:before_save, :before_create, :after_create, :testing, :after_save], @customer.call_backs
    end
  end
end
