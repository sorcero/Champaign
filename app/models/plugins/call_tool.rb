# == Schema Information
#
# Table name: plugins_call_tools
#
#  id         :integer          not null, primary key
#  page_id    :integer
#  active     :boolean
#  ref        :string
#  form_id    :integer
#  targets    :json
#  created_at :datetime
#  updated_at :datetime
#

class Plugins::CallTool < ActiveRecord::Base
  belongs_to :page, touch: true
  belongs_to :form

  validate :targets_are_valid
  after_create :create_form

  DEFAULTS = {}.freeze

  def name
    self.class.name.demodulize
  end

  def liquid_data(supplemental_data={})
    {
      active: active,
      targets: targets,
      target_countries: target_countries,
      title: title
    }
  end

  # TODO: remove
  def find_target(id)
    targets.values.flatten.find do |target|
      target['id'] == id
    end
  end

  def targets=(target_objects)
    write_attribute :targets, target_objects.map(&:to_hash)
  end

  def targets
    read_attribute(:targets).map {|t| ::CallTool::Target.new(t)}
  end

  private

  def create_form
    Form.create! formable: self,
                 name: "call_tool_#{id}",
                 master: false
  end

  # Returns [{ code: <country-code>, name: <country-name>}, {..} ...]
  def target_countries
    return [] if targets.blank?
    locale = page.language&.code || :en
    targets.keys.map do |key|
      country_name = ISO3166::Country[key]&.translation(locale)
      if country_name.present?
        {
          name: country_name,
          code: key
        }
      end
    end.compact
  end

  def targets_are_valid
    unless targets.all?(&:valid?)
      errors.add(:targets, "A target is invalid (TODO: improve error reporting)")
    end
  end
end
