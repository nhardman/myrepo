test README file 5.0.0

<h2>Some raw html</h2>

<form id="my_form">
  <!-- More HTML -->
  <a href="javascript:{}" onclick="document.getElementById('my_form').submit(); return false;">submit</a>
</form>

<form name="myform" action="handle-data.php" method="post">
  <label for="query">Search:</label>
  <input type="text" name="query" id="query"/>
  <button>Search</button>
</form>

<script>
var button = document.querySelector('form[name="myform"] > button');
button.addEventListener(function() {
  document.querySelector("form[name="myform"]").submit();
});
</script>

[![Release](ReleaseButton.png)](https://openwhisk.eu-gb.bluemix.net/api/v1/namespaces/nhardman%40uk.ibm.com_dev/actions/release?message="wooHoo")


