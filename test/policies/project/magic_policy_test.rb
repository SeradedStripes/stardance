require "test_helper"

class Project::MagicPolicyTest < ActiveSupport::TestCase
  setup do
    @admin    = create_user(slack_id: "U_POLICY_ADMIN",    display_name: "policy_admin")
    @reviewer = create_user(slack_id: "U_POLICY_REVIEWER", display_name: "policy_reviewer")
    @ysws     = create_user(slack_id: "U_POLICY_YSWS",     display_name: "policy_ysws")
    @regular  = create_user(slack_id: "U_POLICY_REGULAR",  display_name: "policy_regular")

    @admin.update!(granted_roles: [ "admin" ])
    @reviewer.update!(granted_roles: [ "project_certifier" ])
    @ysws.update!(granted_roles: [ "guardian_of_integrity" ])

    @magic = Project::Magic.new(Project.new)
  end

  test "granting a Super Star is admin-only" do
    assert policy(@admin).create?
    assert policy(@admin).destroy?

    refute policy(@reviewer).create?
    refute policy(@ysws).create?
    refute policy(@regular).create?
    refute policy(nil).create?
  end

  test "nominating is open to Shipwrights, YSWS reviewers, and admins" do
    assert policy(@admin).nominate?
    assert policy(@reviewer).nominate?
    assert policy(@ysws).nominate?

    refute policy(@regular).nominate?
    refute policy(nil).nominate?
  end

  test "withdrawing a nomination follows the same rule as nominating" do
    assert policy(@reviewer).withdraw_nomination?
    assert policy(@ysws).withdraw_nomination?
    refute policy(@regular).withdraw_nomination?
    refute policy(nil).withdraw_nomination?
  end

  private
    def policy(user)
      Project::MagicPolicy.new(user, @magic)
    end
end
