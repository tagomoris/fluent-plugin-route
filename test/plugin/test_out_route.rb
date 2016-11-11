require 'fluent/test'
require 'fluent/plugin/out_route'

class RouteOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    remove_tag_prefix t
    <route t1.*>
      remove_tag_prefix t1
      add_tag_prefix yay
    </route>
    <route t2.*>
      remove_tag_prefix t2
      add_tag_prefix foo
    </route>
    <route **>
      @label @primary
      copy
    </route>
    <route **>
      @label @backup
    </route>
  ]

  def create_driver(conf, tag)
    d = Fluent::Test::OutputTestDriver.new(Fluent::RouteOutput, tag)
    Fluent::Engine.root_agent.define_singleton_method(:find_label) do |label_name|
      obj = Object.new
      obj.define_singleton_method(:event_router){ d.instance.router } # for test...
      obj
    end
    d.configure(conf, true)
  end

  def test_configure
    # TODO: write
  end

  def test_emit_t1
    d = create_driver(CONFIG, "t.t1.test")

    time = Time.parse("2011-11-11 11:11:11 UTC").to_i
    d.run do
      d.emit({"a" => 1}, time)
      d.emit({"a" => 2}, time)
    end

    emits = d.emits
    assert_equal 2, emits.size

    assert_equal ["yay.test", time, {"a" => 1}], emits[0]
    assert_equal ["yay.test", time, {"a" => 2}], emits[1]
  end

  def test_emit_t2
    d = create_driver(CONFIG, "t.t2.test")

    time = Time.parse("2011-11-11 11:11:11 UTC").to_i
    d.run do
      d.emit({"a" => 1}, time)
      d.emit({"a" => 2}, time)
    end

    emits = d.emits
    assert_equal 2, emits.size

    assert_equal ["foo.test", time, {"a" => 1}], emits[0]
    assert_equal ["foo.test", time, {"a" => 2}], emits[1]
  end

  def test_emit_others
    d = create_driver(CONFIG, "t.t3.test")

    time = Time.parse("2011-11-11 11:11:11 UTC").to_i
    d.run do
      d.emit({"a" => 1}, time)
      d.emit({"a" => 2}, time)
    end

    emits = d.emits
    assert_equal 4, emits.size

    assert_equal ["t3.test", time, {"a" => 1}], emits[0]
    assert_equal ["t3.test", time, {"a" => 1}], emits[1]
    assert_equal ["t3.test", time, {"a" => 2}], emits[2]
    assert_equal ["t3.test", time, {"a" => 2}], emits[3]
  end
end
