Before do
  load "#{Rails.root}/db/seeds.rb"

  @default_api_opts = {
    "auth_token"      => "foobar",
    "release_version" => "1.2",
    "target"          => "Core",
    "testset"         => "automated",
    "product"         => "N900",
    "tested_at"       => Date.today.to_s,
    "result_files[]"  => Rack::Test::UploadedFile.new("features/resources/sim.xml", "text/xml")
  }

  @default_api_opts_all = @default_api_opts.merge({
    "title"                => "My Test Report",
    "objective_txt"        => "To notice regression",
    "build_txt"            => "foobar-image.bin",
    "build_id"             => "1234.78a",
    "environment_txt"      => "Laboratory environment",
    "qa_summary_txt"       => "Ready to ship",
    "issue_summary_txt"    => "No major issues found",
    "patches_included_txt" => "No patches included"
  })

  # The oldest API (hwproduct and testtype have since been renamed)
  @default_version_1_api_opts = @default_api_opts.merge({
    "hwproduct"       => "N900",
    "testtype"        => "automated"
  })
  @default_version_1_api_opts.delete("testset")
  @default_version_1_api_opts.delete("product")

  # The 2nd API (hardware has since been renamed)
  @default_version_2_api_opts = @default_api_opts.merge({
    "hardware"        => "N900"
  })
  @default_version_2_api_opts.delete("product")

  @defalt_api_opts_csv_shortcut = @default_api_opts.merge({
    "issue_summary_csv"     => "BZ#9353, BZ#1234",
    "patches_included_csv"  => "5678, 2582"
  })

  @mapped_api_opts = {
    "auth_token"      => "foobar",
    "platform"        => "1.2",
    "branch"          => "Core",
    "team"            => "automated",
    "testtype"        => "N900",
    "tested_at"       => Date.today.to_s,
    "result_files[]"  => Rack::Test::UploadedFile.new("features/resources/sim.xml", "text/xml")
  }

  @mozilla_bugzilla = {
    "name"     => "Mozilla Bugzilla",
    "server"   => "bugzilla.mozilla.org",
    "port"     => 443,
    "use_ssl"  => true,
    "prefix"   => "MOZ",
    "default"  => false,
    "type"     => "bugzilla",
    "uri"      => "/buglist.cgi?bugidtype=include&columnlist=short_desc%%2Cbug_status%%2Cresolution&query_format=advanced&ctype=csv&bug_id=%s",
    "link_uri" => "https://bugzilla.mozilla.org/show_bug.cgi?id=%s"
  }

  @cyanogen_gerrit = {
    "name"      => "Cyanogen Gerrit",
    "prefix"    => "GER",
    "link_uri"  => "http://review.cyanogenmod.org/#/c/%s/",
    "default"   => false,
    "type"      => "link"
  }
end

After do
  #visit destroy_user_session_path
  #DatabaseCleaner.clean
  Rails.cache.clear
end
