# Helpers shared across views for formatting flash messages, buttons, and audit
# metadata.
module ApplicationHelper
  # Base Tailwind utility classes applied to flash messages.
  FLASH_BASE_CLASSES = "mb-4 flex items-start gap-3 rounded-lg border-l-4 px-4 py-3 shadow-sm".freeze
  # Query string keys that should be preserved when building sortable headers.
  SURVEY_SORTABLE_KEYS = %w[q track semester].freeze

  # Computes alert styling classes based on the flash key.
  #
  # @param key [Symbol, String]
  # @return [String]
  def flash_classes(key)
    tone = key.to_sym

    case tone
    when :notice, :info
      "#{FLASH_BASE_CLASSES} border-blue-500 bg-blue-50 text-blue-900"
    when :success
      "#{FLASH_BASE_CLASSES} border-emerald-500 bg-emerald-50 text-emerald-900"
    when :alert, :error
      "#{FLASH_BASE_CLASSES} border-red-500 bg-red-50 text-red-900"
    when :warning
      "#{FLASH_BASE_CLASSES} border-amber-500 bg-amber-50 text-amber-900"
    else
      "#{FLASH_BASE_CLASSES} border-slate-400 bg-white text-slate-700"
    end
  end

  # Provides a human-friendly heading for a flash message key.
  #
  # @param key [Symbol, String]
  # @return [String]
  def flash_title(key)
    {
      notice: "Heads up",
      info: "Heads up",
      success: "Success",
      alert: "Attention",
      error: "Something went wrong",
      warning: "Warning"
    }.fetch(key.to_sym, key.to_s.titleize)
  end

  # Emits a stylesheet tag for Tailwind, with a fallback if the asset pipeline
  # is unavailable (e.g., during development).
  #
  # @return [String, nil]
  def tailwind_stylesheet_tag
    stylesheet_link_tag("tailwind", "data-turbo-track": "reload")
  rescue StandardError => e
    if (asset = Rails.application.assets&.load_path&.find("tailwind.css"))
      prefix = Rails.application.config.assets.prefix.presence || "/assets"
      href = File.join(prefix, asset.digested_path)

      return tag.link(rel: "stylesheet", href:, "data-turbo-track": "reload")
    end

    Rails.logger.warn("tailwind.css could not be loaded: #{e.message}")
    nil
  end

  # Builds Tailwind button classes for the provided variant.
  #
  # @param variant [Symbol]
  # @param extra_classes [String]
  # @return [String]
  def tailwind_button_classes(variant = :primary, extra_classes: "")
    base = "inline-flex items-center justify-center gap-2 rounded-lg px-4 py-2 text-sm font-semibold transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 disabled:cursor-not-allowed disabled:opacity-50"

    variant_classes = case variant.to_sym
    when :primary
      "bg-[#500000] text-white hover:bg-[#330000] focus-visible:outline-[#500000]"
    when :secondary
      "border border-[#500000] text-[#500000] hover:bg-[#f9f2f2] focus-visible:outline-[#500000]"
    when :subtle
      "bg-slate-100 text-slate-700 hover:bg-slate-200 focus-visible:outline-slate-400"
    when :danger
      "bg-rose-600 text-white hover:bg-rose-700 focus-visible:outline-rose-600"
    else
      "bg-slate-700 text-white hover:bg-slate-800 focus-visible:outline-slate-700"
    end

    [ base, variant_classes, extra_classes.presence ].compact.join(" ")
  end

  # Returns CSS classes for a survey status pill.
  #
  # @param status [String, Symbol]
  # @return [String]
  def survey_status_badge_classes(status)
    base = "inline-flex items-center rounded-full border px-3 py-1 text-xs font-semibold uppercase tracking-wide"

    variant = case status.to_s.downcase
    when "completed"
      "border-emerald-200 bg-emerald-50 text-emerald-700"
    when "pending"
      "border-amber-200 bg-amber-50 text-amber-700"
    else
      "border-slate-200 bg-slate-100 text-slate-600"
    end

    "#{base} #{variant}"
  end

  # Generates a concise summary string from survey audit metadata.
  #
  # @param metadata [Hash]
  # @return [String]
  def summarize_survey_audit_metadata(metadata)
    data = metadata.with_indifferent_access
    fragments = []

    fragments << data[:note].to_s if data[:note].present?

    if data[:attributes].is_a?(Hash)
      data[:attributes].each do |attribute, change|
        change = change.with_indifferent_access
        before = humanize_audit_value(change[:before])
        after = humanize_audit_value(change[:after])
        next if before == after

        fragments << "#{attribute.to_s.titleize}: #{before} -> #{after}"
      end
    end

    if data[:associations].is_a?(Hash)
      data[:associations].each do |name, change|
        change = change.with_indifferent_access
        before = humanize_audit_list(change[:before])
        after = humanize_audit_list(change[:after])
        next if before == after

        fragments << "#{name.to_s.titleize}: #{before} -> #{after}"
      end
    end

    fragments = fragments.compact
    fragments = [ "No recorded changes" ] if fragments.empty?
    fragments.first(3).join(" | ")
  end

  # Renders a sortable column header link, preserving existing filters.
  #
  # @param label [String]
  # @param column [String]
  # @return [String]
  def sortable_header(label, column)
    active = @sort_column == column
    next_direction = active && @sort_direction == "asc" ? "desc" : "asc"

    preserved_query = request.query_parameters.slice(*SURVEY_SORTABLE_KEYS)
    target_params = preserved_query.merge("sort" => column, "direction" => next_direction)

    classes = [
      "inline-flex items-center gap-1 text-xs font-semibold uppercase tracking-wide text-slate-500 transition hover:text-slate-700"
    ]
    classes << "text-indigo-600" if active

    indicator = if active
      content_tag(:span, "(#{@sort_direction})", class: "text-[0.65rem] font-medium text-indigo-600")
    end
    label_content = indicator ? safe_join([ label, indicator ], " ") : label

    link_to label_content, admin_surveys_path(target_params), class: classes.join(" ")
  end

  # Supplies an accessible label for avatar placeholders and profile images.
  #
  # @param user [Object, nil]
  # @return [String]
  def avatar_aria_label(user)
    return "User avatar" if user.blank?

    name = user.respond_to?(:full_name) ? user.full_name.to_s.strip : ""
    name.present? ? "Profile picture for #{name}" : "User avatar"
  end

  # Returns an inline SVG icon for flash messages to ensure accessibility
  # (no information conveyed by color alone).
  #
  # @param key [Symbol, String]
  # @return [String]
  def flash_icon(key)
    tone = key.to_sym

    case tone
    when :notice, :info
      '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>'.html_safe
    when :success
      '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>'.html_safe
    when :alert, :error
      '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"></circle><line x1="15" y1="9" x2="9" y2="15"></line><line x1="9" y1="9" x2="15" y2="15"></line></svg>'.html_safe
    when :warning
      '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>'.html_safe
    else
      '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"></circle></svg>'.html_safe
    end
  end

  private

  # Humanizes single audit attribute values for display.
  #
  # @param value [Object]
  # @return [String]
  def humanize_audit_value(value)
    return "none" if value.nil?
    return humanize_audit_list(value) if value.is_a?(Array)

    string = value.to_s.strip
    string.present? ? string : "none"
  end

  # Humanizes audit value arrays into comma-separated strings.
  #
  # @param values [Array]
  # @return [String]
  def humanize_audit_list(values)
    items = Array(values).map { |item| item.to_s.strip }.reject(&:blank?)
    return "none" if items.empty?

    items.join(", ")
  end
end
