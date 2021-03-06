require 'rails_helper'

RSpec.describe CaseComment, type: :model do

  before :each do
    @site = create(:site)
    cluster = create(:cluster, site: @site)
    @case = create(:case, cluster: cluster)
  end

  describe '#create' do
    it 'prevents empty comments' do
      admin = create(:admin)
      comment = CaseComment.new(
         case: @case,
         user: admin,
         text: ''
      )

      expect do
        comment.save!
      end.to raise_error(ActiveRecord::RecordInvalid)
      expect(comment.errors).to include :text
      expect(comment.errors[:text]).to include 'is too short (minimum is 2 characters)'
    end

    it 'prevents users from other sites commenting' do
      other_site = create(:site)
      other_user = create(:user, site: other_site)

      comment = CaseComment.new(
        case: @case,
        user: other_user,
        text: 'This comment is not allowed'
      )

      expect do
        comment.save!
      end.to raise_error(ActiveRecord::RecordInvalid)
      expect(comment.errors).to include :user
      expect(comment.errors[:user]).to include 'does not have permission to post a comment on this case'
    end

    it 'allows users from the correct site to comment' do
      my_user = create(:user, site: @site)

      my_comment = CaseComment.create!(
         case: @case,
         user: my_user,
         text: 'This comment is allowed'
      )

      expect(@case.case_comments.first).to eq(my_comment)
    end

    it 'allows admins to comment' do
      my_comment = CaseComment.create!(
         case: @case,
         user: create(:admin),
         text: 'This comment is allowed'
      )

      expect(@case.case_comments.first).to eq(my_comment)
    end
  end
end
