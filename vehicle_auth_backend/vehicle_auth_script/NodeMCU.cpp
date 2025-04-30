#include <ESP8266WiFi.h>
#define IR D7
WiFiServer server(80);
#include <Servo.h>

Servo myservo;  // create servo object to control a servo
// twelve servo objects can be created on most boards

int pos = 0; 


void setup()
{
  Serial.begin(9600);
//  WiFi.begin("OnePlus_ONEPLUS_A6000_co_aptmfl", "isha2003");
   //WiFi.begin("TP_Link_1FD4", "53066107");
  // WiFi.begin("Krishna", "qwerty1234");
  // WiFi.begin("Ujjwal Patil", "12345678");
  WiFi.begin("Redmi Note 11 Pro+", "12345678");


  //WiFi.begin("dypcoe", "dypcoengg");
  while (WiFi.status() != WL_CONNECTED)
  { delay(1000);
    Serial.println(".");
  }
  Serial.println();
  Serial.println("NodeMCU is Connected");
  Serial.println(WiFi.localIP());
  server.begin();
  pinMode(IR, INPUT);
  myservo.attach(16);
  myservo.write(pos);
}

void loop()
{
  WiFiClient client = server.available();
  client.println("HTTP/1.1 200 OK");
  client.println("Content-Type: text/html");
  client.println("");
  client.println("<!DOCTYPE HTML>");
  client.println("<html>");
  client.println("<center>");
  client.println("<h1 style=background-color:DodgerBlue;>Vehicle Status</h1>");
  
  if (digitalRead(IR) == 0) {
    client.println("<p><strong>Vehicle Detected</strong></p>");
    delay(1000);
    Serial.println("receiving the request");
    String request = client.readStringUntil('\r');
    client.flush();
   Serial.println(request);
   
//    Serial.println("Exit");
//    Serial.println(WiFi.localIP());
  
    if (request.indexOf("/P") != -1){
      Serial.println("Request contains /P");
      for (pos = 0; pos <= 180; pos += 1) { // goes from 0 degrees to 180 degrees
      // in steps of 1 degree
      myservo.write(pos);               // tell servo to go to position in variable 'pos'
      delay(15); 
      // waits 15ms for the servo to reach the position
      }
      while(digitalRead(IR)==0){
        Serial.println("Vehicle There");
        delay(2000);
      }
      delay(3000);

  
      for (pos = 180; pos >= 0; pos -= 1) { // goes from 180 degrees to 0 degrees
      myservo.write(pos);              // tell servo to go to position in variable 'pos'
      delay(15);                       // waits 15ms for the servo to reach the position
     }
       Serial.println("Rotation Complete");
      }
    }
  else {
    client.println("<p><strong>Vehicle Not Detected</strong></p>");
  }
  client.println("</center>");
  client.println("</html>");
//  String request = client.readStringUntil('\r');
//  client.flush();
//  Serial.println(request);
// 
//  Serial.println("Exit");
//  Serial.println(WiFi.localIP());

//  if (request.indexOf("/P") != -1){
//    for (pos = 0; pos <= 180; pos += 1) { // goes from 0 degrees to 180 degrees
//    // in steps of 1 degree
//    myservo.write(pos);              // tell servo to go to position in variable 'pos'
//    delay(15); 
//    // waits 15ms for the servo to reach the position
//    }
//    delay(3000);
//
//    for (pos = 180; pos >= 0; pos -= 1) { // goes from 180 degrees to 0 degrees
//    myservo.write(pos);              // tell servo to go to position in variable 'pos'
//    delay(15);                       // waits 15ms for the servo to reach the position
//    
//   }
//   
//    }


}