// Pin values
int const pent_pin = A5;
int const joy_x_pin = A0;
int const joy_y_pin = A1;

// Interrupt state trackers
boolean double_score = false;
boolean invincibility = false;

void setup() {
  Serial.begin(9600);
  // Set pin modes
  pinMode(2, INPUT);
  pinMode(3, INPUT);
  // When button on pin 2 is pressed, function 'invincibility_power_up' is called
  attachInterrupt(digitalPinToInterrupt(2), invincibility_power_up, FALLING);
  // When button on pin 3 is pressed, function 'double_score_power_up' is called
  attachInterrupt(digitalPinToInterrupt(3), double_score_power_up, FALLING);
}

void loop() {
  // When the double score powerup is in use
  if(double_score) {
    // Let Processing know we have activated the double score powerup
    Serial.println(2);
    double_score = false;

  // Otherwise, when the invincibility powerup is in use
  } else if(invincibility) {
    // Let Processing know we have activated the invincibility powerup
    Serial.println(1);
    invincibility = false;

  // When no powerups are in use, read the ball's values as normal
  } else {
    // Read the potentiometer value and the x/y value
    int pent_value = analogRead(pent_pin);
    int x_pos = analogRead(joy_x_pin);
    int y_pos = analogRead(joy_y_pin);

    // Print out ball_size, x_position, y_position for Processing
    Serial.print(pent_value);
    Serial.print(",");
    Serial.print(x_pos);
    Serial.print(",");
    Serial.println(y_pos);
  }
}

// Called upon interrupt on pin 2
void invincibility_power_up() {
  // Set invincibility powerup on
  invincibility = true;
}

// Called upon interrupt on pin 3
void double_score_power_up() {
  // Note: this pin has issues (likely due to PWM) that
  // causes the interrupt on pin 2 to be triggered sometimes
  // Set double score powerup on
  double_score = true;
}
