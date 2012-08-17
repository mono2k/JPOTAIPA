require 'rubygems'
require 'sinatra'
require 'rest-client'
require 'dm-core'
require 'dm-migrations'

# create our user object
class AppFile
  include DataMapper::Resource
  property :id,           Serial
  property :name,         String
  property :file_url,     String
end


configure :development do
  DataMapper::Logger.new($stdout, :debug)
  DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/ota_ipas.db")
  # make sure to migrate our database
  DataMapper.auto_upgrade!
  # finalize our data models
  DataMapper.finalize
  STDOUT.sync = true
end

configure :production do
  # Configure stuff here you'll want to
  # only be run at Heroku at boot

  # TIP:  You can get you database information
  #       from ENV['DATABASE_URI'] (see /env route below)
  # setup our data store
  DataMapper::Logger.new($stdout, :debug)
  unless ENV['DATABASE_URI'].nil?
    DataMapper.setup(:default, ENV['HEROKU_POSTGRESQL_TEAL_URL'])
  else
    DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/e2b.db")
  end
  # make sure to migrate our database
  DataMapper.auto_upgrade!
  # finalize our data models
  DataMapper.finalize
end

get '/' do
  @apps = AppFile.all
  erb :index
end

post "/upload" do
  puts params
  File.open('uploads/' + params['ipa'][:filename], "w") do |f|
    f.write(params['ipa'][:tempfile].read)
  end
  app = AppFile.new
  app.name = params['filelabel']
  app.file_url = "/uploads/" + params['ipa'][:filename]
  app.save
  return "OK"
end

__END__

@@ index
<!DOCTYPE html>
<html>
  <head>
    <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js"></script>
    <script src="http://ajax.cdnjs.com/ajax/libs/underscore.js/1.1.4/underscore-min.js"></script>
    <script src="http://ajax.cdnjs.com/ajax/libs/backbone.js/0.3.3/backbone-min.js"></script>
    <script type="text/javascript">
    sendForm(){
      alert("Uploading file");
      var formElement = document.getElementById("file");
      var oReq = new XMLHttpRequest();
      oReq.open("POST", "/upload");
      var newFormData = new FormData(formElement)
      newFormData.append("app_name", "test");
      oReq.send(newFormData);
    }
    </script>
  </head>
  <title>OTA Installs</title>
  <body>
    <div id="list">
      <% @apps.each do |app| %>
        <a href="<%= app.file_url %>">File</a>
      <% end %>
    </div>
    <form enctype="multipart/form-data" method="post" name="fileinfo">
      <label>Custom file label:</label>
      <input type="text" name="filelabel" size="12" maxlength="32" /><br />
      <label>File to stash:</label>
      <input type="file" name="ipa" required />
    </form>
    <!-- <a href="javascript:sendForm()" onclick="sendForm();">Upload file</a> -->
    <script type="text/javascript">
      $("[name=ipa]").change(function() {
        var oOutput = document.getElementById("output");
        var oData = new FormData(document.forms.namedItem("fileinfo"));

        oData.append("CustomField", "This is some extra data");

        var oReq = new XMLHttpRequest();
        oReq.open("POST", "/upload", true);
        oReq.onload = function(oEvent) {
          if (oReq.status == 200) {
            alert("Uploaded!");
          } else {
          }
        };

  oReq.send(oData);
      });
    </script>
  </body>
</html>