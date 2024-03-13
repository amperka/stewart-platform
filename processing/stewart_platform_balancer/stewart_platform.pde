class Platform {
  private final float BASE_ANGLES[] = {-50, -70, -170, -190, -290, -310};
  private final float PLATFORM_ANGLES[] = {-54, -66, -174, -186, -294, -306};
  private final float BETA[] = {PI / 6, -5 * PI / 6, -PI / 2, PI / 2, 5 * PI / 6, -PI / 6};
  private final float BASE_RADIUS = 76;
  private final float PLATFORM_RADIUS = 60;
  private final float HORN_LENGTH = 40;
  private final float ROD_LENGTH = 130;
  private final float INITIAL_HEIGHT = 120.28183632;

  private PVector[] b, p, q, l, a;
  private PVector T, R, initial_height;
  private float[] alpha;

  public Platform() {
    T = new PVector();
    R = new PVector();
    b = new PVector[6];
    p = new PVector[6];
    q = new PVector[6];
    l = new PVector[6];
    a = new PVector[6];
    alpha = new float[6];

    initial_height = new PVector(0, 0, INITIAL_HEIGHT);

    for (int i = 0; i < 6; i++) {
      float xb = BASE_RADIUS * cos(radians(BASE_ANGLES[i]));
      float yb = BASE_RADIUS * sin(radians(BASE_ANGLES[i]));
      b[i] = new PVector(xb, yb, 0);

      float px = PLATFORM_RADIUS * cos(radians(PLATFORM_ANGLES[i]));
      float py = PLATFORM_RADIUS * sin(radians(PLATFORM_ANGLES[i]));
      p[i] = new PVector(px, py, 0);

      q[i] = new PVector(0, 0, 0);
      l[i] = new PVector(0, 0, 0);
      a[i] = new PVector(0, 0, 0);
    }
    calculateVectorQL();
  }

  public float[] getAlphaAngles() {
    return alpha;
  }

  public PVector getTranslation() {
    return T;
  }

  public PVector getRotation() {
    return R;
  }

  public void applyTranslationAndRotation(
      PVector translation, PVector rotation) {
    R.set(rotation);
    T.set(translation);
    calculateVectorQL();
    calculateAngleAlpha();
  }

  private void calculateVectorQL() {
    for (int i = 0; i < 6; i++) {
      // Apply rotation
      q[i].x = cos(R.z) * cos(R.y) * p[i].x
          + (-sin(R.z) * cos(R.x) + cos(R.z) * sin(R.y) * sin(R.x)) * p[i].y
          + (sin(R.z) * sin(R.x) + cos(R.z) * sin(R.y) * cos(R.x)) * p[i].z;

      q[i].y = sin(R.z) * cos(R.y) * p[i].x
          + (cos(R.z) * cos(R.x) + sin(R.z) * sin(R.y) * sin(R.x)) * p[i].y
          + (-cos(R.z) * sin(R.x) + sin(R.z) * sin(R.y) * cos(R.x)) * p[i].z;

      q[i].z = -sin(R.y) * p[i].x + cos(R.y) * sin(R.x) * p[i].y
          + cos(R.y) * cos(R.x) * p[i].z;

      // Apply translation
      q[i].add(PVector.add(T, initial_height));

      // Obtain l vector
      l[i] = PVector.sub(q[i], b[i]);
    }
  }

  private void calculateAngleAlpha() {
    for (int i = 0; i < 6; i++) {
      float L = l[i].magSq() - ((ROD_LENGTH * ROD_LENGTH) - (HORN_LENGTH * HORN_LENGTH));
      float M = 2 * HORN_LENGTH * (q[i].z - b[i].z);
      float N = 2 * HORN_LENGTH * (cos(BETA[i]) * (q[i].x - b[i].x) + sin(BETA[i]) * (q[i].y - b[i].y));
      alpha[i] = asin(L / sqrt(M * M + N * N)) - atan2(N, M);

      // Obtain a vector
      a[i].set(HORN_LENGTH * cos(alpha[i]) * cos(BETA[i]) + b[i].x,
          HORN_LENGTH * cos(alpha[i]) * sin(BETA[i]) + b[i].y,
          HORN_LENGTH * sin(alpha[i]) + b[i].z);
    }
  }

  public void drawBall(float x, float y) {    
    PVector ball_plate = new PVector(x, y, 0);
    PVector ball = new PVector();
    
    ball.x = cos(R.z) * cos(R.y) * ball_plate.x +
        (-sin(R.z) * cos(R.x) + cos(R.z) * sin(R.y) * sin(R.x))  *ball_plate.y +
        (sin(R.z) * sin(R.x) + cos(R.z) * sin(R.y) * cos(R.x)) * ball_plate.z;

      ball.y = sin(R.z) * cos(R.y) * ball_plate.x +
        (cos(R.z) * cos(R.x) + sin(R.z) * sin(R.y) * sin(R.x)) * ball_plate.y +
        (-cos(R.z) * sin(R.x) + sin(R.z) * sin(R.y) * cos(R.x)) * ball_plate.z;

      ball.z = -sin(R.y) * ball_plate.x + cos(R.y) * sin(R.x) * ball_plate.y +
        cos(R.y) * cos(R.x) * ball_plate.z;
     
     ball.add(PVector.add(T, initial_height));
     
     strokeWeight(1);
     stroke(color(0, 0, 0));
     line(0, 0, 0, ball.x, ball.y, ball.z);
     strokeWeight(6);
     stroke(color(0, 0, 0));
     point(ball.x, ball.y, ball.z);
    
  }

  public void draw() {
    // Draw Base Axis
    strokeWeight(1);
    stroke(color(255, 0, 0));
    line(0, 0, 0, 40, 0, 0);
    stroke(color(0, 255, 0));
    line(0, 0, 0, 0, 40, 0);
    stroke(color(0, 0, 255));
    line(0, 0, 0, 0, 0, 40);

    // Draw Base
    fill(color(255, 229, 204, 127));
    strokeWeight(1);
    stroke(color(0, 0, 0));
    ellipse(0, 0, 2 * BASE_RADIUS, 2 * BASE_RADIUS);

    textMode(SHAPE);
    for (int i = 0; i < 6; i++) {
      // Draw B points
      pushMatrix();
      translate(b[i].x, b[i].y, b[i].z);
      strokeWeight(6);
      stroke(color(0, 0, 0));
      point(0, 0, 0);
      fill(color(0, 0, 0));
      textSize(10);
      text("B", 0, 0, 2);
      textSize(5);
      text(String.format("%d", i), 6, 0, 2);
      popMatrix();

      // Draw Horns
      stroke(color(0, 0, 0));
      strokeWeight(3);
      line(b[i].x, b[i].y, b[i].z, a[i].x, a[i].y, a[i].z);

      // Draw A points
      pushMatrix();
      translate(a[i].x, a[i].y, a[i].z);
      strokeWeight(6);
      stroke(color(0, 0, 0));
      point(0, 0, 0);
      fill(color(0, 0, 0));
      textSize(10);
      text("A", 0, 0, 2);
      textSize(5);
      text(String.format("%d", i), 6, 0, 2);
      popMatrix();

      // Draw S vectors
      stroke(color(0, 0, 0));
      strokeWeight(3);
      line(a[i].x, a[i].y, a[i].z, q[i].x, q[i].y, q[i].z);

      // Draw P points
      pushMatrix();
      translate(q[i].x, q[i].y, q[i].z);
      strokeWeight(6);
      stroke(color(0, 0, 0));
      point(0, 0, 0);
      fill(color(0, 0, 0));
      textSize(10);
      text("P", 0, 0, 2);
      textSize(5);
      text(String.format("%d", i), 6, 0, 2);
      popMatrix();
    }

    // Draw Platform
    pushMatrix();
    translate(initial_height.x, initial_height.y, initial_height.z);
    translate(T.x, T.y, T.z);
    rotateZ(R.z);
    rotateY(R.y);
    rotateX(R.x);
    fill(color(299, 255, 204, 127));
    strokeWeight(1);
    stroke(color(0, 0, 0));
    //ellipse(0, 0, 2 * PLATFORM_RADIUS, 2 * PLATFORM_RADIUS);
    quad(-225.0/2, 171.5/2, -225.0/2, -171.5/2, 225.0/2, -171.5/2, 255.0/2, 171.5/2);
 
    // Draw Platform Axis
    strokeWeight(1);
    stroke(color(255, 0, 0));
    line(0, 0, 0, 40, 0, 0);
    stroke(color(0, 255, 0));
    line(0, 0, 0, 0, 40, 0);
    stroke(color(0, 0, 255));
    line(0, 0, 0, 0, 0, 40);

    popMatrix();

  }
}
