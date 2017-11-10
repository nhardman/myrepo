<script>
var http = require("https")

var options = {
  "method": "POST",
  "hostname": "api.ibm.com",
  "port": null,
  "path": "/api/v1/namespaces/%7Bnamespace%7D/actions/%7BactionName%7D?blocking=SOME_STRING_VALUE",
  "headers": {
    "accept": "application/json",
    "content-type": "application/json"
  }
};

var req = http.request(options, function (res) {
  var chunks = [];

  res.on("data", function (chunk) {
    chunks.push(chunk);
  });

  res.on("end", function () {
    var body = Buffer.concat(chunks);
    console.log(body.toString());
  });
});

req.end();
</script>

test README file 5.0.0

[![Release](ReleaseButton.png)](https://openwhisk.eu-gb.bluemix.net/api/v1/namespaces/nhardman%40uk.ibm.com_dev/actions/release?message="wooHoo")


