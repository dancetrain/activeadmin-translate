module ActiveAdmin
  module Translate

    # Form builder to build input fields that are arranged by locale in tabs.
    #
    module FormBuilder

      # Create the local field sets to enter the inputs per locale
      #
      # @param [Symbol] name the name of the translation association
      # @param [Proc] block the block for the additional inputs
      #
      def translate_inputs(name = :translations, &block)
        if self.respond_to?(:form_buffers)
          html = form_buffers.last
        else
          html = "".html_safe
        end

        template.assign(has_many_block: true)

        html << template.content_tag(:div, :class => "activeadmin-translate #{ translate_id }") do
          locale_tabs << locale_fields(name, block) << tab_script
        end

        template.concat(html) if template.output_buffer
        html
      end

      # Create raw inputs for each language
      # A simple wrapper around basic form input method
      #
      # @param [Symbol] method
      # @param [Hash] options
      def translate_input(method, options = {})
        html = if self.respond_to?(:form_buffers)
          form_buffers.last
        else
          "".html_safe
        end

        template.assign(has_many_block: true)

        html << template.content_tag(:li, class: 'activeadmin-translate-input') do
          template.content_tag :fieldset, class: 'has_many_fields' do
            template.content_tag(:ol) do
              out = []

              human_attr = human_attribute_name(method)

              out << ::I18n.available_locales.map do |locale|

                translation = object.translation_for(locale)
                translation.instance_variable_set(:@errors, object.errors) if locale == I18n.default_locale

                fields_for :translations, translation do |f|
                  unless has_locale_field
                    f.input :locale, :as => :hidden
                  end

                  opts = options.dup
                  opts[:label] = "#{human_attr}: #{locale_label locale}"

                  f.input method, opts
                end
              end

              self.has_locale_field = true

              out.join.html_safe
            end

          end
        end

        template.concat(html) if template.output_buffer

        html
      end

      protected

      # Create the script to activate the tabs on insertion.
      #
      # @return [String] the script tag
      #
      def tab_script
        template.content_tag(:script, "$('.activeadmin-translate').tabs();".html_safe)
      end

      # Create the local field sets to enter the inputs per locale.
      #
      # @param [Symbol] name the name of the translation association
      # @param [Proc] block the block for the additional inputs
      #
      def locale_fields(name, block)
        ::I18n.available_locales.map do |locale|
          translation = object.translation_for(locale)
          translation.instance_variable_set(:@errors, object.errors) if locale == I18n.default_locale

          fields = proc do |form|
            form.input(:locale, :as => :hidden)
            block.call form
          end

          inputs_for_nested_attributes(:for => [name, translation], :id => field_id(locale), :class => "inputs locale locale-#{ locale }", &fields)
        end.join.html_safe
      end


      # Create the locale tab to switch the translations.
      #
      # @return [String] the HTML for the locale tabs
      #
      def locale_tabs
        template.content_tag(:ul, :class => 'locales') do
          ::I18n.available_locales.map do |locale|
            template.content_tag(:li) do
              template.content_tag(:a, ::I18n.t("active_admin.translate.#{ locale }"), :href => "##{ field_id(locale) }")
            end
          end.join.html_safe
        end
      end

      # Get the unique id for the translation field
      #
      def field_id(locale)
        "locale-#{ locale }-#{ translate_id }"
      end

      # Get the unique id for the translation
      #
      # @return [String] the id
      #
      def translate_id
        "#{ self.object.class.to_s.underscore.dasherize }-#{ self.object.object_id }"
      end


      # Flag to prevent double render for locale hidden field
      #
      # @return [Boolean]
      #
      def has_locale_field
        @has_locale_field ||= false
      end

      # Flag to prevent double render for locale hidden field
      #
      # @return [Boolean]
      #
      def has_locale_field=(value)
        @has_locale_field = value
      end

      # Get translation of locale
      #
      # @param [String|Symbol] locale
      #
      # @return [String]
      #
      def locale_label(locale)
        ::I18n.t("active_admin.translate.#{ locale }")
      end

      # Get human attribute name for method
      #
      # @param [String|Symbol] method
      #
      # @return [String]
      #
      def human_attribute_name(method)
        if @object.respond_to?(:human_attribute_name)
          @object.human_attribute_name(method, default: method.to_s.titleize)
        else
          method.to_s.titleize
        end
      end

    end
  end
end
