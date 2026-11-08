Plano3D[] planos;

float anguloX = 0;
float anguloY = 0;

float velocidad = 0.0;

int ejeRotacion = 2;
int sentido = 1;

boolean faster = false;
boolean slower = false;

void setup() {
  size(1000, 700, P3D);

  planos = new Plano3D[6];
  float radio = 200;

  for (int i = 0; i < planos.length; i++) {
    float angulo = TWO_PI * i / planos.length;
    float x = cos(angulo) * radio;
    float z = sin(angulo) * radio;

    planos[i] = new Plano3D(
      x,
      0,
      z,
      angulo
      );
  }
}

void draw() {
  background(20);

  ambientLight(120, 120, 120);
  directionalLight(
    255, 255, 255,
    0, 0, -1
    );

  pushMatrix();
  translate(width/2, height/2, 0);

  if (faster) {
    velocidad += 0.002;
  }
  if (slower) {
    velocidad -= 0.002;
  }

  if (ejeRotacion == 1) {
    anguloX += velocidad * sentido;
  }
  if (ejeRotacion == 2) {
    anguloY += velocidad * sentido;
  }

  rotateX(anguloX);
  rotateY(anguloY);

  for (int i = 0; i < planos.length; i++) {
    pushMatrix();
    planos[i].mostrar();
    popMatrix();
  }

  pushMatrix();
  fill(200, 100, 50);
  noStroke();
  sphere(40);
  popMatrix();

  popMatrix();
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == RIGHT) {
      ejeRotacion = 2;
      sentido = 1;
    }
    if (keyCode == LEFT) {
      ejeRotacion = 2;
      sentido = -1;
    }
    if (keyCode == DOWN) {
      ejeRotacion = 1;
      sentido = 1;
    }
    if (keyCode == UP) {
      ejeRotacion = 1;
      sentido = -1;
    }
  }

  if (key == 'd' || key == 'D') {
    ejeRotacion = 0;
  }

  if (key == 'r' || key == 'R') {
    anguloX = 0;
    anguloY = 0;
    ejeRotacion = 2;
    sentido = 1;

    for (int i = 0; i < planos.length; i++) {
      planos[i].cambiarDiseno();
    }
  }

  if (key == '+') {
    faster = true;
  }
  if (key == '-') {
    slower = true;
  }
}

void keyReleased() {
  if (key == '+') {
    faster = false;
  }
  if (key == '-') {
    slower = false;
  }
}

// ======================================================
// CLASE PLANO 3D (Diseño Cohete GeoGebra P3D)
// ======================================================

class Plano3D {

  float x;
  float y;
  float z;

  float orientacion;

  float ancho = 120;
  float alto = 180;

  color colorPlano;

  Plano3D(
    float x_,
    float y_,
    float z_,
    float orientacion_
    ) {
    x = x_;
    y = y_;
    z = z_;
    orientacion = orientacion_;
    cambiarDiseno();
  }

  void mostrar() {
    pushMatrix();

    translate(x, y, z);
    rotateY(-orientacion + HALF_PI);

    fill(colorPlano);
    stroke(255);
    strokeWeight(1);

    normal(0, 0, 1);

    beginShape(QUADS);
    vertex(-ancho/2, -alto/2, 0);
    vertex(ancho/2, -alto/2, 0);
    vertex(ancho/2, alto/2, 0);
    vertex(-ancho/2, alto/2, 0);
    endShape();

    popMatrix();
  }

  void cambiarDiseno() {
    colorPlano = color(
      random(80, 255),
      random(80, 255),
      random(80, 255)
      );
  }
}
