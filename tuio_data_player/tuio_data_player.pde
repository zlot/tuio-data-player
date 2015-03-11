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
int warningTextAlpha = 255;
PFont font;

boolean verbose = false; // print console debug messages
int PORT = 3333;

HashMap<Integer, RecordedCursor> recordedCursors;
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
  
  recordedCursors = new HashMap<Integer, RecordedCursor>();
  loadDataFromFile();
}

void loadDataFromFile() {
  lines = loadStrings("3333.txt");
}

class RecordedCursor {
  public int id;
//  public float x,y; // note these are normalised x,y vals
  private ArrayList<PVector> points;
  
  RecordedCursor(int _id, PVector point) {
    id = _id;
    points = new ArrayList<PVector>();
    points.add(point);
  }
  
  void addTrackingPoint(PVector p) {
    points.add(p);
  }
  
  void draw() {
    stroke(0, 180);
    PVector startPoint = points.get(0);
    for(PVector p : points) {
      // unnormalise vals
      line(startPoint.x*width, startPoint.y*height, p.x*width, p.y*height);
      startPoint = p;
    }
    
    PVector lastKnownPoint = points.get(points.size()-1);
    ellipse(lastKnownPoint.x*width, lastKnownPoint.y*height, 10, 10);
    fill(0);
    text(""+ id,  lastKnownPoint.x*width+10,  lastKnownPoint.y*height+5);
  }
  
}

void runThroughData() {
    if(frameCount % lines.length == 0) {
      // we've run through all the data. Start again and warn!
      recordedCursors.clear();
      warningTextAlpha = 255;
    }
    String[] datum = split(lines[frameCount-1 % lines.length], ' ');
    
    String command = datum[0];
    int id = int(datum[3].substring(1,4));
    
    if(command.equals("add")) {
      float x = float(datum[4]);
      float y = float(datum[5]);
      RecordedCursor newC = new RecordedCursor(id, new PVector(x,y));
      recordedCursors.put(id, newC); 
    } else if(command.equals("set")) {
      float x = float(datum[4]);
      float y = float(datum[5]);
      recordedCursors.get(id).addTrackingPoint(new PVector(x,y));
    } else if(command.equals("del")) {
        recordedCursors.remove(id);
    }
}

void showDataFinishedText() {
  if(warningTextAlpha > 0) {
    textSize(30);
    pushStyle();
    fill(0,0,0,warningTextAlpha);
    text("DATA FINISHED. REPLAYING", width/7, height/2);
    popStyle();
    warningTextAlpha -= 2;
  } else {
    
  }
}

void draw() {
  background(255);
  if(warningTextAlpha > 0) showDataFinishedText();
  
  textFont(font,18*scale_factor);
  float cur_size = cursor_size*scale_factor; 
  
  runThroughData();
   
  for(RecordedCursor c : recordedCursors.values()) {
    c.draw();
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
