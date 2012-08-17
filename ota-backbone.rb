# OTA IPA plist url
# <a href="itms-services://?action=download-manifest&url=https://dl.dropbox.com/u/39652/mycampus.plist" class="btn btn-primary btn-large">Click here to install MyCampus OTA!</a>

require 'rubygems'
require 'sinatra'
require 'rest-client'
require 'dm-core'
require 'dm-migrations'

# setup for use with foreman
configure do
    set :app_file, __FILE__
    set :port, ENV['PORT']
    set :static, true
    set :public_folder, '.'
end

# create our user object
class AppFile
  include DataMapper::Resource
  property :id,           Serial
  property :name,         String
  property :file_url,     String
  property :plist_url,    String
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
  File.open('uploads/' + params['plist'][:filename], "w") do |f|
    f.write(params['plist'][:tempfile].read)
  end
  app = AppFile.new
  app.name = params['filelabel']
  app.file_url = "/uploads/" + params['ipa'][:filename]
  app.plist_url = "/uploads/" + params['ipa'][:filename]
  app.save
  return app.plist_url
end

__END__

@@ index
<!DOCTYPE html>
<html>
  <head>
    <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js"></script>
    <script src="http://ajax.cdnjs.com/ajax/libs/underscore.js/1.1.4/underscore-min.js"></script>
    <script src="http://ajax.cdnjs.com/ajax/libs/backbone.js/0.3.3/backbone-min.js"></script>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale = 1.0, minimum-scale = 1.0">
    <link href="./bootstrap/docs/assets/css/bootstrap.css" rel="stylesheet">
    <link href="./bootstrap/docs/assets/css/bootstrap-responsive.css" rel="stylesheet">
    <style>
      body {
        padding-top: 60px; /* 60px to make the container go all the way to the bottom of the topbar */
      }
    </style>
  </head>
  <title>OTA Installs</title>
  <body>
    <div class="navbar navbar-fixed-top">
      <div class="navbar-inner">
        <div class="container">
          <a class="brand" href="#">OTA IPAs</a>
        </div>
      </div>
    </div>
    <div class="container">
      <div id="list">
        <% @apps.each do |app| %>
          <a href="itms-services://?action=download-manifest&url=<%= app.plist_url %>" class="btn btn-primary btn-large"><%= app.name %></a><br/>
        <% end %>
      </div>
      <form enctype="multipart/form-data" method="post" name="fileinfo">
        <label>Name:</label>
        <input type="text" id="filelabel" name="filelabel" required /><br />
        <label>IPA:</label>
        <input type="file" name="ipa" required />
        <label>Plist:</label>
        <input type="file" name="plist" id="plist" required />
      </form>
      <button id="add-app">Upload App</button>
      <!-- Backbone model at the bottom here -->
      <script>
        (function ($) { 
          IPA = Backbone.Model.extend({
            //Create a model to hold friend atribute
            name: null,
            ipa_file: null,
            plist_file: null
          });
          
          IPAs = Backbone.Collection.extend({
            //This is our Friends collection and holds our Friend models
            initialize: function (models, options) {
              this.bind("add", options.view.addIPALi);
              //Listen for new additions to the collection and call a view function if so
              this.bind("change", options.view.renderUpdate);
            }
          });
          
          AppView = Backbone.View.extend({
            el: $("body"),
            initialize: function () {
              this.ipas = new IPAs( null, { view: this });
              //Create a friends collection when the view is initialized.
              //Pass it a reference to this view to create a connection between the two
            },
            events: {
              "click #add-app":  "upload",
            },
            upload: function () {
              var friend_name = $('#filelabel').val();
              if (typeof friend_name === "undefined" || friend_name.length == 0){
                 alert("You must specify a name.");
                 return;
              }
              var friend_model = new IPA({ name: friend_name });
              //Add a new friend model to our friend collection
              this.ipas.add( friend_model );

              var oOutput = document.getElementById("output");
              var oData = new FormData(document.forms.namedItem("fileinfo"));

              oData.append("CustomField", "This is some extra data");

              var oReq = new XMLHttpRequest();
              oReq.open("POST", "/upload", true);
              oReq.onload = function(oEvent) {
                if (oReq.status == 200) {
                  friend_model.set({ plist_file: oReq.responseText });
                } else {
                  alert("Error uploading");
                }
              };
              // finally, send our data
              oReq.send(oData);
            },
            renderUpdate: function(model){
              $("#" + model.id +  "").removeClass("btn-warning");
              $("#" + model.id +  "").addClass("btn-success");
              $("#" + model.id +  "").attr("href", "itms-services://?action=download-manifest&url=" + model.get('plist_file'));
            },
            addIPALi: function (model) {
              //The parameter passed is a reference to the model that was added
              // <button class="btn btn-warning" href="#">Warning</button>
              $("#list").append("<a id=\"" + model.id + "\"class=\"btn btn-warning btn-large\" href=\"#\">" + model.get('name') + "</a><br/>");
              //Use .get to receive attributes of the model
            }
          });
          
          var appview = new AppView;
        })(jQuery);
      </script>
    </div>
  </body>
</html>