$:.unshift "../lib"
require 'eventmachine'
require 'test/unit'

class TestFileWatch < Test::Unit::TestCase
  module FileWatcher
    def file_modified
      $modified = true
    end
    def file_deleted
      $deleted = true
    end
    def unbind
      $unbind = true
      EM.stop
    end
  end

  def setup
    EM.kqueue = true if EM.kqueue?
    EM.event_ports = true if EM.event_ports?
  end

  def teardown
    EM.kqueue = false if EM.kqueue?
    EM.event_ports = false if EM.event_ports?
  end

  def test_events
    EM.run{
      require 'tempfile'
      file = Tempfile.new('em-watch')
      $tmp_path = file.path

      # watch it
      watch = EM.watch_file(file.path, FileWatcher)
      $path = watch.path

      # modify it
      File.open(file.path, 'w'){ |f| f.puts 'hi' }

      # delete it
      EM.add_timer(0.01){ file.close; file.delete }
    }

    assert_equal($path, $tmp_path)
    assert($modified)
    assert($deleted)
    assert($unbind)
  end
end
