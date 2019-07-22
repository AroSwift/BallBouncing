//Handle Serial Communication
import processing.serial.*;
Serial myPort;

//Objects to be dodged by user
//Ball(xLocation, yLocation, Radius)
Ball[] obstacles ={
    new Ball(22, 22, 20, #FF0000, 3),
    new Ball(54, 54, 20, #FF0000, 3),
    new Ball(106, 106, 30, #00FF00, 3),
    new Ball(169, 169, 30, #00FF00, 3),
    new Ball(241, 241, 40, #0000FF, 3),
    new Ball(250, 600, 40, #0000FF, 3),
    new Ball(445, 445, 80, #FFFF00, 3),
    new Ball(607, 607, 80, #FFFF00, 3)
  };

//Handle user's scoreboard
float score = 0;
int last_score_update;
int score_update_delay = 1000;
boolean win = false;

// User ball variables
Ball user_ball = new Ball(350, 350, 15, #dfe1e3, 0);
int powerup_update_delay = 2000;
int invincibility_last_update;
int double_score_last_update;
int invincibility_usage_count = 0;
int double_score_usage_count = 0;
float size = 15;
float pos_x;
float pos_y;

void setup()
{
   size(700, 700);//screen size

   myPort = new Serial(this, Serial.list()[1], 9600);//Modify for your Arduino Com Port
   myPort.bufferUntil('\n');
   
   // Set the score update to now
   last_score_update = millis();
   // Set the invincibility and double score last update to now - 2 seconds (to prevent run on start)
   invincibility_last_update =  millis() - powerup_update_delay;
   double_score_last_update = millis() - powerup_update_delay;
}

void serialEvent(Serial myPort) {
   String inString = myPort.readStringUntil('\n');
   println("Value Read: " + inString);
   
   //Processing serial value(s)
   if(inString != null) {
    // Read in and tokenize the serial string
    inString = trim(inString);
    float[] values = float(split(inString, ","));
    
    // When we have only one token
    if(values.length == 1) {
      // When the token indicates invincibility
      if(values[0] == 1) {
        // And the invincibility powerup has not been used more than twice
        if(invincibility_usage_count <= 1) {
          invincibility_last_update = millis();
          invincibility_usage_count += 1;
        }
      // When the token indicates double score
      } else if(values[0] == 2) {
        // And the double score powerup has not been used more than twice
        if(double_score_usage_count <= 1) {
          double_score_last_update = millis();
          double_score_usage_count += 1;
        }
      }
    // Otherwise, when we have at least 3 tokens
    } else if(values.length >= 3) {
      // Get the size, position, and button state
      size = values[0];
      pos_x = values[1];
      pos_y = values[2];
      
      // Map the size, x position, and y position to usuable values
      size = map(size, 0, 1023, 15, 100);
      pos_x = map(pos_x, 0, 1023, 0, 700);
      pos_y = map(pos_y, 0, 1023, 0, 700);
      
      // Set the user ball's position (between 0-700)
      user_ball.setPosition(pos_x, pos_y);
      // Then set the user ball's size (between 15-100)
      user_ball.setRadius(size);
    }
  }
}

void draw() {
   background(150); //gray background
  
   // When the score is at least 100
   if(score >= 100) {
     win = true;
   }
   
   // When the user won
   if(win) {
     // Everything is cleared from the screen because
     // The screen is redrawn each iteration in the loop
     // Now, inform the user of winning status
     textSize(32);
     textAlign(CENTER);
     text("You win!", width / 2, height / 2);
   } else { // Otherwise, print score as normal
     //display Current Score
     textSize(32);
     textAlign(CENTER);
     text("Score:  " + score, width / 2, 30);
   
     // Update the user's ball (e.g. position, size, and draw it)
     user_ball.update();
     user_ball.checkBoundaryCollision();
     user_ball.display();
     
     // When the alloted time has expired since the last run (1 second)
     if(millis() - last_score_update >= score_update_delay) {
       // Get the points earned since the last update
       float points_earned = (size / 100) * 2;
       
       // When the double score powerup's effects are still working (2 seconds)
       if(millis() - double_score_last_update <= powerup_update_delay) {
         // Double the score earned
         points_earned *= 2;
       }
       
       // Add the points earned to the score
       score += points_earned;
       // Set the last update to the current time
       last_score_update = millis();
     }
    
     // When the invincibility powerup's effects are still working (2 seconds)
     if(millis() - invincibility_last_update <= powerup_update_delay) {
       
       // Update the upstacle's positions and check if they have collided with the edge of the screen
       for (Ball b : obstacles) {
         b.update();
         b.display();
         b.checkBoundaryCollision();
       }
  
    } else { // Otherwise, check for collisions as usual
       //Update the upstacle's positions and check if they have collided with the edge of the screen
       for (Ball b : obstacles) {
         // Check if a ball has collided with the user's ball
         b.update();
         b.display();
         b.checkBoundaryCollision();
        
         // When a computer ball collides with the user ball or visa versa
         if(b.hasCollided(user_ball) || user_ball.hasCollided(b)) {
          // Reset score
          score = 0;
         }
      }
      
      //Check if any two ball's have collided
      for(int mainBall = 0; mainBall < obstacles.length; mainBall++)
      {
        for(int compareBall = mainBall + 1; compareBall < obstacles.length; compareBall++)
        {
          obstacles[mainBall].checkCollision(obstacles[compareBall]);//Update to nested for loop
        } 
        // Check if a ball has collided with the user's ball
        obstacles[mainBall].checkCollision(user_ball);
      }  
    }
    
  } // Check winning status
}

/*
* Class taken from https://processing.org/examples/circlecollision.html & modified to allow for manual control
*
* Important methods:
*  setPosition(x, y) - manually update the ball's position
*  hasCollided(Ball b) - returns true, if two ball's have collided
*  display() - draw the ball
*/
class Ball {
  PVector position;
  PVector velocity;

  float radius, m;
  int rgbColor;

  Ball(float x, float y, float r_, int rgb, int init_velocity) {
    position = new PVector(x, y);
    velocity = PVector.random2D();
    velocity.mult(init_velocity);
    radius = r_;
    m = radius*.1;
    rgbColor = rgb;
  }
  
  void setPosition(float x, float y)
  {
      position = new PVector(x, y); 
  }
  
  void setRadius(float r_)
  {
    radius = r_;
  }

  void update() {
    position.add(velocity);
  }

  void checkBoundaryCollision() {
    if (position.x > width-radius) {
      position.x = width-radius;
      velocity.x *= -1;
    } else if (position.x < radius) {
      position.x = radius;
      velocity.x *= -1;
    } else if (position.y > height-radius) {
      position.y = height-radius;
      velocity.y *= -1;
    } else if (position.y < radius) {
      position.y = radius;
      velocity.y *= -1;
    }
  }

boolean hasCollided(Ball other) {
    boolean collided = false;
    // Get distances between the balls components
    PVector distanceVect = PVector.sub(other.position, position);

    // Calculate magnitude of the vector separating the balls
    float distanceVectMag = distanceVect.mag();

    // Minimum distance before they are touching
    float minDistance = radius + other.radius;

    if (distanceVectMag < minDistance) {
      collided = true;
    }
    return collided;
}

  void checkCollision(Ball other) {

    // Get distances between the balls components
    PVector distanceVect = PVector.sub(other.position, position);

    // Calculate magnitude of the vector separating the balls
    float distanceVectMag = distanceVect.mag();

    // Minimum distance before they are touching
    float minDistance = radius + other.radius;

    if (distanceVectMag < minDistance) {
      float distanceCorrection = (minDistance-distanceVectMag)/2.0;
      PVector d = distanceVect.copy();
      PVector correctionVector = d.normalize().mult(distanceCorrection);
      other.position.add(correctionVector);
      position.sub(correctionVector);

      // get angle of distanceVect
      float theta  = distanceVect.heading();
      // precalculate trig values
      float sine = sin(theta);
      float cosine = cos(theta);

      /* bTemp will hold rotated ball positions. You 
       just need to worry about bTemp[1] position*/
      PVector[] bTemp = {
        new PVector(), new PVector()
      };

      /* this ball's position is relative to the other
       so you can use the vector between them (bVect) as the 
       reference point in the rotation expressions.
       bTemp[0].position.x and bTemp[0].position.y will initialize
       automatically to 0.0, which is what you want
       since b[1] will rotate around b[0] */
      bTemp[1].x  = cosine * distanceVect.x + sine * distanceVect.y;
      bTemp[1].y  = cosine * distanceVect.y - sine * distanceVect.x;

      // rotate Temporary velocities
      PVector[] vTemp = {
        new PVector(), new PVector()
      };

      vTemp[0].x  = cosine * velocity.x + sine * velocity.y;
      vTemp[0].y  = cosine * velocity.y - sine * velocity.x;
      vTemp[1].x  = cosine * other.velocity.x + sine * other.velocity.y;
      vTemp[1].y  = cosine * other.velocity.y - sine * other.velocity.x;

      /* Now that velocities are rotated, you can use 1D
       conservation of momentum equations to calculate 
       the final velocity along the x-axis. */
      PVector[] vFinal = {  
        new PVector(), new PVector()
      };

      // final rotated velocity for b[0]
      vFinal[0].x = ((m - other.m) * vTemp[0].x + 2 * other.m * vTemp[1].x) / (m + other.m);
      vFinal[0].y = vTemp[0].y;

      // final rotated velocity for b[0]
      vFinal[1].x = ((other.m - m) * vTemp[1].x + 2 * m * vTemp[0].x) / (m + other.m);
      vFinal[1].y = vTemp[1].y;

      // hack to avoid clumping
      bTemp[0].x += vFinal[0].x;
      bTemp[1].x += vFinal[1].x;

      /* Rotate ball positions and velocities back
       Reverse signs in trig expressions to rotate 
       in the opposite direction */
      // rotate balls
      PVector[] bFinal = { 
        new PVector(), new PVector()
      };

      bFinal[0].x = cosine * bTemp[0].x - sine * bTemp[0].y;
      bFinal[0].y = cosine * bTemp[0].y + sine * bTemp[0].x;
      bFinal[1].x = cosine * bTemp[1].x - sine * bTemp[1].y;
      bFinal[1].y = cosine * bTemp[1].y + sine * bTemp[1].x;

      // update balls to screen position
      other.position.x = position.x + bFinal[1].x;
      other.position.y = position.y + bFinal[1].y;

      position.add(bFinal[0]);

      // update velocities
      velocity.x = cosine * vFinal[0].x - sine * vFinal[0].y;
      velocity.y = cosine * vFinal[0].y + sine * vFinal[0].x;
      other.velocity.x = cosine * vFinal[1].x - sine * vFinal[1].y;
      other.velocity.y = cosine * vFinal[1].y + sine * vFinal[1].x;
    }
  }

  void display() {
    noStroke();
    fill(rgbColor);
    ellipse(position.x, position.y, radius*2, radius*2);
  }
}