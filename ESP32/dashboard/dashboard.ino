/* 
 * ENGG 183.3X & ENGG 113.02 & ENGG 181.3X Final Project: Self-Regulating Water Heater
 * 
 * Raphael Enrico D. Catapang
 * Andreas Josef C. Diaz
 * Marc Jefferson B. Obeles
 * Justin Gabrioel M. Sy
 */

#include <WiFi.h>
#include <WebServer.h>
#include <WiFiClientSecure.h>
#include <ArduinoJson.h>
#include "dashboard_webpage.h"

// Wi-Fi Credentials
const char* wifi_ssid = "";
const char* wifi_password = "";

// Web Server Object
WebServer server(80);

// XML
char XML[1028];
char buf[64];

// Firebase HTTP
const int    ssl_port      = 443;                               
const char*  firebase_host = "self-regulating-water-heater-default-rtdb.asia-southeast1.firebasedatabase.app";  
const String firebase_auth = "";                      
const String firebase_path = "/";
const String http_url      = firebase_path + ".json?auth=" + firebase_auth;

// Firebase HTTP (GET)
WiFiClientSecure client_get;

// Database Fields
float setting_water_temperature_setpoint;
float setting_k_p;
float setting_k_i;
float setting_k_d;
float current_water_temperature;
float current_ambient_temperature;

// JSON Document
#define JSON_DOCUMENT_CAPACITY 1024
StaticJsonDocument<JSON_DOCUMENT_CAPACITY> json_document;

unsigned long last_delay = 0;
bool first_download = false;
bool pause_upload_download = false;

void handleRoot()
{
  String HTML = main_page;
  server.send(200, "text/html", HTML);
}

void handleUpdateSettings() 
{
  pause_upload_download = true;
  
  deserializeJson(json_document, server.arg("plain"));

  setting_water_temperature_setpoint = json_document["water_temperature_setpoint"];
  setting_k_p = json_document["k_p"];
  setting_k_i = json_document["k_i"];
  setting_k_d = json_document["k_d"];

  Serial.println("RECEIVED " + String(setting_water_temperature_setpoint) + " | " + String(setting_k_p) + " | " + String(setting_k_i) + " | " + String(setting_k_d) + " END");

  upload_data();

  pause_upload_download = false;
}

void setup() 
{
  Serial.begin(9600);

  // LED
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, HIGH);

  // Wi-Fi
  WiFi.mode(WIFI_STA);

  WiFi.begin(wifi_ssid, wifi_password);

  Serial.print("Connecting...");
  while(WiFi.status() != WL_CONNECTED)
  {
    Serial.print(".");
    delay(100);
  }

  Serial.print("\nConnected to ");
  Serial.println((String) WiFi.SSID());
  Serial.print("[*] RSSI: ");
  Serial.println((String) WiFi.RSSI() + " dB");
  Serial.print("[*] ESP32 IP: ");
  Serial.println(WiFi.localIP());

  digitalWrite(LED_BUILTIN, LOW);

  // Firebase HTTP (GET)
  client_get.setInsecure();
  
  Serial.print("Connecting GET to ");
  Serial.print(firebase_host);
  Serial.println("...");

  if(!client_get.connect(firebase_host, ssl_port))
  {
    Serial.print("ERROR: GET connection to ");
    Serial.print(firebase_host);
    Serial.println(" failed");
    return;
  }
  
  client_get.println("GET " + http_url + " HTTP/1.1");
  client_get.println("Host: " + String(firebase_host));
  client_get.println("Accept: text/event-stream");
  client_get.println("Connection: close");
  client_get.println();

  // Web Server Handler
  server.on("/", handleRoot);

  server.on("/xml", SendXML);
  server.on("/update_settings", HTTP_PUT, handleUpdateSettings);

  server.begin();
  
  Serial.println("HTML server started");
  Serial.println();
}

void loop() 
{
  digitalWrite(LED_BUILTIN, (WiFi.status() != WL_CONNECTED) ? HIGH : LOW);
  
  // Web Server
  server.handleClient();

  if(pause_upload_download) return;

  // Firebase HTTP (GET) - Response Body Content
  while(client_get.available())
  {
    String response_body = client_get.readStringUntil('\r');

    Serial.print(response_body);

    DeserializationError error = deserializeJson(json_document, response_body.substring(response_body.indexOf('{')));

    if(!error) 
    {
      String path = json_document["path"];

      if(path == "/") // PATCH
      {
        if(json_document["data"].containsKey("Water Temperature Setpoint Setting"))
          setting_water_temperature_setpoint = json_document["data"]["Water Temperature Setpoint Setting"];
          
        if(json_document["data"].containsKey("K_p Setting"))
          setting_k_p = json_document["data"]["K_p Setting"];
          
        if(json_document["data"].containsKey("K_i Setting"))
          setting_k_i = json_document["data"]["K_i Setting"];
          
        if(json_document["data"].containsKey("K_d Setting"))
            setting_k_d = json_document["data"]["K_d Setting"];

        if(json_document["data"].containsKey("Current Water Temperature"))
          current_water_temperature = json_document["data"]["Current Water Temperature"];
          
        if(json_document["data"].containsKey("Current Ambient Temperature"))
          current_ambient_temperature = json_document["data"]["Current Ambient Temperature"];
        
        first_download = true;
      }
      else if(path == "/Water Temperature Setpoint Setting") // PUT
      {
        setting_water_temperature_setpoint = json_document["data"];
      }
      else if(path == "/K_p Setting") // PUT
      {
        setting_k_p = json_document["data"];
      }
      else if(path == "/K_i Setting") // PUT
      {
        setting_k_i = json_document["data"];
      }
      else if(path == "/K_d Setting") // PUT
      {
        setting_k_d = json_document["data"];
      }
      else if(path == "/Current Water Temperature") // PUT
      {
        current_water_temperature = json_document["data"];
      }
      else if(path == "/Current Ambient Temperature") // PUT
      {
        current_ambient_temperature = json_document["data"];
      }
    }
  }

  unsigned long current_time = millis();
  
  if(current_time - last_delay > 1000)
  {
    last_delay = current_time;

    if(!first_download) return;
    
    upload_data();
  }
}

void upload_data()
{
  // JSON Document
  json_document.clear();
  
  json_document["Water Temperature Setpoint Setting"] = setting_water_temperature_setpoint;
  json_document["K_p Setting"] = setting_k_p;
  json_document["K_i Setting"] = setting_k_i;
  json_document["K_d Setting"] = setting_k_d;

  String json_string;
  serializeJson(json_document, json_string);
  
  // Firebase HTTP (PATCH)
  WiFiClientSecure client_patch;
  
  client_patch.setInsecure();

  Serial.print("Connecting PATCH to ");
  Serial.print(firebase_host);
  Serial.println("...");

  if(!client_patch.connect(firebase_host, ssl_port))
  {
    Serial.print("ERROR: PATCH connection to ");
    Serial.print(firebase_host);
    Serial.println(" failed");
    return;
  }

  client_patch.println("PATCH " + http_url + " HTTP/1.1");
  client_patch.println("Host: " + String(firebase_host));
  client_patch.println("Connection: close");
  client_patch.println("Content-Length: " + String(json_string.length()));
  client_patch.println();
  client_patch.println(json_string);

  // Firebase HTTP (PATCH) - Server Response
  while(client_patch.connected())
  {
    String response = client_patch.readStringUntil('\n');
    Serial.println(response);
    
    if(response == "\r") break;
  }

  // Firebase HTTP (PATCH) - Response Body Content
  while(client_patch.available())
  {
    char response_body = client_patch.read();
    Serial.print(response_body);
  }

  Serial.println("\n");

  client_patch.stop();
}

void SendXML()
{
  if(!first_download || pause_upload_download) return;
  
  strcpy(XML, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
  strcat(XML, "<sensorNode>\n");

  sprintf(buf, "\t<a>%.1f</a>\n", setting_water_temperature_setpoint);
  strcat(XML, buf);

  sprintf(buf, "\t<b>%.3f</b>\n", setting_k_p);
  strcat(XML, buf);

  sprintf(buf, "\t<c>%.3f</c>\n", setting_k_i);
  strcat(XML, buf);

  sprintf(buf, "\t<d>%.3f</d>\n", setting_k_d);
  strcat(XML, buf);

  sprintf(buf, "\t<e>%.1f</e>\n", current_water_temperature);
  strcat(XML, buf);

  sprintf(buf, "\t<f>%.1f</f>\n", current_ambient_temperature);
  strcat(XML, buf);

  strcat(XML, "</sensorNode>\n");

  Serial.println(XML);

  server.send(200, "text/xml", XML);
}
