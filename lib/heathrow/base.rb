require 'heathrow'

class Heathrow::Base
  private

  # Not a UUID because emphasis is on local uniqueness.
  def generate_id
    now = Time.now
    parts = [now.to_i, now.usec, $$, rand(16**8)]
    parts.map {|i| i.to_s(16)}.join('-')
  end
end
