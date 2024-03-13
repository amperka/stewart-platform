import controlP5.*;
import peasy.*;
import processing.serial.*; 

PeasyCam camera;
Platform platform;
ControlP5 cp5;

Serial serial;

float pos_x = 0, pos_y = 0, pos_z = 0, rot_x = 0, rot_y = 0, rot_z = 0;
float[] alpha;
PVector T, R;

void setup() {
  //size(1920, 1080, P3D);
  fullScreen(P3D);
  frameRate(60);

  cp5 = new ControlP5(this);
  PFont pfont = createFont("Arial", 16, true);
  ControlFont font = new ControlFont(pfont, 16);

  camera = new PeasyCam(this, 0, 0, 0, 500);
  camera.setRotations(0.0, 0, 0);

  platform = new Platform();
  platform.applyTranslationAndRotation(new PVector(), new PVector());

  printArray(Serial.list());
  serial = new Serial(this, Serial.list()[0], 115200);

  // Add slider bars
  cp5.addSlider("pos_x")
      .setPosition(20, 20)
      .setLabel("Translation X, mm")
      .setFont(font)
      .setSize(200, 40)
      .setRange(-100, 100);
  cp5.addSlider("pos_y")
      .setPosition(20, 70)
      .setLabel("Translation Y, mm")
      .setFont(font)
      .setSize(200, 40)
      .setRange(-100, 100);
  cp5.addSlider("pos_z")
      .setPosition(20, 120)
      .setLabel("Translation Z, mm")
      .setFont(font)
      .setSize(200, 40)
      .setRange(-100, 100);
  cp5.addSlider("rot_x")
      .setPosition(20, 170)
      .setLabel("Rotation X, rad")
      .setFont(font)
      .setSize(200, 40)
      .setRange(-PI, PI);
  cp5.addSlider("rot_y")
      .setPosition(20, 220)
      .setLabel("Rotation Y, rad")
      .setFont(font)
      .setSize(200, 40)
      .setRange(-PI, PI);
  cp5.addSlider("rot_z")
      .setPosition(20, 270)
      .setLabel("Rotation Z, rad")
      .setFont(font)
      .setSize(200, 40)
      .setRange(-PI, PI);

  // Add buttons
  cp5.addButton("Reset")
      .setPosition(20, 320)
      .setFont(font)
      .setSize(100, 40)
      .activateBy(ControlP5.PRESS);

  // Text fields
  cp5.addTextarea("alpha_str_0")
      .setPosition(20, 370)
      .setSize(200, 40)
      .setFont(font);
  cp5.addTextarea("alpha_str_1")
      .setPosition(20, 390)
      .setSize(200, 40)
      .setFont(font);
  cp5.addTextarea("alpha_str_2")
      .setPosition(20, 410)
      .setSize(200, 40)
      .setFont(font);
  cp5.addTextarea("alpha_str_3")
      .setPosition(20, 430)
      .setSize(200, 40)
      .setFont(font);
  cp5.addTextarea("alpha_str_4")
      .setPosition(20, 450)
      .setSize(200, 40)
      .setFont(font);
  cp5.addTextarea("alpha_str_5")
      .setPosition(20, 470)
      .setSize(200, 40)
      .setFont(font);
  cp5.addTextarea("platform_roll")
      .setPosition(20, 510)
      .setSize(200, 40)
      .setFont(font);
  cp5.addTextarea("platform_pitch")
      .setPosition(20, 530)
      .setSize(200, 40)
      .setFont(font);
  cp5.addTextarea("platform_yaw")
      .setPosition(20, 550)
      .setSize(200, 40)
      .setFont(font);

  cp5.setAutoDraw(false);
  camera.setActive(true);
}

void sendAnglesToSerial() {
  byte[] cmd_bytes = { 0x6A, 0x6A };
  serial.write(cmd_bytes);
  
  String data = (int)(degrees(alpha[0]) * 100) + ","
              + (int)(degrees(alpha[1]) * 100) + ","
              + (int)(degrees(alpha[2]) * 100) + ","
              + (int)(degrees(alpha[3]) * 100) + ","
              + (int)(degrees(alpha[4]) * 100) + ","
              + (int)(degrees(alpha[5]) * 100) + "\n";
   serial.write(data);
}

void draw() {
  background(200);

  T = platform.getTranslation();
  T.x = pos_x;
  T.y = pos_y;
  T.z = pos_z;
  R = platform.getRotation();
  R.x = rot_x;
  R.y = rot_y;
  R.z = rot_z;
  platform.applyTranslationAndRotation(T, R);
  platform.draw();

  alpha = platform.getAlphaAngles();
  sendAnglesToSerial();

  cp5.get(Textarea.class, "alpha_str_0")
      .setText(String.format("Alpha 0, deg: %.2f", degrees(alpha[0])));
  cp5.get(Textarea.class, "alpha_str_1")
      .setText(String.format("Alpha 1, deg: %.2f", degrees(alpha[1])));
  cp5.get(Textarea.class, "alpha_str_2")
      .setText(String.format("Alpha 2, deg: %.2f", degrees(alpha[2])));
  cp5.get(Textarea.class, "alpha_str_3")
      .setText(String.format("Alpha 3, deg: %.2f", degrees(alpha[3])));
  cp5.get(Textarea.class, "alpha_str_4")
      .setText(String.format("Alpha 4, deg: %.2f", degrees(alpha[4])));
  cp5.get(Textarea.class, "alpha_str_5")
      .setText(String.format("Alpha 5, deg: %.2f", degrees(alpha[5])));

  cp5.get(Textarea.class, "platform_roll")
      .setText(String.format("Roll, deg: %.2f", degrees(R.x)));
  cp5.get(Textarea.class, "platform_pitch")
      .setText(String.format("Pitch, deg: %.2f", degrees(R.y)));
  cp5.get(Textarea.class, "platform_yaw")
      .setText(String.format("Yaw, deg: %.2f", degrees(R.z)));

  hint(DISABLE_DEPTH_TEST);
  camera.beginHUD();
  cp5.draw();
  camera.endHUD();
  hint(ENABLE_DEPTH_TEST);
}

void controlEvent(ControlEvent theEvent) {
  camera.setActive(false);
}

void mouseReleased() {
  camera.setActive(true);
}

public void Reset() {
  pos_x = 0;
  pos_y = 0;
  pos_z = 0;
  rot_x = 0;
  rot_y = 0;
  rot_z = 0;
  cp5.getController("pos_x").setValue(pos_x);
  cp5.getController("pos_y").setValue(pos_y);
  cp5.getController("pos_z").setValue(pos_z);
  cp5.getController("rot_x").setValue(rot_x);
  cp5.getController("rot_y").setValue(rot_y);
  cp5.getController("rot_z").setValue(rot_z);
}
