require "test_helper"

class Mission::SubmissionTest < ActiveSupport::TestCase
  setup do
    @builder = User.create!(email: "builder-#{SecureRandom.hex(4)}@example.test",
                            display_name: "builder-#{SecureRandom.hex(4)}",
                            slack_id: "U#{SecureRandom.hex(8)}")
    @project = Project.create!(title: "Queue Age Project")
    @project.memberships.create!(user: @builder, role: :owner)
    @mission = create_mission
    @project.mission_attachments.create!(mission: @mission)
  end

  test "certifying stamps pending_at with the queue entry time" do
    submission = ship_to_mission!(@project, @builder, @mission)
    assert_nil submission.pending_at

    travel 2.days do
      submission.certify!
      assert_in_delta Time.current, submission.reload.pending_at, 1.second
    end
  end

  test "undo restamps pending_at so queue age counts from the last review" do
    submission = ship_to_mission!(@project, @builder, @mission)
    submission.certify!
    first_entry = submission.reload.pending_at

    travel 3.days do
      submission.approve!
      submission.undo!
      assert_operator submission.reload.pending_at, :>, first_entry
      assert_in_delta Time.current, submission.pending_at, 1.second
    end
  end

  test "queue_entered_at falls back to created_at when pending_at is unset" do
    submission = ship_to_mission!(@project, @builder, @mission, status: "pending")
    assert_nil submission.pending_at
    assert_equal submission.created_at, submission.queue_entered_at

    submission.update_column(:pending_at, 1.hour.ago)
    assert_equal submission.pending_at, submission.reload.queue_entered_at
  end
end
