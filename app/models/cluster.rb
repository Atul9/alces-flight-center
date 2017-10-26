class Cluster < ApplicationRecord
  include AdminConfig::Cluster
  include HasSupportType
  include MarkdownDescription

  SUPPORT_TYPES = SupportType::VALUES

  belongs_to :site
  has_many :component_groups, dependent: :destroy
  has_many :components, through: :component_groups, dependent: :destroy
  has_many :cases

  validates_associated :site
  validates :name, presence: true
  validates :support_type, inclusion: { in: SUPPORT_TYPES }, presence: true
  validates :canonical_name, presence: true
  validate :validate_all_components_advice, if: :advice?

  before_validation CanonicalNameCreator.new, on: :create

  # Automatically picked up by rails_admin so only these options displayed when
  # selecting support type.
  def support_type_enum
    SUPPORT_TYPES
  end

  def case_form_json
    {
      id: id,
      name: name,
      components: components.map(&:case_form_json),
      supportType: support_type,
    }
  end

  def managed_components
    components.select(&:managed?)
  end

  def advice_components
    components.select(&:advice?)
  end

  def documents_path
    File.join(
      ENV.fetch('AWS_DOCUMENTS_PREFIX'),
      site.canonical_name,
      canonical_name
    )
  end

  def documents
    @documents ||= DocumentsRetriever.retrieve(documents_path)
  end

  private

  def validate_all_components_advice
    unless components.all?(&:advice?)
      errors.add(:base, 'advice Cluster cannot be associated with managed Components')
    end
  end

  Document = Struct.new(:name, :url)

  module DocumentsRetriever
    class << self
      ACCESS_KEY_ID = ENV.fetch('AWS_ACCESS_KEY_ID')
      SECRET_ACCESS_KEY = ENV.fetch('AWS_SECRET_ACCESS_KEY')
      BUCKET = ENV.fetch('AWS_DOCUMENTS_BUCKET')
      REGION = ENV.fetch('AWS_REGION')

      def retrieve(documents_path)
        objects_under_path(documents_path).map do |object|
          name = File.basename(object.key)
          url = presigned_url_for(object)
          Document.new(name, url)
        end
      end

      private

      def objects_under_path(path)
        s3 = Aws::S3::Resource.new(
          access_key_id: ACCESS_KEY_ID,
          secret_access_key: SECRET_ACCESS_KEY,
          region: REGION
        )
        response = s3.client.list_objects(
          bucket: BUCKET,
          prefix: path
        )
        response.contents
      end

      def presigned_url_for(object)
        presigner = Aws::S3::Presigner.new
        presigner.presigned_url(
          :get_object,
          bucket: BUCKET,
          key: object.key,
          expires_in: 60.minutes.to_i
        )
      end
    end
  end
end
