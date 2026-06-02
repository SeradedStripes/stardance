require "test_helper"

class Projects::FireControlsTest < ActionDispatch::IntegrationTest
  setup do
    @admin    = create_user(slack_id: "U_CTRL_ADMIN",    display_name: "ctrl_admin")
    @reviewer = create_user(slack_id: "U_CTRL_REVIEWER", display_name: "ctrl_reviewer")
    @ysws     = create_user(slack_id: "U_CTRL_YSWS",     display_name: "ctrl_ysws")
    @regular  = create_user(slack_id: "U_CTRL_REGULAR",  display_name: "ctrl_regular")
    @admin.update!(granted_roles: [ "admin" ])
    @reviewer.update!(granted_roles: [ "project_certifier" ])
    @ysws.update!(granted_roles: [ "guardian_of_integrity" ])
    @project = Project.create!(title: "Render me", description: "d")
  end

  test "admin sees mark button on a fresh project" do
    sign_in @admin
    get project_path(@project)
    assert_response :success
    assert_select "button", text: "Mark as Super Star"
  end

  test "a Shipwright sees the nominate button on a fresh project" do
    sign_in @reviewer
    get project_path(@project)
    assert_response :success
    assert_select "button", text: "Nominate for Super Star"
  end

  test "a YSWS reviewer sees the nominate button on a fresh project" do
    sign_in @ysws
    get project_path(@project)
    assert_response :success
    assert_select "button", text: "Nominate for Super Star"
  end

  test "regular user sees no fire controls" do
    sign_in @regular
    get project_path(@project)
    assert_response :success
    assert_select "button", text: "Nominate for Super Star", count: 0
  end

  test "admin sees approve on a nominated project" do
    Project::Magic.new(@project).nominate(@reviewer)
    sign_in @admin
    get project_path(@project)
    assert_response :success
    assert_select "button", text: "Approve Super Star"
    assert_match "Nominated by #{@reviewer.display_name}", response.body
  end
end
