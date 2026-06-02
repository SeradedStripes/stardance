require "test_helper"

class Projects::FireNominationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @reviewer = create_user(slack_id: "U_NOM_REVIEWER", display_name: "nom_reviewer")
    @regular  = create_user(slack_id: "U_NOM_REGULAR",  display_name: "nom_regular")
    @reviewer.update!(granted_roles: [ "project_certifier" ])
    @project = Project.create!(title: "Nominate me", description: "d")
  end

  test "a Shipwright can nominate a project" do
    sign_in @reviewer

    post project_fire_nomination_path(@project)

    assert_redirected_to project_path(@project)
    assert @project.reload.fire_nomination_pending?
    assert_equal @reviewer, @project.nominated_fire_by
  end

  test "a YSWS reviewer can nominate a project" do
    ysws = create_user(slack_id: "U_NOM_YSWS", display_name: "nom_ysws")
    ysws.update!(granted_roles: [ "guardian_of_integrity" ])
    sign_in ysws

    post project_fire_nomination_path(@project)

    assert_redirected_to project_path(@project)
    assert_equal ysws, @project.reload.nominated_fire_by
  end

  test "a Shipwright can withdraw a nomination" do
    Project::Magic.new(@project).nominate(@reviewer)
    sign_in @reviewer

    delete project_fire_nomination_path(@project)

    assert_redirected_to project_path(@project)
    assert_not @project.reload.nominated_fire_at?
  end

  test "a non-reviewer cannot nominate" do
    sign_in @regular

    post project_fire_nomination_path(@project)

    assert_response :forbidden
    assert_not @project.reload.nominated_fire_at?
  end

  test "a logged-out visitor is sent to sign in instead of nominating" do
    post project_fire_nomination_path(@project)

    assert_redirected_to root_path
    assert_not @project.reload.nominated_fire_at?
  end
end
