module FormatsHelper
  def fuzzy_big_number_with_delimiter(number)
    number_to_human(number, {
      precision: 2,
      significant: false,
      delimiter: ',',
      units: {
        thousand: 'K',
        million: 'M',
        billion: 'B',
        trillion: 'T',
        quadrillion: 'Q'
      }
    })
  end

  def duration(length, allow_zero: false)
    return '--:--' if !allow_zero && length == 0
    Ffmpeg.to_h_m_s(length, cut_leading_zero_hours: true)
  end

  def safe_to_display(num, max)
    num ||= 0
    return number_with_delimiter(max) + '+' if num > max
    number_with_delimiter num
  end
end
