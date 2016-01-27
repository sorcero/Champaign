require 'rails_helper'

describe FormElement do
  let(:form)    { create(:form) }
  let(:element) { create(:form_element, form: form) }

  it 'belongs to a form' do
    el = create(:form_element)
    expect(el.form).to be_a Form
  end

  describe '.create' do
    it 'sets position' do
      element_0 = create(:form_element, form: form)
      element_1 = create(:form_element, form: form)

      expect(element_0.position).to eq(0)
      expect(element_1.position).to eq(1)
    end

    describe 'name fixing' do
      it 'keeps name if whitelisted' do
        expect(
          create(:form_element, form: form, name: 'address1').name
        ).to eq('address1')
      end

      it 'prefixes custom names' do
        expect(
          create(:form_element, form: form, name: 'foo_bar').name
        ).to eq('action_foo_bar')
      end

      it 'does nothing when prefix is present' do
        expect(
          create(:form_element, form: form, name: 'action_foo_bar').name
        ).to eq('action_foo_bar')
      end
    end
  end

  describe '.update' do
    it 'does not change position' do
      expect{
        element.update(label: "Surname")
      }.to_not change{ element.reload.position}
    end
  end

  describe 'cascading touch' do
    let(:page)      { create(:page) }
    let!(:petition) { create(:plugins_petition, page: page) }

    it 'touches associated records' do
      future = Time.now.utc + 1.hour

      Timecop.freeze(future) do
        petition.form.form_elements.first.update(label: 'foo')
        expect(petition.page.reload.updated_at.to_s).to eq(future.to_s)
      end
    end
  end
end

