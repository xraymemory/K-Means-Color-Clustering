/**
 Lab 7: K-Means Color Clustering 
 Michael Anzuoni
 Due: October 19th. 2011
 
 This lab demonstrates k-means color clustering. The user defines the cluster centers
 with 4 mouse clicks. The user can also switch between RGB and YUV mode with 'r' and 
 'y' respectively 

 For best results, start in RGB and then switch to YUV. 
 */

import processing.video.*;
Capture webcam;

PImage test; // original image used for testing
PImage reset; // copy of test 
PImage result;

//color of cluster
color clust;

// mode 1 = rgb, mode 2 = yuv
int mode;
// flag for copy of original
int copy = 0;

int minCent; // closest cluster
int n = 4; // number of clusters 
int m = 0; // mouse click counter
int t = 400; // threshold for collecting pixels in cluster
int centroid [][] = new int [n][5]; // clusters to be created
// n arrays for clustered pixels, used to re-calculate clusters,
int pix1 [][] = new int [1000000][5];
int pix2 [][] = new int [1000000][5];
int pix3 [][] = new int [1000000][5];
int pix4 [][] = new int [1000000][5];
// n counts for number of pixels assigned to each cluster 
int count1 = 0;
int count2 = 0;
int count3 = 0;
int count4 = 0;

void setup() {
  size(720, 478);
  //test = loadImage("test.jpg");
  webcam = new Capture(this, width, height, 30);
  result = new PImage(width, height);
  mode = 1; // default is RGB
}

void draw() {
  image(test, 0, 0);
  if (copy == 0){
    reset = get();
    copy = 1;
  }
  test = get();
  if (m == 4) {
    image(assignPixels(test), 0, 0);
    averageCluster(0, count1, pix1);
    averageCluster(1, count2, pix2);
    averageCluster(2, count3, pix3);
    averageCluster(3, count4, pix4);
  }
}
// utility functions 
void captureEvent(Capture cap){
  cap.read();
}

void mousePressed() {
  // user clicks 4 times to create cluster centers
  if (m < n) {
    m++;
    createCentroid(mouseX, mouseY, m-1);
    ellipse(mouseX, mouseY, 5, 5);
    println(m);
  }
}

void keyPressed() {
  if (key == 'r') {
    mode = 1;
  }
  if (key == 'y') {
    mode = 2;
  }

  if (key == 'n') {
    m = 0;
    image(reset, 0, 0);
  }
}

// k-means functions 

// places centroids at mouseX and mouseY
void createCentroid(int w, int h, int row) {
  color pixelColor = get(w, h);
  int r = (pixelColor >> 16) & 0xFF;
  int g = (pixelColor >> 8) & 0xFF;
  int b = pixelColor & 0xFF;
  // YUV mode
  if (mode == 2) {
    int y = (306*r + 601*g + 117*b)  >> 10;
    int u = ((-172*r - 340*g + 512*b) >> 10)  + 128;
    int v = ((512*r - 429*g - 83*b) >> 10) + 128;
    constrain(y, 0, 255);
    constrain(u, 0, 255);
    constrain(v, 0, 255);
    centroid[row][0] = w;
    centroid[row][1] = h;
    centroid[row][2] = y;
    centroid[row][3] = u;
    centroid[row][4] = v;
  }
  // RGB mode
  else {
    centroid[row][0] = w;
    centroid[row][1] = h;
    centroid[row][2] = r;
    centroid[row][3] = g;
    centroid[row][4] = b;
  }
} 


//assigns pixels to clusters based on the euclidean distance between x,y,r/y,g/u,b/v values
PImage assignPixels(PImage img) {
  img.loadPixels();
  result.loadPixels();

  for (int j = 0; j < width; j++) {
    for (int k = 0; k < height; k++) {
      //pixel values (in order): x, y, r, g, b,
      int px = j;
      int py = k;
      int pr = (img.pixels[py*width+px] >> 16) & 0xFF;
      int pg = (img.pixels[py*width+px] >> 8) & 0xFF;
      int pb = img.pixels[py*width+px] & 0xFF;
      
      if (mode == 2){
        // for the sake of performance, we'll just remap pr, pg, pb to be yuv without name changing
        // so we won't have to write different cases
        pr = (306*pr + 601*pg + 117*pb)  >> 10;
        pg = ((-172*pr - 340*pg + 512*pb) >> 10)  + 128;
        pb = ((512*pr - 429*pg - 83*pb) >> 10) + 128;
        constrain(pr, 0, 255);
        constrain(pg, 0, 255);
        constrain(pb, 0, 255);
      }

      // arbitrarily large float for comparison
      float minDist = 1000;

      for (int i = 0; i < n; i++) {
        int cx = centroid[i][0];
        int cy = centroid[i][1];
        int cr = centroid[i][2];
        int cg = centroid[i][3];
        int cb = centroid[i][4];
        if (mode == 2){
          // same conventions as pixels above
          cr = (306*cr + 601*cg + 117*cb)  >> 10;
          cb = ((-172*cr - 340*cg + 512*cb) >> 10)  + 128;
          cg = ((512*cr - 429*cg - 83*cb) >> 10) + 128;
          constrain(cr, 0, 255);
          constrain(cb, 0, 255);
          constrain(cg, 0, 255);
        }
        //calcuate euclidean distance and determine if they are to be clustered
        //based on the closest Euclidean Distance
        float eucDist = sqrt((pow(abs(cx-px), 2) + pow(abs(cy-py), 2) + pow(abs(cr-pr), 2)
          + pow(abs(cg-pg), 2) + pow(abs(cb-pb), 2)));

        if (eucDist < minDist) {
          minDist = eucDist;
          minCent = i;
          clust = color(cr, cg, cb);
        }
      }
      // count number of pixels in each cluster and add to them to respective arrays
      // I keep the pixels stable when they reach the index limit of the array
      switch(minCent) {
      case 0: 
        count1++; 
        if (count1 > 999999){count1--;}
        collectPixelVals(pix1, count1, px, py, pr, pg, pb); 
        break;
      case 1: 
        count2++; 
        if (count2 > 999999){count2--;}
        collectPixelVals(pix2, count2, px, py, pr, pg, pb); 
        break;
      case 2: 
        count3++; 
        if (count3 > 999999){count3--;}
        collectPixelVals(pix3, count3, px, py, pr, pg, pb); 
        break;
      case 3: 
        count4++; 
        if (count4 > 999999){count4--;}
        collectPixelVals(pix4, count4, px, py, pr, pg, pb); 
        break;
      }

      //color clustered image
      result.pixels[py*width+px] = clust;
    }
  }
  result.updatePixels();
  return result;
}



// collects pixel values to store in respective pixel arrays for calcuating the new cluster average
void collectPixelVals(int[][] arr, int num, int x, int y, int r, int g, int b) {
  arr[num][0] = x;
  arr[num][1] = y;
  arr[num][2] = r;
  arr[num][3] = g;
  arr[num][4] = b;
}

// calcuates the new average for the inputted cluster.
// just using the X and Y values prevents the colors from
// becoming big brown mushy clusters, hence why I have
// commented out the color averages. Sometimes the color
// average DOES work, though, as long as the colors are
// diverse and far enough apart
void averageCluster(int clustnum, int cnt, int[][] pix) {
  int cxavg = 0;
  int cyavg = 0;
  //int cravg = 0;
  //int cgavg = 0;
  //int cbavg = 0;
  for (int i = 0; i < cnt; i++) {
    cxavg += pix[cnt][0];
    cyavg += pix[cnt][1];
    //cravg += pix[cnt][2];
    //cgavg += pix[cnt][3];
    //cbavg += pix[cnt][4];

  }
  centroid[clustnum][0] = cxavg / cnt;
  centroid[clustnum][1] = cyavg / cnt;
  //centroid[clustnum][2] = cravg / cnt;
  //centroid[clustnum][3] = cgavg / cnt;
  //centroid[clustnum][4] = cbavg / cnt;
  
}


