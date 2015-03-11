/* 
 Allows a txt file of TUIO tracking data to be replayed visually.
 Note, this is cut down to work only with TUIO cursors.
 Author: Mark C Mitchell / @zlot.
 Built from the work of Martin Kaltenbrunner <martin@tuio.org>
 
 //<>//
 TUIO 1.1 Demo for Processing
 Copyright (c) 2005-2014 Martin Kaltenbrunner <martin@tuio.org>

 Permission is hereby granted, free of charge, to any person obtaining
 a copy of this software and associated documentation files
 (the "Software"), to deal in the Software without restriction,
 including without limitation the rights to use, copy, modify, merge,
 publish, distribute, sublicense, and/or sell copies of the Software,
 and to permit persons to whom the Software is furnished to do so,
 subject to the following conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
 ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

// import the TUIO library
import TUIO.*;
// declare a TuioProcessing client
TuioProcessing tuioClient;

// these are some helper variables which are used
// to create scalable graphical feedback
float cursor_size = 15;
float table_size = 1200;
float scale_factor = 1;
PFont font;

boolean verbose = false; // print console debug messages
int PORT = 3333;

ArrayList<RecordedPoint> recordedPoints;
String[] lines;

void setup()
{
  // GUI setup
  noCursor();
  size(600,600);
  noStroke();
  fill(0);
  frameRate(60);
  font = createFont("Arial", 18);
  scale_factor = height/table_size;
  tuioClient  = new TuioProcessing(this, PORT);
  
  recordedPoints = new ArrayList<RecordedPoint>();
  loadDataFromFile();
}

void loadDataFromFile() {
  lines = loadStrings("3333.txt");
  
//  for(int i=0; i<lines.length; i++) {
//    String[] datum = split(lines[i], ' ');
//    
//    if(!(datum.length > 6))
//      continue;
//    
//    int id = int(datum[3]);
//    float x = float(datum[4]);
//    float y = float(datum[5]);
//    
//    boolean addToRecordedPoints = true;
//    // check if recorded point id exists in recordedPoints
//    for(RecordedPoint p : recordedPoints) {
//      if(p.id == id) {
//        p.x = x;
//        p.y = y;
//        addToRecordedPoints = false;
//        break;
//      }
//    }
//    if(addToRecordedPoints) {
//      RecordedPoint newP = new RecordedPoint(id, x, y);
//      recordedPoints.add(newP); 
//    }
//  }
}

class RecordedPoint {
  public int id;
  public float x,y; // note these are normalised x,y vals
  
  RecordedPoint(int _id, float _x, float _y) {
    id = _id;
    x = _x;
    y = _y;
  }
  
  void draw() {
    // unnormalise vals
    ellipse(x*width, y*height, 10, 10);
    fill(0);
    text(""+ id,  x*width+10,  y*height+5);
  }
  
}

void runThroughData() {
    String[] datum = split(lines[frameCount % lines.length], ' ');
    
    if(!(datum.length > 6))
      return;
    
    int id = int(datum[3].substring(1,4));
    println(id);
    float x = float(datum[4]);
    float y = float(datum[5]);
    
    boolean addToRecordedPoints = true;
    // check if recorded point id exists in recordedPoints
    for(RecordedPoint p : recordedPoints) {
      if(p.id == id) {
        p.x = x;
        p.y = y;
        addToRecordedPoints = false;
        break;
      }
    }
    if(addToRecordedPoints) {
      RecordedPoint newP = new RecordedPoint(id, x, y);
      recordedPoints.add(newP); 
    }  
}

void draw() {
  background(255);
  textFont(font,18*scale_factor);
  float cur_size = cursor_size*scale_factor; 
  
  runThroughData();
  
  
  for(RecordedPoint p : recordedPoints) {
    p.draw();
  }
  
  
   ArrayList<TuioCursor> tuioCursorList = tuioClient.getTuioCursorList();
   for (int i=0;i<tuioCursorList.size();i++) {
      TuioCursor tcur = tuioCursorList.get(i);
      ArrayList<TuioPoint> pointList = tcur.getPath();
      
      if (pointList.size()>0) {
        stroke(0,0,255);
        TuioPoint start_point = pointList.get(0);
        for (int j=0;j<pointList.size();j++) {
           TuioPoint end_point = pointList.get(j);
           line(start_point.getScreenX(width),start_point.getScreenY(height),end_point.getScreenX(width),end_point.getScreenY(height));
           start_point = end_point;
        }
        stroke(192,192,192);
        fill(192,192,192);
        ellipse( tcur.getScreenX(width), tcur.getScreenY(height),cur_size,cur_size);
        fill(0);
        text(""+ tcur.getCursorID(),  tcur.getScreenX(width)-5,  tcur.getScreenY(height)+5);
      }
   }
}


void addTuioCursor(TuioCursor tcur) {
  if (verbose) println("add cur "+tcur.getCursorID()+" ("+tcur.getSessionID()+ ") " +tcur.getX()+" "+tcur.getY());
}

void updateTuioCursor (TuioCursor tcur) {
  if (verbose) println("set cur "+tcur.getCursorID()+" ("+tcur.getSessionID()+ ") " +tcur.getX()+" "+tcur.getY()
          +" "+tcur.getMotionSpeed()+" "+tcur.getMotionAccel());
}

void removeTuioCursor(TuioCursor tcur) {
  if (verbose) println("del cur "+tcur.getCursorID()+" ("+tcur.getSessionID()+")");
}


// called at the end of each TUIO frame
void refresh(TuioTime frameTime) {
  if (verbose) println("frame #"+frameTime.getFrameID()+" ("+frameTime.getTotalMilliseconds()+")");
  redraw();
}

void keyPressed() {
 
}
