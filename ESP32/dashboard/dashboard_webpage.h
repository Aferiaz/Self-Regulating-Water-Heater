const char main_page[] PROGMEM = R"=====(
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Self-Regulating Water Heater Control Dashboard</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      background-color: #f4f4f4;
      margin: 0;
      padding: 0;
    }

    .dashboard {
      width: 80%;
      margin: 20px auto;
      background-color: #fff;
      padding: 20px;
      box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
      border-radius: 5px;
    }

    .current-value {
      font-size: 2em;
      margin-bottom: 20px;
    }

    .input-group {
      display: flex;
      align-items: center;
      margin-bottom: 10px;
    }

    label {
      flex: 1;
      margin-right: 10px;
    }

    input {
      flex: 2;
      padding: 8px;
      font-size: 1em;
    }

    button {
      background-color: #4caf50;
      color: #fff;
      border: none;
      padding: 10px 20px;
      cursor: pointer;
      border-radius: 3px;
      font-size: 1em;
    }
  </style>
  
  <script>
    let pause_download = false;
    
    function GetXMLResponse()
    {
      if(!pause_download)
      {
        var xmlDoc = new XMLHttpRequest();
        xmlDoc.onreadystatechange = function() 
        {
          if (this.readyState == 4 && this.status == 200) 
          {
            if (this.responseXML != null)
            {
              document.getElementById("setting_water_temperature_setpoint").innerHTML = this.responseXML.getElementsByTagName("a")[0].childNodes[0].nodeValue;
              document.getElementById("setting_k_p").innerHTML = this.responseXML.getElementsByTagName("b")[0].childNodes[0].nodeValue;
              document.getElementById("setting_k_i").innerHTML = this.responseXML.getElementsByTagName("c")[0].childNodes[0].nodeValue;
              document.getElementById("setting_k_d").innerHTML = this.responseXML.getElementsByTagName("d")[0].childNodes[0].nodeValue;
              document.getElementById("current_water_temperature").innerHTML = this.responseXML.getElementsByTagName("e")[0].childNodes[0].nodeValue;
              document.getElementById("current_ambient_temperature").innerHTML = this.responseXML.getElementsByTagName("f")[0].childNodes[0].nodeValue;
            }
          }
        }
        xmlDoc.open("GET", "xml", true);
        xmlDoc.send(null);
      }
      setTimeout("GetXMLResponse()", 2000);
    }
  </script>
  
</head>

<body onload="GetXMLResponse()">

  <div class="dashboard">
    <div class="current-value" id="water_temperature">Current Water Temperature: <span id="current_water_temperature"></span>°C</div>

    <div class="current-value" id="ambient_temperature">Current Ambient Temperature: <span id="current_ambient_temperature"></span>°C</div>

    <div class="input-group">
      <label for="water_temperature_setpoint">Water Temperature Setpoint (<span id="setting_water_temperature_setpoint"></span>°C):</label>
      <input type="number" id="water_temperature_setpoint" step="0.1" min="27.5" max="100.0" placeholder="Enter Temperature Setpoint (°C)">
    </div>

    <div class="input-group">
      <label for="k_p">K_p (<span id="setting_k_p"></span>):</label>
      <input type="number" id="k_p" step="0.001" min="0" max="127.992" placeholder="Enter K_p">
    </div>

    <div class="input-group">
      <label for="k_i">K_i (<span id="setting_k_i"></span>):</label>
      <input type="number" id="k_i" step="0.001" min="0" max="127.992" placeholder="Enter K_i">
    </div>

    <div class="input-group">
      <label for="k_d">K_d (<span id="setting_k_d"></span>):</label>
      <input type="number" id="k_d" step="0.001" min="0" max="127.992" placeholder="Enter K_d">
    </div>

    <button onclick="updateSettings()">Update Settings</button>
  </div>

  <script>
    function isFloatWithinStep(value, step) {
      const stringValue = value.toString();
      const decimalPart = stringValue.includes('.') ? stringValue.split('.')[1] : '';
      const stepDecimalPart = step.toString().split('.')[1] || '';
      return decimalPart.length <= stepDecimalPart.length;
    }

    function updateSettings() {
      pause_download = true;

      const settings = {
        water_temperature_setpoint: document.getElementById('setting_water_temperature_setpoint').innerText,
        k_p: document.getElementById('setting_k_p').innerText,
        k_i: document.getElementById('setting_k_i').innerText,
        k_d: document.getElementById('setting_k_d').innerText
      };
      
      const waterTemperatureSetpointInput = document.getElementById('water_temperature_setpoint');
      const kpInput = document.getElementById('k_p');
      const kiInput = document.getElementById('k_i');
      const kdInput = document.getElementById('k_d');

      if ((waterTemperatureSetpointInput.value < 27.5 || waterTemperatureSetpointInput.value > 100.0 || !isFloatWithinStep(waterTemperatureSetpointInput.value, 0.1)) && waterTemperatureSetpointInput.value != "") {
        alert(`ERROR: Water temperature setpoint must be between 27.5°C and 100.0°C with at most 1 decimal precision`);
        return;
      }

      if ((kpInput.value < 0 || kpInput.value > 127.992 || !isFloatWithinStep(kpInput.value, 0.001)) && kpInput.value != "") {
        alert(`ERROR: K_p must be between 0 and 127.992 with at most 3 decimal precision`);
        return;
      }

      if ((kiInput.value < 0 || kiInput.value > 127.992 || !isFloatWithinStep(kiInput.value, 0.001)) && kiInput.value != "") {
        alert(`ERROR: K_i must be between 0 and 127.992 with at most 3 decimal precision`);
        return;
      }

      if ((kdInput.value < 0 || kdInput.value > 127.992 || !isFloatWithinStep(kdInput.value, 0.001)) && kdInput.value != "") {
        alert(`ERROR: K_d must be between 0 and 127.992 with at most 3 decimal precision`);
        return;
      }

      if (waterTemperatureSetpointInput.value != "")
      {
        settings.water_temperature_setpoint = parseFloat(waterTemperatureSetpointInput.value);
      }
      if (kpInput.value != "")
      {
        settings.k_p = parseFloat(kpInput.value);
      }
      if (kiInput.value != "")
      {
        settings.k_i = parseFloat(kiInput.value);
      }
      if (kdInput.value != "")
      {
        settings.k_d = parseFloat(kdInput.value);
      }

      const xhttp = new XMLHttpRequest();
      xhttp.open("PUT", "/update_settings", true);
  
      xhttp.setRequestHeader("Content-type", "application/json");
  
      const settingsJSON = JSON.stringify(settings);
      
      xhttp.send(settingsJSON);

      pause_download = false;
    }
  </script>

</body>
</html>
)=====";
