require 'minitest/autorun'
require 'climate_control'
require_relative '../lib/options.rb'
require_relative 'test_helper.rb'

class TestOptions < Minitest::Test
  def test_add
    assert_equal (4+1), 5
  end

  def test_run_the_stack_with_no_kill
    tasks = Options.parse(['--run-the-stack', '--no-kill'])
    refute(tasks[:kill_all])
  end

  def test_export_with_no_explicit_destination
    tasks = Options.parse(['--export'])
    assert(tasks[:build])
    assert(tasks[:export])
    assert_equal(['--rm','export'], tasks[:awestruct_command_args])
  end

  def test_export_with_specified_destination
    tasks = Options.parse(['--export','foo@bar:/tmp/foo'])
    assert(tasks[:build])
    assert_equal(['--rm','export','foo@bar:/tmp/foo'], tasks[:awestruct_command_args])
  end

  def test_rollback_site_to
    tasks = Options.parse(['--rollback-site-to','export-foo'])
    assert(tasks[:build])
    assert_equal(['--rm','rollback','export-foo'], tasks[:awestruct_command_args])
    assert_equal([], tasks[:supporting_services])
  end

  def test_no_pull_option
    tasks = Options.parse(['--no-pull'])
    refute(tasks[:docker_pull])
  end

  def test_no_pull_defaults_to_environment_if_not_specified
    tasks = Options.parse(['-e', 'drupal-dev'])
    assert(tasks[:docker_pull])
  end


  def test_no_pull_overrides_environment_default
    tasks = Options.parse(['-e', 'drupal-dev', '--no-pull'])
    refute(tasks[:docker_pull])
  end

  def test_loads_drupal_dev_environment_by_default
    tasks = Options.parse(['-t'])
    rhd_environment = tasks[:environment]
    assert_equal('drupal-dev', rhd_environment.environment_name)
  end

  def test_loads_specified_environment
    tasks = Options.parse(['-e drupal-pull-request'])
    rhd_environment = tasks[:environment]
    assert_equal('drupal-pull-request', rhd_environment.environment_name)
  end

  def test_decrypt

    tasks = Options.parse (["-b"])
    assert(tasks[:decrypt])

    tasks = Options.parse (["-p"])
    assert(tasks[:decrypt])

    tasks = Options.parse (["-r"])
    assert(tasks[:decrypt])

    tasks = Options.parse (["-p"])
    assert(tasks[:decrypt])

    tasks = Options.parse (["-g"])
    assert(tasks[:decrypt])

    tasks = Options.parse (["--run-the-stack"])
    assert(tasks[:decrypt])

    tasks = Options.parse (['-u'])
    assert(tasks[:decrypt])

    tasks = Options.parse (['-t'])
    assert(tasks[:decrypt])
  end

  def test_backup_with_no_backup_name
    tasks = Options.parse (["--backup"])
    assert(tasks[:build])
    assert_equal(['--rm', 'backup',''], tasks[:awestruct_command_args])
    assert_equal(%w(), tasks[:supporting_services])
  end

  def test_backup_with_supplied_backup_name
    tasks = Options.parse (["--backup", "my-backup-name"])
    assert(tasks[:build])
    assert_equal(['--rm', 'backup', 'my-backup-name'], tasks[:awestruct_command_args])
    assert_equal(%w(), tasks[:supporting_services])
  end

  def test_set_build
    tasks = Options.parse (["-b"])
    assert(tasks[:build])
    assert_equal([], tasks[:supporting_services])
    assert_equal(nil, tasks[:awestruct_command_args])
  end

  def test_kill_drupal_dev
    tasks = Options.parse (['-e drupal-dev',"-r"])
    assert(tasks[:kill_all])
    assert_equal(tasks[:supporting_services], %w(apache drupalmysql drupal))
    assert_equal(nil, tasks[:awestruct_command_args])
  end

  def test_kill_drupal_pull_request
    tasks = Options.parse (['-e drupal-pull-request',"-r"])
    assert(tasks[:kill_all])
    assert_equal(tasks[:supporting_services], %w(drupalmysql drupal))
    assert_equal(nil, tasks[:awestruct_command_args])
  end

  def test_kill_drupal_staging
    tasks = Options.parse (['-e drupal-staging',"-r"])
    assert(tasks[:kill_all])
    assert_equal(tasks[:supporting_services], %w(drupal))
    assert_equal(nil, tasks[:awestruct_command_args])
  end

  def test_kill_drupal_production
    tasks = Options.parse (['-e drupal-production',"-r"])
    assert(tasks[:kill_all])
    assert_equal(tasks[:supporting_services], %w(drupal))
    assert_equal(nil, tasks[:awestruct_command_args])
  end

  def test_awestruct_command_drupal_dev
    tasks = Options.parse ['-e drupal-dev', '-p']
    # If we're using drupal, we don't need to do a preview in awestruct
    %w(--rm --service-ports awestruct).each do |commands|
      assert_includes tasks[:awestruct_command_args], commands
    end

    tasks = Options.parse ['-e drupal-dev', '-g']
    %w(--rm --service-ports awestruct).each do |commands|
      assert_includes tasks[:awestruct_command_args], commands
    end
  end

  def test_awestruct_command_drupal_pull_request_environment
    tasks = Options.parse ['-e drupal-pull-request', '-p']
    # If we're using drupal, we don't need to do a preview in awestruct
    %w(--rm --service-ports awestruct).each do |commands|
      assert_includes tasks[:awestruct_command_args], commands
    end

    tasks = Options.parse ['-e drupal-pull-request', '-g']
    ['--rm', '--service-ports', 'awestruct'].each do |commands|
      assert_includes tasks[:awestruct_command_args], commands
    end
  end

  def test_run_the_stack_with_no_decrypt
    tasks = Options.parse (['-e drupal-dev', '--run-the-stack', '--no-decrypt'])
    assert(tasks[:kill_all])
    refute(tasks[:decrypt])
    assert_equal(tasks[:unit_tests], expected_unit_test_tasks)
    assert_equal(%w(apache drupalmysql drupal), tasks[:supporting_services])
  end

  def test_run_tests_with_no_decrypt
    tasks = Options.parse (['-e drupal-dev', '-t', '--no-decrypt'])
    refute(tasks[:kill_all])
    refute(tasks[:decrypt])
    assert_equal(tasks[:unit_tests], expected_unit_test_tasks)
    assert_equal(%w(), tasks[:supporting_services])
  end

  def test_run_the_stack_drupal_dev
    tasks = Options.parse (['-e drupal-dev', "--run-the-stack"])
    assert(tasks[:kill_all])
    assert(tasks[:decrypt])
    assert_equal(tasks[:unit_tests], expected_unit_test_tasks)
    assert_equal(%w(apache drupalmysql drupal), tasks[:supporting_services])
  end

  def test_run_the_stack_drupal_pull_request

    tasks = Options.parse (['-e drupal-pull-request', "--run-the-stack"])

    assert(tasks[:kill_all])
    assert(tasks[:decrypt])
    assert_equal(tasks[:unit_tests], expected_unit_test_tasks)
    assert_equal(%w(drupalmysql drupal), tasks[:supporting_services])
  end

  def test_test_task
    tasks = Options.parse(["-t"])
    assert(tasks[:build])
    assert(tasks[:decrypt])
    assert_equal(tasks[:unit_tests], expected_unit_test_tasks)
    assert_equal(nil, tasks[:awestruct_command_args])
  end

  private def expected_unit_test_tasks
    %w(--no-deps --rm unit_tests)
  end
end
