#include <SPI.h>
// 1 MHz, you can increase or decrease but it will cause glitches. Safest is 1 MHz
static const int spiClk = 1000000; 
uint16_t test;

void setup()
{
  Serial.begin(9600);
  SPI.begin();
  pinMode(SS, OUTPUT);
}

void loop()
{
  //Send "BEEF" to FPGA, it should show up on the 7Seg
  test = SendData(0xbeef);
  // Check if the value sent from FPGA is still the same when in serial
  Serial.println(test, HEX);
  delay(5000);
}

uint16_t SendData(uint16_t data)
{
  SPI.beginTransaction(SPISettings(spiClk, MSBFIRST, SPI_MODE0));
  digitalWrite(SS, LOW);
  uint16_t read = SPI.transfer16(data);
  digitalWrite(SS, HIGH);
  SPI.endTransaction();
  return read;
}