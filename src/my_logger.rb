require 'singleton'

class MyLogger
  include Singleton

  def std_log text
    puts text
  end

  def err_log text
    puts text
  end

  def debug_log text
    puts text
  end
end
