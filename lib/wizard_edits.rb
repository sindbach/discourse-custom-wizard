require_dependency 'wizard'
require_dependency 'wizard/field'
require_dependency 'wizard/step'

::Wizard.class_eval do
  def self.user_requires_completion?(user)
    wizard_result = self.new(user).requires_completion?
    return wizard_result if wizard_result

    custom_redirect = nil

    if user && wizard_id = CustomWizard::Wizard.after_signup
      custom_redirect = wizard_id.dasherize

      if CustomWizard::Wizard.new(user, id: wizard_id).completed?
        custom_redirect = nil
      end
    end

    $redis.set('custom_wizard_redirect', custom_redirect)

    !!custom_redirect
  end
end

::Wizard::Field.class_eval do
  attr_reader :label, :description, :key, :min_length

  def initialize(attrs)
    attrs = attrs || {}

    @id = attrs[:id]
    @type = attrs[:type]
    @required = !!attrs[:required]
    @label = attrs[:label]
    @description = attrs[:description]
    @key = attrs[:key]
    @min_length = attrs[:min_length]
    @value = attrs[:value]
    @choices = []
  end
end

class ::Wizard::Step
  attr_accessor :title, :description, :key
end

::WizardSerializer.class_eval do
  attributes :id, :background, :completed, :required

  def id
    object.id
  end

  def include_id?
    object.respond_to?(:id)
  end

  def background
    object.background
  end

  def include_background?
    object.respond_to?(:background)
  end

  def completed
    object.completed?
  end

  def include_completed?
    object.completed? && !object.respond_to?(:multiple_submissions) && !scope.current_user.admin?
  end

  def include_start?
    object.start && include_steps?
  end

  def include_steps?
    !include_completed?
  end

  def required
    object.required
  end

  def include_required?
    object.respond_to?(:required)
  end
end

::WizardStepSerializer.class_eval do
  def title
    return object.title if object.title
    I18n.t("#{object.key || i18n_key}.title", default: '')
  end

  def description
    return object.description if object.description
    I18n.t("#{object.key || i18n_key}.description", default: '')
  end
end

::WizardFieldSerializer.class_eval do
  def label
    return object.label if object.label
    I18n.t("#{object.key || i18n_key}.label", default: '')
  end

  def description
    return object.description if object.description
    I18n.t("#{object.key || i18n_key}.description", default: '')
  end

  def placeholder
    I18n.t("#{object.key || i18n_key}.placeholder", default: '')
  end
end
