# This is used if no supported application framework is detected
class Spork::AppFramework::Unknown < Spork::AppFramework
  def entry_point
    nil
  end

  def self.present?
    false
  end
end
