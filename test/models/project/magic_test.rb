require "test_helper"

class Project::MagicTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @reviewer = create_user(slack_id: "U_MAGIC_REVIEWER", display_name: "magic_reviewer")
    @admin    = create_user(slack_id: "U_MAGIC_ADMIN",    display_name: "magic_admin")
    @owner    = create_user(slack_id: "U_MAGIC_OWNER",    display_name: "magic_owner")
    @project  = Project.create!(title: "Cool project", description: "d")
    @project.memberships.create!(user: @owner, role: :owner)
    @magic = Project::Magic.new(@project)
  end

  test "nominate records who proposed the project without making it a Super Star" do
    assert @magic.nominate(@reviewer)

    @project.reload
    assert @project.fire_nomination_pending?
    assert_equal @reviewer, @project.nominated_fire_by
    assert_not @project.fire?
  end

  test "nominate is rejected when the project is already nominated" do
    @magic.nominate(@reviewer)

    refute Project::Magic.new(@project.reload).nominate(@reviewer)
  end

  test "nominate is rejected once the project is a Super Star" do
    @magic.grant(@admin)

    refute Project::Magic.new(@project.reload).nominate(@reviewer)
  end

  test "withdraw_nomination clears the proposal" do
    @magic.nominate(@reviewer)

    assert Project::Magic.new(@project.reload).withdraw_nomination(@reviewer)
    assert_not @project.reload.nominated_fire_at?
  end

  test "withdraw_nomination is rejected when there is no nomination" do
    refute @magic.withdraw_nomination(@reviewer)
  end

  test "grant promotes a nominated project and keeps the nomination as provenance" do
    @magic.nominate(@reviewer)

    assert Project::Magic.new(@project.reload).grant(@admin)

    @project.reload
    assert @project.fire?
    assert_equal @admin, @project.marked_fire_by
    assert_equal @reviewer, @project.nominated_fire_by
  end

  test "grant works on a project that was never nominated" do
    assert @magic.grant(@admin)
    assert @project.reload.fire?
  end

  test "grant posts a fire event and mails the prize" do
    assert_enqueued_with(job: Project::MagicHappeningLetterJob) do
      assert_difference "Post::FireEvent.count", 1 do
        @magic.grant(@admin)
      end
    end
  end

  test "grant is rejected when the project is already a Super Star" do
    @magic.grant(@admin)

    refute Project::Magic.new(@project.reload).grant(@admin)
  end

  test "revoke removes the Super Star but leaves the nomination intact" do
    @magic.nominate(@reviewer)
    Project::Magic.new(@project.reload).grant(@admin)

    assert Project::Magic.new(@project.reload).revoke(@admin)

    @project.reload
    assert_not @project.fire?
    assert @project.fire_nomination_pending?
  end

  test "revoke is rejected when the project is not a Super Star" do
    refute @magic.revoke(@admin)
  end
end
