
When %r/^the client sends a updated file "([^\"]*)" with the id (\d+) via the REST API$/ do |file, report_id|
  report_id = MeegoTestSession.find(:first).id
  post "/api/update/#{report_id}?auth_token=foobar", {
      "report"          => Rack::Test::UploadedFile.new("features/resources/#{file}", "text/xml")
  }
  response.should be_success
end

When "the client sends an updated result file" do
  step %{the client sends a updated file "sim_new.xml" with the id 1 via the REST API}
end

When "the client sends an updated but invalid result file" do
  step %{the client sends a updated file "invalid.xml" with the id 1 via the REST API}
end

When "the client sends an updated file with invalid extension" do
  step %{the client sends a updated file "invalid_ext.txt" with the id 1 via the REST API}
end

When "I have sent a file with NFT results" do
  step %{the client sends file "features/resources/serial_result.xml" via the REST API}
  step %{the upload succeeds}
end

When "I have sent a basic result file" do
  step %{the client sends a basic test result file}
end

When "the client sends several updated files" do
  step %{the client sends several updated files with the id 1 via the REST API}
end

When "the client sends a valid and an invalid file" do
  step %{the client sends 1 updated valid file, and 1 invalid file with the id 1 via the REST API}
end

When %r/^the client sends several updated files with the id (\d+) via the REST API$/ do |report_id|
  report_id = MeegoTestSession.find(:first).id
  post "/api/update/#{report_id}?auth_token=foobar", {
      "report.1"        => Rack::Test::UploadedFile.new("features/resources/sim_new.xml", "text/xml"),
      "report.2"        => Rack::Test::UploadedFile.new("features/resources/bluetooth.xml", "text/xml"),
  }
  response.should be_success
end

When %r/^the client sends 1 updated valid file, and 1 invalid file with the id (\d+) via the REST API$/ do |report_id|
  report_id = MeegoTestSession.find(:first).id
  post "/api/update/#{report_id}?auth_token=foobar", {
      "report.1"        => Rack::Test::UploadedFile.new("features/resources/sim_new.xml", "text/xml"),
      "report.2"        => Rack::Test::UploadedFile.new("features/resources/invalid.xml", "text/xml"),
  }
  response.should be_success
end

Then "I see NFT results" do
  step %{I should find element "#detailed_nft_results"}
  step %{I should find element "a[href='#detailed_nft_results']" within ".toc"}
end

Then "I should not see NFT results" do
  step %{I should not find element "#detailed_nft_results"}
  step %{I should not find element "a[href='#detailed_nft_results']" within ".toc"}
end
