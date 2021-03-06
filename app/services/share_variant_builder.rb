# frozen_string_literal: true

require 'share_progress'

# rubocop:disable ClassLength
class ShareVariantBuilder
  class << self
    def create(params:, variant_type:, page:, url:)
      new(params, variant_type, page, url, nil).create
    end

    def update(params:, variant_type:, page:, id:)
      new(params, variant_type, page, nil, id).update
    end

    def destroy(params:, variant_type:, page:, id:)
      new(params, variant_type, page, nil, id).destroy
    end

    def update_button_url(url, button)
      if button.share_progress?
        sp_button = ShareProgress::Button.new(id: button.sp_id,
                                              page_url: url,
                                              button_template: "sp_#{variant_initials(button.share_type)}_large")
        return unless sp_button.save
      end
      button.update(url: url)
    end

    def variant_initials(variant_type)
      {
        facebook: 'fb',
        twitter: 'tw',
        email: 'em'
      }[variant_type.to_sym]
    end
  end

  def initialize(params, variant_type, page, url = nil, id = nil)
    @page = page
    @params = params.except(:name)
    @variant_type = variant_type.to_sym
    @url = url
    @id = id
  end

  def update
    @variant = variant_class.find(@id)
    @variant.assign_attributes(@params)
    return @variant if @variant.changed.empty? || @variant.invalid?

    @button = Share::Button.find_by(share_type: @variant_type, page_id: @page.id)
    update_and_return
  end

  def create
    @variant = variant_class.new(@params)
    @variant.page = @page
    return @variant unless @variant.valid?

    @button = Share::Button.find_or_initialize_by(share_type: @variant_type, page_id: @page.id)
    @variant.button = @button
    update_and_return
  end

  def destroy
    @variant = variant_class.find(@id)
    @button = Share::Button.find_by(share_type: @variant_type, page_id: @page.id)

    if @variant.share_progress?
      sp_button = ShareProgress::Button.new(share_progress_button_params(@variant, @button))
      sp_variant = sp_variant_class.new(id: @variant.sp_id, button: sp_button)
      unless sp_variant.destroy
        add_sp_errors_to_variant(sp_variant, @variant)
        return @variant
      end
    end
    @variant.destroy
    @variant
  end

  private

  def update_and_return
    if @variant.share_progress?
      update_sp_resources
    else
      update_button
      @variant.save
    end
    @variant
  end

  def update_button
    # Update with other options when we will support other non-sp share types.
    # Note that the share button html MUST have a css class - otherwise it'll be missed by Shares.get_all
    # Add a class that indicates the variant type, and in _share.liquid, add a class that identifies the variant/button.
    case @variant_type
    when :whatsapp
      @button.update(
        share_button_html: '<a class="whatsapp_large" href="https://api.whatsapp.com/send?text={TEXT}"></a>',
        url: @url
      )
    end
  end

  def update_sp_resources
    sp_button = ShareProgress::Button.new(share_progress_button_params(@variant, @button))
    if sp_button.save
      @button.update(sp_id: sp_button.id, share_button_html: sp_button.share_button_html, url: sp_button.page_url)
      @variant.update(sp_id: sp_button.variants[@variant_type].last[:id])
    else
      add_sp_errors_to_variant(sp_button, @variant)
    end
  end

  def add_sp_errors_to_variant(sp_button, variant)
    if sp_button.errors.key? 'variants'
      variant.add_errors(sp_button.errors['variants'][0])
    else
      sp_button.errors.each_value do |val|
        variant.add_errors(val[0])
      end
    end
  rescue NoMethodError
    # in case SP just starts returning something wonky and the array access raises NoMethodError
    variant.add_errors([sp_button.errors.to_s])
  end

  def share_progress_button_params(variant, button)
    {
      page_url: @url || button.url,
      button_template: "sp_#{self.class.variant_initials(@variant_type)}_large",
      page_title: "#{@page.title} [#{@variant_type}]",
      variants: send("#{@variant_type}_variants", variant),
      id: button.sp_id
    }
  end

  def facebook_variants(variant)
    {
      facebook: [
        {
          facebook_title: variant.title,
          facebook_description: variant.description,
          facebook_thumbnail: variant.image.blank? ? nil : variant.image.content(:facebook),
          id: variant.sp_id
        }
      ]
    }
  end

  def twitter_variants(variant)
    {
      twitter: [
        {
          twitter_message: variant.description,
          id: variant.sp_id
        }
      ]
    }
  end

  def email_variants(variant)
    {
      email: [
        {
          email_subject: variant.subject,
          email_body: variant.body,
          id: variant.sp_id
        }
      ]
    }
  end

  def sp_variant_class
    "ShareProgress::#{@variant_type.to_s.classify}Variant".constantize
  end

  def variant_class
    "Share::#{@variant_type.to_s.classify}".constantize
  end
end
# rubocop:enable ClassLength
