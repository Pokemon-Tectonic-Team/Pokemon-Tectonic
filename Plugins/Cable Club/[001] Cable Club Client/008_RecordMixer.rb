module RecordMixer
  @@records = HandlerHashBasic.new

  def self.copy(sym, *syms)
    @@records.copy(sym, *syms)
  end

  def self.register(sym, hash)
    @@records.add(sym, hash)
  end
  
  def self.each
    @@records.each { |sym, _ | yield sym }
  end

  def self.record_name(sym)
    return self.call("name", sym)
  end
  
  def self.write_record(sym, writer)
    self.call("writeData", sym, writer)
  end
  
  def self.parse_record(sym, record)
    self.call("parseData", sym, record)
  end
  
  def self.finalize_record(sym)
    self.call("finalizeData", sym)
  end
    
  def self.call(func, sym, *args)
    r = @@records[sym]
    return nil if !r || !r[func]
    return r[func].call(*args)
  end
end

module CableClub
  def self.do_mix_records(connection)
    RecordMixer.each do |sym|
      record_name = RecordMixer.record_name(sym)
      yield _INTL("Preparing {1} Data",record_name) if block_given?
      connection.send do |writer|
        writer.sym(sym.to_sym)
        RecordMixer.write_record(sym, writer)
      end
    end
    
    RecordMixer.each do |sym|
      record_name = RecordMixer.record_name(sym)
      ret = false
      loop do
        yield _INTL("Receiving {1} Data",record_name) if block_given?
        Graphics.update
        Input.update
        connection.update do |record|
          case (type = record.sym)
          when sym.to_sym
            RecordMixer.parse_record(sym, record)
            ret = true
          else
            raise "Unknown message: #{type}"
          end
        end
        break if ret
      end
    end
    
    RecordMixer.each do |sym|
      record_name = RecordMixer.record_name(sym)
      yield _INTL("Processing {1} Data",record_name) if block_given?
      RecordMixer.finalize_record(sym)
    end
  end
end