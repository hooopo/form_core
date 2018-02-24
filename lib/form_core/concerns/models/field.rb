# frozen_string_literal: true

module FormCore::Concerns
  module Models
    module Field
      extend ActiveSupport::Concern

      NAME_REGEX = /\A[a-z_][a-z_0-9]*\z/

      included do

        serialize :validations
        serialize :options

        validates :name,
                  presence: true,
                  uniqueness: {scope: :form},
                  exclusion: {in: FormCore.reserved_names},
                  format: {with: NAME_REGEX}

        after_initialize do
          self.validations ||= {}
          self.options ||= {}
        end
      end

      def name
        self[:name]&.to_sym
      end

      def stored_type
        raise NotImplementedError
      end

      def default_value
        nil
      end

      def interpret_to(model, overrides: {})
        check_model_validity!(model)

        default_value = overrides.fetch(:default_value, self.default_value)
        model.attribute name, stored_type, default: default_value

        interpret_validations_to model, overrides
        interpret_extra_to model, overrides

        model
      end

      protected

      def interpret_validations_to(model, overrides = {})
        validations = overrides.fetch(:validations, (self.validations || {}))
        validation_options = overrides.fetch(:validation_options) { self.options.fetch(:validation, {}) }

        if validations.present?
          model.validates name, **validations, **validation_options
        end
      end

      def interpret_extra_to(_model, _overrides = {})
      end

      def check_model_validity!(model)
        unless model.is_a?(Class) && model < ::FormCore::VirtualModel
          raise ArgumentError, "#{model} must be a #{::FormCore::VirtualModel}'s subclass"
        end
      end
    end
  end
end
