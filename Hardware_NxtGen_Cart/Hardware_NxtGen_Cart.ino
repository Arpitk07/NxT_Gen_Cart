#include <WiFi.h>
#include <Firebase_ESP_Client.h>

/* WiFi Credentials */
#define WIFI_SSID "Arpit's Oneplus"
#define WIFI_PASSWORD "1234567890"

/* Firebase Credentials */
#define API_KEY "AIzaSyBHrB2K25WZaI6gDU8oCTWqzn-bfi3JoN0"
#define DATABASE_URL "https://nxtgen-cart-default-rtdb.firebaseio.com"

/* Firebase objects */
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

/* Timer */
unsigned long sendDataPrevMillis = 0;
int counter = 0;

void setup()
{
  Serial.begin(115200);

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");

  while (WiFi.status() != WL_CONNECTED)
  {
    Serial.print(".");
    delay(500);
  }

  Serial.println();
  Serial.println("WiFi Connected");

  /* Firebase setup */
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  Serial.println("Firebase Ready");
}

void loop()
{
  if (Firebase.ready() && (millis() - sendDataPrevMillis > 5000))
  {
    sendDataPrevMillis = millis();

    counter++;

    FirebaseJson json;

    json.set("product_name", "Milk");
    json.set("price", random(10, 50));
    json.set("quantity", 1);
    json.set("expiry_date", "2026-02-10");
    json.set("scan_count", counter);

    if (Firebase.RTDB.setJSON(&fbdo, "/trolleys/T1/cart_items/item1", &json))
    {
      Serial.println("Data written to Firebase");
    }
    else
    {
      Serial.println("Write failed");
      Serial.println(fbdo.errorReason());
    }
  }
}