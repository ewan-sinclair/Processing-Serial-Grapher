//this allows you to look at 3 analog outputs at the same time in processing
import processing.serial.*;

Serial myPort; 
int[] serialInArray = new int[3];    
int serialCount = 0;                 

int i = 1;                   
int inByte = -1;             
int xpos, ypos, zpos = 0;

boolean firstContact = false;

void setup () {
  size(400, 300);      
  println(Serial.list());

  myPort = new Serial(this, Serial.list()[0], 9600);

  background(0);
  myPort.write(65);   
}
void draw () {
  while (myPort.available() > 0) {
    processByte(myPort.read());
    firstContact = true;
  }
  if (firstContact == false) {
    delay(300);
    myPort.write(65);
  }
}

void drawGraph () {
  int valueToGraph0 = 0;
  int valueToGraph1 = 0;
  int valueToGraph2 = 0;

  valueToGraph0 = xpos;
  stroke(255,0,0,150);
  valueToGraph1 = ypos;
  stroke(0,255,0,150);
  valueToGraph2 = zpos;
  stroke(0,0,255,150);

  line(i, height, i, height - valueToGraph0);
  line(i, height, i, height - valueToGraph1);
  line(i, height, i, height - valueToGraph2);

  if (i >= width-2) {
    i = 0;
    background(0); 
  } 
  else {
    i++;
  }
}

void processByte( int inByte) {

  serialInArray[serialCount] = inByte;
  serialCount++;

  if (serialCount > 2 ) {
    xpos = serialInArray[0];
    ypos = serialInArray[1];
    zpos = serialInArray[2];

    drawGraph();
    myPort.write(65);
    serialCount = 0;
  }
}

