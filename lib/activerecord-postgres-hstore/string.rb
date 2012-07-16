class String

  # If the value os a column is already a String and it calls to_hstore, it
  # just returns self. Validation occurs afterwards.
  def to_hstore
    self
  end

  # Validates the hstore format. Valid formats are:
  # * An empty string
  # * A string like %("foo"=>"bar"). I'll call it a "double quoted hstore format".
  # * A string like %(foo=>bar). Postgres doesn't emit this but it does accept it as input, we should accept any input Postgres does

  def valid_hstore?
    pair = hstore_pair
    !!match(/^\s*(#{pair}\s*(,\s*#{pair})*)?\s*$/)
  end

  # Test to see if a string is actually a number
  # test shamelessly stolen from: http://railsforum.com/viewtopic.php?id=19081
  def is_numeric?
    begin Float(self)
      true 
    end
    rescue
      false
  end

  def to_implicit_type(can_be_obj=true)
    return true if self =~ /^true$/i
    return false if self =~ /^false$/i
    return nil if self =~ /^NULL$/i
    if self.is_numeric?
      if self =~ /^[0-9]+\.[0-9]+$/
        return self.to_f
      else
        return self.to_i
      end
    end
    unquoted = self[0] == '"' ? self[1..-2] : self
    return $1.gsub(/\\(.)/, '\1').from_hstore if can_be_obj && unquoted =~ /^\{\\(.*?)\}/
    unquoted
  end

  # Creates a hash from a valid double quoted hstore format, 'cause this is the format
  # that postgresql spits out.
  def from_hstore
    token_pairs = (scan(hstore_pair)).map { |k,v| [k.to_implicit_type(false), v.to_implicit_type] }
    Hash[ token_pairs ]
  end

  private

  def hstore_pair
    quoted_string = /"[^"\\]*(?:\\.[^"\\]*)*"/
    unquoted_string = /[^\s=,][^\s=,\\]*(?:\\.[^\s=,\\]*|=[^,>])*/
    string = /(#{quoted_string}|#{unquoted_string})/
    /#{string}\s*=>\s*#{string}/
  end
end
