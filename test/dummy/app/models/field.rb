# frozen_string_literal: true

class Field < FormCore::Field
  include EnumTranslate

  belongs_to :section, touch: true, optional: true

  acts_as_list scope: [:section_id]

  validates :label,
            presence: true
  validates :type,
            inclusion: {
              in: ->(_) { Field.descendants.map(&:to_s) }
            }

  def self.type_key
    model_name.name.split("::").last.underscore
  end

  def type_key
    self.class.type_key
  end

  def options_configurable?
    options.is_a?(FieldOptions) && options.attributes.any?
  end

  def validations_configurable?
    validations.is_a?(FieldOptions) && validations.attributes.any?
  end

  protected

  def interpret_validations_to(model, accessibility, overrides = {})
    return unless accessibility == :read_and_write

    name = overrides.fetch(:name, self.name)

    validations_overrides = overrides.fetch(:validations) { {} }
    validations =
      if validations_overrides.any?
        self.validations.dup.update(validations_overrides)
      else
        self.validations
      end

    validations.interpret_to(model, name, accessibility)
  end

  def interpret_extra_to(model, accessibility, overrides = {})
    name = overrides.fetch(:name, self.name)

    options_overrides = overrides.fetch(:options) { {} }
    options =
      if options_overrides.any?
        self.options.dup.update(options_overrides)
      else
        self.options
      end

    options.interpret_to(model, name, accessibility)
  end
end

require_dependency "fields"
