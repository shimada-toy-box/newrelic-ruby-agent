# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.

require File.expand_path(File.join(File.dirname(__FILE__),'..','test_helper'))

# look through the source code to enforce some simple rules that help us keep
# our license data up to date.
class LicenseTest < Test::Unit::TestCase

  # A list of regexs that will likely match license info
  LICENSE_TERMS = {
    'GPL' => /GPL/i,
    '(c)' => /\(c\)/i,
    'Copyright' => /copyright/i,
    'BSD' => /\bBSD\b/i,
    'MIT' => /\bMIT\b/i,
    'Apache' => /\bapache\b/i,
  }

  # Known occurrences of the above license terms
  EXPECTED_LICENSE_OCCURRENCES = {
    ['/lib/new_relic/okjson.rb', '(c)'] => 3, # methods arguments like (c)
    ['/test/new_relic/agent/instrumentation/active_record_instrumentation_test.rb', '(c)'] => 2, # methods arguments like (c)
    ['/lib/new_relic/okjson.rb', 'Copyright'] => 3, # okjson license info
    ['/lib/new_relic/timer_lib.rb', '(c)'] => 1, # timer_lib license info
    ['/lib/new_relic/timer_lib.rb', 'Copyright'] => 1, # timer_lib license info
    ['/LICENSE', 'GPL'] => 1, # dual license info for system_timer
    ['/LICENSE', 'MIT'] => 3,
    ['/LICENSE', '(c)'] => 3,
    ['/LICENSE', 'Copyright'] => 11,
    ['/ui/views/newrelic/file/javascript/jquery-1.4.2.js', 'GPL'] => 3,
    ['/ui/views/newrelic/file/javascript/jquery-1.4.2.js', 'BSD'] => 2,
    ['/ui/views/newrelic/file/javascript/jquery-1.4.2.js', 'Copyright'] => 3,
    ['/ui/views/newrelic/file/javascript/jquery-1.4.2.js', 'MIT'] => 3,
    ['/test/new_relic/agent/agent_test_controller_test.rb', 'Apache'] => 1, # apache header tests
    ['/vendor/gems/metric_parser-0.1.0.pre1/lib/new_relic/metric_parser/solr.rb', 'Apache'] => 2, # parse apache solr metrics
    ['/vendor/gems/metric_parser-0.1.0.pre1/lib/new_relic/metric_parser/solr_request_handler.rb', 'Apache'] => 1, # parse apache solr metrics
  }

  def all_rb_and_js_files
    pattern = File.expand_path(gem_root + "/**/*.{rb,js}")
    Dir[pattern]
  end

  def all_files
    pattern = File.expand_path(gem_root + "/**/*")
    Dir[pattern]
  end

  def gem_root
    File.expand_path(File.dirname(__FILE__) + "/../../")
  end

  def shebang
    /^#!/
  end

  def encoding
    /^# ?(en)?coding: utf-8/
  end

  def syntax_mark
    /^# -\*- ruby -\*-/
  end

  def should_skip?(path)
    (
      # skip directories
      !File.file?(path) ||
      # skip binary files
      %w| .sqlite3 .log .png .ico .gif .gem |.include?(File.extname(path)) ||
      # skip this file
      File.expand_path(__FILE__) == path ||
      # skip rpm_test_app and other stuff that ends up in tmp
      path.include?(gem_root + '/tmp/') ||
      # skip tags file
      path.include?(gem_root + '/tags')||
      # skip the auto-generated build.rb file
      path =~ %r{lib/new_relic/build\.rb} ||
      # skip tags file
      path =~ %r{/tags$}
    )
  end

  def test_all_rb_and_js_files_have_license_header
    all_rb_and_js_files.each do |filename|
      next if should_skip?(filename)

      first_four_lines = File.read(filename, 1000).split("\n")[0...4]
      if first_four_lines.first =~ shebang
        first_four_lines.shift # discard it
      end
      if first_four_lines.first =~ syntax_mark
        first_four_lines.shift # discard it
      end
      if first_four_lines.first =~ encoding
        first_four_lines.shift # discard it
      end

      assert_match(/This file is distributed under .+ license terms\./, first_four_lines[0], "#{filename} does not contain the proper license header.")
      assert_match(%r"See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.", first_four_lines[1])
    end
  end

  def test_for_scary_license_terms
    files_to_check = all_files.reject { |f| should_skip?(f) }
    files_to_check.each do |filename|
      LICENSE_TERMS.each do |key, pattern|
        # we're checking this one.  We'll update the count of checked files below.
        occurrences = File.readlines(filename).grep(pattern).size
        expected = (EXPECTED_LICENSE_OCCURRENCES[[filename.sub(gem_root, ''), key]] || 0)
        assert_equal expected, occurrences, "#{filename} contains #{key} #{occurrences} times. Should be #{expected}"
      end
    end
    # sanity check that we are not skipping all the files.
    checked_files = files_to_check.size
    assert checked_files >= 390, "Somethings off. We only scanned #{checked_files} files for license info.  There should be more."
  end
end
