# gem install gmail - https://github.com/dcparker/ruby-gmail
require 'gmail'
require 'sinatra'
require 'base64'
Net::IMAP::debug = true

$gmail_login = ARGV[0]
$gmail_password = ARGV[1]
$gmail = Gmail.new $gmail_login, $gmail_password
$last_email_uid = nil

def fetch_last_email
  begin
    email = $gmail.inbox.emails.last
    puts 'test'
  rescue # error handling when connection is lost
    begin
      puts 'logout'
      $gmail.logout
    ensure
      $gmail = Gmail.new $gmail_login, $gmail_password
      email = $gmail.inbox.emails.last    
    end
  end
  
  puts 'emailid is '
  puts email.uid

  if email.uid == $last_email_uid
    return
  end
   
  $last_email_uid = email.uid
  $sender = Mail::Encodings.value_decode email.sender.first.name
  $subject = Mail::Encodings.value_decode email.subject
  $received_at = email.envelope.date
  $image = nil
  if email.attachments.size > 0 
    $image = email.attachments.first.decoded
  end
end

set :port, 1212
set :bind, '0.0.0.0'

get '/email' do
  fetch_last_email
  
  <<STRING
<html>
  <head>
  <!-- Latest compiled and minified CSS -->
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">
<style>
body {font-family: sans}
p {padding-top: 0; paddding-bottom: 0; margin-top: 0; margin-bottom: 0;}
</style>
</head>
  <body>
  <div class="jumbotron">
    <h1 style="font-size: 1200%;">#{$subject}</h1>
  </div>
    <p  style="font-size: 120%"><b>#{$sender}</b>, #{$received_at}</p>
    <img src="data:image/jpg;base64,#{Base64.encode64($image) if $image}" style="width:100%;">

    <script>
        function ajaxGetRequest(url, callback) { // https://gist.github.com/iwek/5599777
          var xhr;

          if(typeof XMLHttpRequest !== 'undefined') xhr = new XMLHttpRequest();
          else {
            var versions = ["MSXML2.XmlHttp.5.0", 
                "MSXML2.XmlHttp.4.0",
                "MSXML2.XmlHttp.3.0", 
                "MSXML2.XmlHttp.2.0",
                "Microsoft.XmlHttp"]

            for(var i = 0, len = versions.length; i < len; i++) {
            try {
              xhr = new ActiveXObject(versions[i]);
              break;
            }
              catch(e){}
            } // end for
          }

          xhr.onreadystatechange = ensureReadiness;

          function ensureReadiness() {
            if(xhr.readyState < 4) {
              return;
            }

            if(xhr.status !== 200) {
              return;
            }

            // all is well	
            if(xhr.readyState === 4) {
              callback(xhr);
            }			
          }

          xhr.open('GET', url, true);
          xhr.send('');
        }

        lastEmailChangedCheck = function(){
          ajaxGetRequest('should_we_reload?rendered_email_uid=#{$last_email_uid}', function(xhr) {	
            if(xhr.responseText == 'yes')
                location.reload();
          });
          setTimeout(lastEmailChangedCheck, 10000);
        }

        lastEmailChangedCheck();

    </script>
  </body>
</html>
STRING
end

get '/should_we_reload' do
  fetch_last_email
  (params['rendered_email_uid'].to_i == $last_email_uid) ? 'no' : 'yes'
end
