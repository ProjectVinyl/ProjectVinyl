module StringsHelper
  def self.check_and_trunk(str, defa = '')
    return defa if str.blank?
    str = str.strip
    str.length > 255 ? str[0, 255] : str
  end

  def check_and_trunk(str, defa = '')
    StringsHelper.check_and_trunk(str, defa)
  end

  def self.valid_string?(s)
    s.present?
  end

  def valid_string?(s)
    StringsHelper.valid_string?(s)
  end

  def sensible_option_for_select(options, selected)
    raw (options.map.with_index { |label,value|
      "<option value=\"#{value}\"#{value == selected ? " selected" : ""}>#{label}</option>"
    }).join
  end

  def self.explode(prefixes, ignore_empty: false, wrap_char: '-')
    yield('') if ignore_empty.nil? || !ignore_empty
    prefixes.each {|p| yield("#{wrap_char}#{p}#{wrap_char}")}
  end
end
