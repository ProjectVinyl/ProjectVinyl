# require 'statistics2'

module Wilson
  # https://www.evanmiller.org/how-not-to-sort-by-average-rating.html
  # pos: number of positive votes
  # n: total number of votes
  # confidence: confidence rating from 0-1
  def ci_bounds(pos, n, confidence = 0.95)
    return [0,0] if n == 0

    z = 1.96 # Statistics2.pnormaldist(1-(1-confidence)/2) # 1.96 for confidence=0.95

    phat = 1.0*pos/n

    origin = (phat + z*z/(2*n)
    deviation = z * Math.sqrt((phat*(1-phat)+z*z/(4*n))/n))/(1+z*z/n)

    [
      origin - deviation,
      origin + deviation
    ]
  end
end
