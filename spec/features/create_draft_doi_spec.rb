# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'creating a draft DOI', :datacite_api, :js do
  let(:model_class) do
    Class.new(GenericWork) do
      include Hyrax::DOI::DOIBehavior
      include Hyrax::DOI::DataCiteDOIBehavior
    end
  end
  let(:form_class) do
    Class.new(Hyrax::GenericWorkForm) do
      include Hyrax::DOI::DOIFormBehavior
      include Hyrax::DOI::DataCiteDOIFormBehavior

      self.model_class = GenericWork
    end
  end
  let(:helper_module) do
    Module.new do
      include ::BlacklightHelper
      include Hyrax::BlacklightOverride
      include Hyrax::HyraxHelperBehavior
      include Hyrax::DOI::HelperBehavior
    end
  end
  let(:solr_document_class) do
    Class.new(SolrDocument) do
      include Hyrax::DOI::SolrDocument::DOIBehavior
      include Hyrax::DOI::SolrDocument::DataCiteDOIBehavior
    end
  end
  let(:controller_class) do
    Class.new(::ApplicationController) do
      # Adds Hyrax behaviors to the controller.
      include Hyrax::WorksControllerBehavior
      include Hyrax::BreadcrumbsForWorks
      self.curation_concern_type = GenericWork

      # Use this line if you want to use a custom presenter
      self.show_presenter = Hyrax::GenericWorkPresenter

      helper Hyrax::DOI::Engine.helpers
    end
  end

  let(:prefix) { '10.1234' }
  let(:user) { create(:admin) }

  before do
    # Override test app classes and module to simulate generators having been run
    stub_const("GenericWork", model_class)
    stub_const("Hyrax::GenericWorkForm", form_class)
    stub_const("HyraxHelper", helper_module)
    stub_const("SolrDocument", solr_document_class)
    stub_const("Hyrax::GenericWorksController", controller_class)

    Hyrax.config.identifier_registrars = { datacite: Hyrax::DOI::DataCiteRegistrar }
    Hyrax::DOI::DataCiteRegistrar.mode = :test
    Hyrax::DOI::DataCiteRegistrar.prefix = prefix
    Hyrax::DOI::DataCiteRegistrar.username = 'username'
    Hyrax::DOI::DataCiteRegistrar.password = 'password'

    allow_any_instance_of(Ability).to receive(:admin_set_with_deposit?).and_return(true)
    allow_any_instance_of(Ability).to receive(:can?).and_call_original
    allow_any_instance_of(Ability).to receive(:can?).with(:new, anything).and_return(true)

    sign_in user
  end

  scenario 'creates a draft DOI on the form' do
    visit "/concern/generic_works/new"
    click_link "doi-create-draft-btn"
    expect(page).to have_field('generic_work_doi', with: '10.1234/draft-doi')
  end
end