#include <Multiservo.h>
#include <TouchScreen.h>

constexpr uint8_t YP = A2;
constexpr uint8_t XM = A3;
constexpr uint8_t YM = 8;
constexpr uint8_t XP = 9;

constexpr float X_MIN = 75.0;
constexpr float X_MAX = 975.0;
constexpr float Y_MIN = 120.0;
constexpr float Y_MAX = 921.0;

constexpr float TOUCHSCREEN_WIDTH = 225.0;
constexpr float TOUCHSCREEN_HEIGHT = 171.5;

constexpr float BALL_BREAKTHROUGH = 50.0;

constexpr uint16_t SERVO_MIN_PULSE_WIDTH[6] = { 544 - 34, 544 + 78, 544 + 20, 544 + 0, 544 - 44, 544 - 70 };
constexpr uint16_t SERVO_MIDDLE_PULSE_WIDTH[6] = { 1522 - 48, 1522 + 60, 1522 + 0, 1522 + 14, 1522 - 28, 1522 - 116 };
constexpr uint16_t SERVO_MAX_PULSE_WIDTH[6] = { 2500 - 84, 2500 + 0, 2500 - 20, 2500 - 30, 2500 - 64, 2500 - 102 };

constexpr uint8_t MULTI_SERVO_PIN[6] = { 0, 1, 2, 3, 4, 5 };

Multiservo multiservo[6];
TouchScreen ts = TouchScreen(XP, YP, XM, YM, 0);

float target_angle_degree[6] = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };

union coordinate {
  uint8_t b[2];
  int16_t i;
};

coordinate x_valid, y_valid;

void resetToZero() {
  for (uint8_t i = 0; i < 6; i++)
    multiservo[i].writeMicroseconds(SERVO_MIDDLE_PULSE_WIDTH[i]);
}

void servosHandler() {
  for (uint8_t i = 0; i < 6; i++) {
    uint16_t pulse = 0;
    if (target_angle_degree[i] >= 0)
      pulse = map(target_angle_degree[i], 0.0, 90.0, SERVO_MIDDLE_PULSE_WIDTH[i], SERVO_MAX_PULSE_WIDTH[i]);
    else if (target_angle_degree[i] < 0)
      pulse = map(target_angle_degree[i], -90.0, 0.0, SERVO_MIN_PULSE_WIDTH[i], SERVO_MIDDLE_PULSE_WIDTH[i]);
    multiservo[i].writeMicroseconds(pulse);
  }
}

void setup() {
  Serial.begin(115200);

  for (uint8_t i = 0; i < 6; i++)
    multiservo[i].attach(MULTI_SERVO_PIN[i]);

  resetToZero();
  x_valid.i = 0;
  y_valid.i = 0;  
}

void loop() {
  if (Serial.available() >= 20) {
    if (Serial.read() == 0x6A && Serial.read() == 0x6A) {
      for (uint8_t i = 0; i < 6; i++) {
        target_angle_degree[i] = (float)Serial.parseInt() / 100.0;
        target_angle_degree[i] = i % 2 ? -1 * target_angle_degree[i] : target_angle_degree[i];
      }
    }
  }
  servosHandler();

  TSPoint p = ts.getPoint();
  float x = map(p.x, X_MIN, X_MAX, 0, TOUCHSCREEN_WIDTH);
  float y = map(p.y, Y_MIN, Y_MAX, 0, TOUCHSCREEN_HEIGHT);
  x = constrain(x, 0, TOUCHSCREEN_WIDTH);
  y = constrain(y, 0, TOUCHSCREEN_HEIGHT);

  // Смещаем систему координат в центр
  x = x - TOUCHSCREEN_WIDTH / 2;
  y = y - TOUCHSCREEN_HEIGHT / 2;  

  // Не отправляем одинаковые координаты
  if (x == x_valid.i && y == y_valid.i)
    return;  
  // Если нет шарика то координаты примерно (-112, 73), отсеиваем их
  if (x < -110.0) 
    return;
  // Отсеиваем резкий проскок шара
  if ((abs(x - x_valid.i) >= BALL_BREAKTHROUGH) || (abs(y - y_valid.i) >= BALL_BREAKTHROUGH))
    return;

  x_valid.i = x;
  y_valid.i = y;

  Serial.write(0x6B);
  Serial.write(0x6B);
  Serial.write(x_valid.b, 2);
  Serial.write(y_valid.b, 2);
  Serial.flush();

}