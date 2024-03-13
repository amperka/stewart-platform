#include <Multiservo.h>

constexpr uint16_t SERVO_MIN_PULSE_WIDTH[6] = { 544 - 34, 544 + 78, 544 + 20, 544 + 0, 544 - 44, 544 - 70 };
constexpr uint16_t SERVO_MIDDLE_PULSE_WIDTH[6] = { 1522 - 48, 1522 + 60, 1522 + 0, 1522 + 14, 1522 - 28, 1522 - 116 };
constexpr uint16_t SERVO_MAX_PULSE_WIDTH[6] = { 2500 - 84, 2500 + 0, 2500 - 20, 2500 - 30, 2500 - 64, 2500 - 102 };

constexpr uint8_t MULTI_SERVO_PIN[6] = { 0, 1, 2, 3, 4, 5 };

Multiservo multiservo[6];

float target_angle_degree[6] = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };

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
}

void loop() {
  if (Serial.available()) {
    if (Serial.read() == 0x6A && Serial.read() == 0x6A) {
      for (uint8_t i = 0; i < 6; i++) {
        target_angle_degree[i] = (float)Serial.parseInt() / 100.0;
        target_angle_degree[i] = i % 2 ? -1 * target_angle_degree[i] : target_angle_degree[i];
      }
    }
  }
  servosHandler();
}