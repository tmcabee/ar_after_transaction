require "spec_helper"

class AnExpectedError < Exception
end

class Foo
  cattr_accessor :test_callbacks, :test_stack
  self.test_stack = []
  self.test_callbacks = []

  after_create :do_it
  def do_it
    self.class.test_callbacks.map{|callback| send(callback)}.last
  end

  def do_after
    after_transaction do
      ActiveRecord::Base.transaction do
        # nested transaction should not cause infinitive recursion
      end
      self.class.test_stack << :after
    end
  end

  def do_normal
    self.class.test_stack << :normal
  end

  def create_bar
    Bar.create! :foo_id => id, :message => "Bar for #{id}"
  end

  def oops
    raise AnExpectedError
  end
end

describe ARAfterTransaction do
  before do
    Foo.normally_open_transactions = nil
    Foo.send(:transactions_open?).should == false
    Foo.test_stack.clear
    Foo.test_callbacks.clear
  end

  it "does not execute when transaction on another database completes" do
    Foo.test_callbacks = [:do_after, :do_normal, :create_bar, :oops]
    lambda{
      Foo.create!
    }.should raise_error(AnExpectedError)
    Foo.test_stack.should == [:normal]
  end
end