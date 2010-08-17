class TraceLogger
  def initialize(file, active=true)
    @file = file
    @active = nil
    @fd = nil

    start if active
  end
  
  def start
    @fd = File.open(@file, 'w')
    @active = true
  end

  def shutdown
    @fd.close if @active
    @fd = nil
    @active = false
  end

  def message(msg)
    @fd.puts msg if @active
  end
end
