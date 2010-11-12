/*
Processing Serial Grapher
by Ewan Sinclair, based on on code by Tom Igoe and Jen Kirchherr:
http://itp.nyu.edu/physcomp/sensors/Code/DataloggerMulti
http://itp.nyu.edu/physcomp/sensors/Code/Multi

March 11 2010

This will read 3 variables as bytes from a serial connection and graph their values in real time.
Send a byte of value 255 before each frame of three bytes, which must range from 0-254 in value.
To allow for positive and negative values, adjust the axisOrigin array with offsets for each axis.
*/

import processing.serial.*;
import java.io.*;

Serial myPort; 
int[] serialInArray = new int[3];    
int serialCount = 0;                 

int i = 1;                   
int inByte = -1;             
int xpos, ypos, zpos = 0;

boolean firstContact = false;

//Track how many bytes in we are from a newline
int byteCounter=0;

//Used to track frequency of datapoints
int dataPointCounter=0;
int prevMillis=1001; //Frequency doesn't track if this isn't initially >1000, as the value of millis() is very different if set here
int frequency=0;
int timer=0;

//Size of the graph display area
int graphXsize=400;
int graphYsize=300;

//We will store a screenful's worth of values in this array, round robin stylee.
int[][] storedValues=new int[graphXsize][3];
int currentDataPoint=0;

//This array contains the offsets for all three axes (the incoming data is 0 to 254, and needs to be -127 to +127)
int[] axisOrigin={121,121,120};

boolean debug=false;

//Graphics variables
PFont fonty;
PGraphics buffer1;

void setup () {
  size(graphXsize, graphYsize);      
  println(Serial.list());

  myPort = new Serial(this, Serial.list()[0], 9600);

  background(0);
  //myPort.write(65); //Shouldn't need this, my arduino code doesn't need to be prodded
  buffer1=createGraphics(graphXsize, graphYsize, JAVA2D);

//Setup text rendering
  fonty=loadFont("SansSerif.plain-12.vlw");
  textFont(fonty);
  //textMode(SCREEN);
}

void draw () {

  if(millis()-prevMillis >= 1000){
   frequency=dataPointCounter;
   dataPointCounter=0;
   prevMillis=millis();
   timer++;
  }
  buffer1.background(0);
  drawGraph(buffer1);
  drawFrequency(buffer1);
  image(buffer1,0,0);

  while (myPort.available() > 0) {
    processByte(myPort.read());
  }
}

void drawFrequency(PGraphics g){
  g.beginDraw();
  g.textFont(fonty);
  g.text("Freq: "+frequency+"Hz",105,20);
  g.text("Secs: "+timer,105,35);
  g.endDraw();
}

void drawGraph(PGraphics g){
  //Draws a black background, followed by the lines for each input (X,Y,Z) using the historical data in the round-robin array
  g.beginDraw();
  g.textFont(fonty);
  g.text("X: "+storedValues[currentDataPoint][0],10,20);
  g.text("Y: "+storedValues[currentDataPoint][1],10,35);
  g.text("Z: "+storedValues[currentDataPoint][2],10,50);
  g.text("Agg: "+aggregate(storedValues[currentDataPoint]),10,65);
  int graphPosition=1;
  for(int count=currentDataPoint+1; count<graphXsize; count++){
    drawPoint(storedValues[count],storedValues[count-1],graphPosition,g);
    graphPosition++;
  }
  for(int count=1; count<currentDataPoint; count++){
    drawPoint(storedValues[count],storedValues[count-1],graphPosition,g);
    graphPosition++;
  }
  g.endDraw();
}

void drawPoint(int[] currentPoint, int[] lastPoint, int positionOnGraph, PGraphics g){
  //Draws a line between the last datapoint and the current for X,Y and Z. Done for all values, this forms a line graph.
  //Draw X
  g.stroke(255,0,0,150);
  g.line(positionOnGraph-1, height/2-lastPoint[0], positionOnGraph, height/2-currentPoint[0]);
  //Draw Y
  g.stroke(0,255,0,150);
  g.line(positionOnGraph-1, height/2-lastPoint[1], positionOnGraph, height/2-currentPoint[1]);
  //Draw Z
  g.stroke(0,0,255,150);
  g.line(positionOnGraph-1, height/2-lastPoint[2], positionOnGraph, height/2-currentPoint[2]);

  //Aggregate
  g.stroke(255,255,255,150);
  g.line(positionOnGraph-1, height-aggregate(lastPoint), positionOnGraph, height-aggregate(currentPoint));
}

int aggregate(int[] values){
  //return (Math.abs(values[0])+Math.abs(values[1])+Math.abs(values[2])); //Add absolute values of axes together
   
   //Return the square root of the squares of X,Y,Z. This is the magnitude of the force vector.
   int squares=(
      (int) Math.pow(Math.abs(values[0]),2)
      + (int) Math.pow(Math.abs(values[1]),2)
      + (int) Math.pow(Math.abs(values[2]),2)
    );
    return (int) Math.sqrt(squares);
}

void nextDataPoint(){
  //Increment the round-robin pointer into our datapoint array
  if(currentDataPoint < graphXsize-1){
    currentDataPoint++;
  }
  else{
    currentDataPoint=0; 
  }
  dataPointCounter++;
}

void processByte( int inByte) {
  //This method takes a byte and stores it in the incoming data array as an X,Y, or Z coordinate.

  if(inByte==255){
    //255 will be sent before each 3 value bytes. Value bytes will never be 255.
    serialCount=0;
    nextDataPoint();
    if(debug) {
      System.out.println("+");
    }
  }
  else if(serialCount<=2 && serialCount>=0){
    //Adjust new value to an axis origin
    int adjustedValue=inByte-axisOrigin[serialCount];
    //This section will fill in one of the three X,Y,Z values for the current datapoint.
    storedValues[currentDataPoint][serialCount] = adjustedValue;
    serialCount++;
    if(debug) {
      System.out.print("/" + inByte);
    }
  }
  else{
    //If this block is reached, the serial byte counter mechanism is broken. This may be due to the serial data being bad.
    System.err.println("Bad value for serial byte counter: " + serialCount +" / " + inByte);
  }

}



