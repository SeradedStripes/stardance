require "test_helper"

class LikePolicyTest < ActiveSupport::TestCase
  setup do
    @user = create_user(slack_id: "U_LIKE_POLICY_USER", display_name: "lpu")
    @likeable = post_devlogs(:one)
    @like = Like.new(user: @user, likeable: @likeable)
  end

  test "create? is false for nil user" do
    refute LikePolicy.new(nil, @like).create?
  end

  test "create? is false for a logged-in but unverified user" do
    @user.update!(verification_status: "needs_submission")
    refute LikePolicy.new(@user, @like).create?
  end

  test "create? is true once the user is verified" do
    @user.update!(verification_status: "verified")
    assert LikePolicy.new(@user, @like).create?
  end
end
