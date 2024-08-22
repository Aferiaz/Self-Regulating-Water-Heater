/* 
 * ENGG 183.3X & ENGG 113.02 & ENGG 181.3X Final Project: Self-Regulating Water Heater
 * 
 * Raphael Enrico D. Catapang
 * Andreas Josef C. Diaz
 * Marc Jefferson B. Obeles
 * Justin Gabrioel M. Sy
 */

#include <SPI.h>
#include <Wire.h> 
#include <LiquidCrystal_I2C.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <ArduinoJson.h>
#include "Adafruit_MCP9808.h"

// Wi-Fi Credentials
const char* wifi_ssid = "";
const char* wifi_password = "";

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

// SPI Commands
#define COMMAND_SETPOINT      0
#define COMMAND_PROPORTIONAL  1
#define COMMAND_INTEGRAL      2
#define COMMAND_DERIVATIVE    3

static const int spiClk = 1000000; // 10 MHz

// GPIO Objects
LiquidCrystal_I2C lcd(0x27,20,2);
Adafruit_MCP9808 airtempsensor = Adafruit_MCP9808();

unsigned long last_delay = 0;
bool first_download = false;

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

  // SPI
  SPI.begin();
  pinMode(SS, OUTPUT);

  // LCD
  lcd.init();
  lcd.backlight();

  // Air Temperature Sensor
  airtempsensor.setResolution(2);
  
  if(!airtempsensor.begin(0x18)) 
  {
    Serial.println("ERROR: Could not find MCP9808");
    while(1);
  }
}

void loop() 
{
  digitalWrite(LED_BUILTIN, (WiFi.status() != WL_CONNECTED) ? HIGH : LOW);
  
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
    }
  }

  unsigned long current_time = millis();
  uint16_t test;
  
  if(current_time - last_delay > 1000)
  {
    last_delay = current_time;

    if(!first_download) return;
    
    current_water_temperature = convertBitsToFloat(SendData(COMMAND_SETPOINT, setting_water_temperature_setpoint));
    current_ambient_temperature = getAirTemp();

    convertBitsToFloat(SendData(COMMAND_PROPORTIONAL, setting_k_p));
    convertBitsToFloat(SendData(COMMAND_INTEGRAL, setting_k_i));
    convertBitsToFloat(SendData(COMMAND_DERIVATIVE, setting_k_d));
    
    showLCD(current_water_temperature, setting_water_temperature_setpoint);

    upload_data();
  }
}

void upload_data()
{
  // JSON Document
  json_document.clear();
  
  json_document["Current Ambient Temperature"] = current_ambient_temperature;
  json_document["Current Water Temperature"] = current_water_temperature;

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

float getAirTemp()
{
  airtempsensor.wake();
  float value = airtempsensor.readTempC();
  airtempsensor.shutdown_wake(1);
  return value;
}

void showLCD(float value1, float value2)
{
  lcd.clear();
  lcd.setCursor(0,0);
  lcd.print("M : ");
  lcd.print(value1,1);
  lcd.print((char)223);
  lcd.print("C");

  lcd.setCursor(0,1);
  lcd.print("SP: ");
  lcd.print(value2,1);
  lcd.print((char)223);
  lcd.print("C");
}

uint16_t SendData(int command, float value)
{
  uint16_t data = convertFloattoBits(value);
  uint16_t masked_data=0x0000;
  
  if(command == COMMAND_SETPOINT) // Setpoint
    masked_data = data | 0b0000000000000000;
  else if (command == COMMAND_PROPORTIONAL) // Proportional
    masked_data = data | 0b0100000000000000;
  else if (command == COMMAND_INTEGRAL) // Integral
    masked_data = data | 0b1000000000000000;
  else if (command == COMMAND_DERIVATIVE) // Derivative
    masked_data = data | 0b1100000000000000;
    
  SPI.beginTransaction(SPISettings(spiClk, MSBFIRST, SPI_MODE0));
  digitalWrite(SS, LOW);
  uint16_t read = SPI.transfer16(masked_data);
  digitalWrite(SS, HIGH);
  SPI.endTransaction(); 
  return read;
}

float convertBitsToFloat(uint16_t extractedBits) 
{
  float floatValue = (extractedBits * 0.0625);
  return floatValue;
}

uint16_t convertFloattoBits(float floatData) 
{
  uint16_t bitValue = (floatData/0.0078125);
  return bitValue;
}
