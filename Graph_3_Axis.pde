//this allows you to look at 3 analog outputs at the same time in processing
import processing.serial.*;

Serial myPort; 
int[] serialInArray = new int[3];    
int serialCount = 0;                 

int i = 1;                   
int inByte = -1;             
int xpos, ypos, zpos = 0;

boolean firstContact = false;

//Track how many bytes in we are from a newline
int byteCounter=0;

//Size of the graph display area
int graphXsize=400;
int graphYsize=300;

//We will store a screenful's worth of values in this array, round robin stylee.
int[][] storedValues=new int[graphXsize][3];
int currentDataPoint=0;

boolean debug=false;

void setup () {
  size(graphXsize, graphYsize);      
  println(Serial.list());

  myPort = new Serial(this, Serial.list()[0], 9600);

  background(0);
  //myPort.write(65); //Shouldn't need this, my arduino code doesn't need to be prodded
}

void draw () {
  
  drawGraph();
  
  while (myPort.available() > 0) {
    processByte(myPort.read());
  }
  /*
  if (firstContact == false) {
   delay(300);
   myPort.write(65);
   }
   */
}

void drawGraph(){
  //Draws a black background, followed by the lines for each input (X,Y,Z) using the historical data in the round-robin array
  background(0);
  int graphPosition=1;
  for(int count=currentDataPoint+1; count<graphXsize; count++){
    drawPoint(storedValues[count],storedValues[count-1],graphPosition);
    graphPosition++;
  }
  for(int count=1; count<currentDataPoint; count++){
    drawPoint(storedValues[count],storedValues[count-1],graphPosition);
    graphPosition++;
  }
}

void drawPoint(int[] currentPoint, int[] lastPoint, int positionOnGraph){
  //Draw X
  stroke(255,0,0,150);
  line(positionOnGraph-1, height-lastPoint[0], positionOnGraph, height-currentPoint[0]);
  //Draw Y
  stroke(0,255,0,150);
  line(positionOnGraph-1, height-lastPoint[1], positionOnGraph, height-currentPoint[1]);
  //Draw Z
  stroke(0,0,255,150);
  line(positionOnGraph-1, height-lastPoint[2], positionOnGraph, height-currentPoint[2]);
  
  //Aggregate
  stroke(255,255,255,150);
  int aggregateCurrent=(currentPoint[0]+currentPoint[1]+currentPoint[2])/3;
  int aggregateLast=(lastPoint[0]+lastPoint[1]+lastPoint[2])/3;
  line(positionOnGraph-1, height-aggregateLast, positionOnGraph, height-aggregateCurrent);
}

void drawGraphOld () {
  //Deprecated. Throw rocks at it!
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

void nextDataPoint(){
  //Increment the round-robin pointer into our datapoint array
  if(currentDataPoint < graphXsize-1){
    currentDataPoint++;
  }
  else{
    currentDataPoint=0; 
  }
}

void processByte( int inByte) {
  //This method takes a byte and stores it in the incoming data array as an X,Y, or Z coordinate.

  if(inByte==255){
    //255 will be sent before each 3 value bytes. Value bytes will never be 255.
    serialCount=0;
    nextDataPoint();
    if(debug) {System.out.println("+");}
  }
  else if(serialCount<=2 && serialCount>=0){
    //This section will fill in one of the three X,Y,Z values for the current datapoint.
    storedValues[currentDataPoint][serialCount] = inByte;
    serialCount++;
    if(debug) {System.out.print("/" + inByte);}
  }
  else{
    //If this block is reached, the serial byte counter mechanism is broken. This may be due to the serial data being bad.
    System.err.println("Bad value for serial byte counter: " + serialCount +" / " + inByte);
  }

  /*
  serialInArray[serialCount] = inByte;
   serialCount++;
   
   if (serialCount > 2 ) {
   xpos = serialInArray[0];
   ypos = serialInArray[1];
   zpos = serialInArray[2];
   
   drawGraph();
   myPort.write(65);
   serialCount = 0;
   */

}


