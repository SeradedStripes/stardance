require "test_helper"

class Projects::MagicControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin    = create_user(slack_id: "U_MAGICCTL_ADMIN",    display_name: "magicctl_admin")
    @reviewer = create_user(slack_id: "U_MAGICCTL_REVIEWER", display_name: "magicctl_reviewer")
    @admin.update!(granted_roles: [ "admin" ])
    @reviewer.update!(granted_roles: [ "project_certifier" ])
    @project = Project.create!(title: "Approve me", description: "d")
  end

  test "an admin approves a nomination, turning it into a Super Star" do
    Project::Magic.new(@project).nominate(@reviewer)
    sign_in @admin

    post project_magic_path(@project)

    assert_redirected_to project_path(@project)
    assert @project.reload.fire?
  end

  test "an admin can revoke a Super Star" do
    Project::Magic.new(@project).grant(@admin)
    sign_in @admin

    delete project_magic_path(@project)

    assert_redirected_to project_path(@project)
    assert_not @project.reload.fire?
  end

  test "a Shipwright cannot grant a Super Star" do
    sign_in @reviewer

    post project_magic_path(@project)

    assert_response :forbidden
    assert_not @project.reload.fire?
  end
end
