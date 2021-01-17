/*
Create a laser cut box with finger joints
Released under the Creative Commons Attribution License
Some Rights Reserved: aaron . ciuffo 2 gmail.com

Version 2.6 05 November 2015
  * added lid hole
  * TODO: check kerf calculations

Version 2.5 18 September 2014
  * merged changes from 2.4 to allow different cut width on lid

Version 2.4 15 September 2014
  * variable cut width on lid
  * implementation is broken because uDiv is calculated from cutW, not cutWlid

Version 2.3 15 September 2014
  * partial rewrite of modules to make more parametric

*/

/* [Box OUTSIDE Dimensions] */
//Box Width (X)
bX=90;
//Box Depth (Y)
bY=140;
//Box Height (Z)
bZ=88;
//Material Thickness
cutD=3;
//include a lid?
addLid=1; //[1:Lid, 0:No Lid]
//Finger Hole Diameter
holeDia=0; //[0:50]


/*[Inside Supports]*/
//X Location - from origin
supXpos=20;

/* [Finger Width] */
//Finger  width (cutW < 1/3 shortest side)
cutW=5;//[3:20]
//Finger width on lid (cutWlid < 1/3 shorter of X/Y dimension)
cutWlid=15;//[3:30]
//Laser kerf (1/2 inside, 1/2 outside of laser path)
kerf=0.1;

/* [Layout] */
//separation of finished pieces
separation=1;
//transparency of 3D model
alpha=70; //[1:100]
//2D or 3D Layout
2D=0; //[1:2D for DXF, 0:3D for STL]



/* [Hidden] */
//Calculate the maximum number of tabs and slots
maxDivX=floor(bX/cutW);
maxDivY=floor(bY/cutW);
maxDivZ=floor(bZ/cutW);

//NB! the maximum usable divisions MUST be odd
uDivX= (maxDivX%2)==0 ? maxDivX-3 : maxDivX-2;
uDivY= (maxDivY%2)==0 ? maxDivY-3 : maxDivY-2;
uDivZ= (maxDivZ%2)==0 ? maxDivZ-3 : maxDivZ-2;

alp=1-alpha/100;

//cuts that fall completely insde the edges
module insideCuts(len, cutWidth, cutDepth, uDiv, lKerf=0.1) {

  //Calculate the number of tabs and slots
  numTabs=floor(uDiv/2);
  numSlots=ceil(uDiv/2);

  //draw out rectangles for slots
  for (i=[0:numSlots-1]) {
    translate([i*(cutWidth*2)+lKerf/2, 0, 0])
      square([cutWidth-lKerf, cutDepth]);
  }
}


//cuts that fall at the end of an edge
module outsideCuts(len, cutWidth, cutDepth, uDiv, lKerf=0.1, endCut) {

  numSlots=floor(uDiv/2);

  //padding - shift all the slots by the amount equal to the end cut plus one division
  padding=endCut+cutWidth;

  //first endcut - remove the bit of edge that falls outside the normal finger
  // joints
  square([endCut+lKerf/2, cutD]);

  //draw all the normal slots plus the last endcut
  for (i=[0:numSlots]) {
    if (i < numSlots) {
      translate([i*(cutWidth*2)+padding-lKerf/2, 0, 0])
        square([cutWidth+lKerf, cutDepth]);
    } else {
      //last endCut 
      translate([i*(cutWidth*2)+padding-lKerf/2, 0, 0])
        square([endCut+lKerf/2, cutDepth]);
    }
  }
 }


//Face A (X and Z dimension)
//Front and Back face
//uDiv - usable divisions, uDivLX - usable divisions on the Lid
module faceA(uDivX, uDivY, uDivZ, uDivLX) {
  difference() {
    square([bX, bZ], center=true);
    //X+/- edge (X axis in OpenSCAD)
    // if true, make cuts for the lid
    if (addLid) {
      //translate([-uDivX*cutW/2, bZ/2-cutD, 0])
      //  insideCuts(len=bX, cutWidth=cutW, cutDepth=cutD, uDiv=uDivX, lKerf=kerf);
      translate([-uDivLX*cutWlid/2, bZ/2-cutD, 0])
        insideCuts(len=bX, cutWidth=cutWlid, cutDepth=cutD, uDiv=uDivLX, lKerf=kerf);
    }
    translate([-uDivX*cutW/2, -bZ/2, 0])
      insideCuts(len=bX, cutWidth=cutW, cutDepth=cutD, uDiv=uDivX, lKerf=kerf);

    //Z+/- edge (Y axis in OpenSCAD)
    translate([bX/2-cutD+kerf/2, uDivZ*cutW/2, 0]) rotate([0, 0, -90])
      insideCuts(len=bZ, cutWidth=cutW, cutDepth=cutD, uDiv=uDivZ, lKerf=kerf);
    translate([-bX/2, uDivZ*cutW/2, 0]) rotate([0, 0, -90])
      insideCuts(len=bZ, cutWidth=cutW, cutDepth=cutD, uDiv=uDivZ, lKerf=kerf);

    translate([-bY/2+cutD/2+supXpos, 0, 0])
      internalSupport(uDivY, uDivZ, uDivLX, Zcutter=1);

  }
}

//Face B (X and Y dimension)
//create the lid and base
module faceB(uDivX, uDivY, uDivLX, uDivLY, lid=0) {

  
  //if this is the "lid" use cutWlid dimensions instead of cutW
  // create the local version of these variables

  uDivXloc= lid==1 ? uDivLX : uDivX;
  uDivYloc= lid==1 ? uDivLY : uDivY;
  cutWloc=  lid==1 ? cutWlid : cutW;
  lidHoleloc= lid==1 ? holeDia/2 : 0;

  //endCut = remaning edge after fingers have been made; this will 
  // be removed leaving an extra wide finger/slot
  endCutX=(bX-uDivXloc*cutWloc)/2;


  difference() {
    square([bX, bY], center=true);
    //X+/- edge (X axis in OpenSCAD)
    translate([(-uDivXloc*cutWloc/2)-endCutX, bY/2-cutD, 0])
    //Original: #translate([(-uDivX*cutW/2)-endCutX, bY/2-cutD+kerf/2, 0])
      outsideCuts(len=bX, cutWidth=cutWloc, cutDepth=cutD, uDiv=uDivXloc,
        lKerf=kerf, endCut=endCutX);
    translate([(-uDivXloc*cutWloc/2)-endCutX, -bY/2, 0])
      outsideCuts(len=bX, cutWidth=cutWloc, cutDepth=cutD, uDiv=uDivXloc,
        lKerf=kerf, endCut=endCutX);
    
    circle(r=lidHoleloc);

    //Y+/- edge (Y axis in OpenSCAD)
    translate([bX/2-cutD+kerf/2, uDivYloc*cutWloc/2, 0]) rotate([0, 0, -90])
      insideCuts(len=bY, cutWidth=cutWloc, cutDepth=cutD, uDiv=uDivYloc, lKerf=kerf);
    translate([-bX/2, uDivYloc*cutWloc/2, 0]) rotate([0, 0, -90])
      insideCuts(len=bY, cutWidth=cutWloc, cutDepth=cutD, uDiv=uDivYloc, lKerf=kerf);
    if (lid==0) { 
      translate([-bX/2+cutD-kerf*4+supXpos, 0, 0]) rotate([0, 0, 90])
        internalSupport(uDivY, uDivZ, uDivLX, Ycutter=1);
    }

  }
}


module faceC(uDivY, uDivZ, uDivLY) {
  //amount to cut off at the end of an outside cut edge
  endCutY=(bY-uDivY*cutW)/2;
  endCutZ=(bZ-uDivZ*cutW)/2;
  endCutLY=(bY-uDivLY*cutWlid)/2;

  difference() {
      square([bY, bZ], center=true);
      //Y+/- edge (X axis in OpenSCAD)
      if(addLid) {
        translate([(-uDivLY*cutWlid/2)-endCutLY, bZ/2-cutD, 0])
          outsideCuts(len=bY, cutWidth=cutWlid, cutDepth=cutD, uDiv=uDivLY, lKerf=kerf,
            endCut=endCutLY);
      }
      translate([(-uDivY*cutW/2)-endCutY, -bZ/2, 0])
        outsideCuts(len=bY, cutWidth=cutW, cutDepth=cutD, uDiv=uDivY, lKerf=kerf,
          endCut=endCutY);

      //Z+/- edge (Y axis in OpenSCAD)
      translate([-bY/2, (uDivZ*cutW/2)+endCutZ, 0]) rotate([0, 0, -90])
        outsideCuts(len=bZ, cutWidth=cutW, cutDepth=cutD, uDiv=uDivZ, lKerf=kerf,
          endCut=endCutZ);
      translate([bY/2-cutD+kerf/2, (uDivZ*cutW/2)+endCutZ, 0]) rotate([0, 0, -90])
        outsideCuts(len=bZ, cutWidth=cutW, cutDepth=cutD, uDiv=uDivZ, lKerf=kerf,
          endCut=endCutZ);
    }
}

module internalSupport(uDivY, uDivZ, uDivLY, Ycutter=0, Zcutter=0) {
  //decrease the usable divisions by dividing to improve strength of face 
  uDivZloc=ceil(uDivZ/2);
  uDivYloc=ceil(uDivY/2);

  difference() {
    faceC(uDivYloc, uDivZloc, uDivLY);
    translate([0, bZ/2-cutD/2, 0])
      square([bY, cutD], center=true);
   //if this is to be used as a cutter cut off everything other than the cutting bit
   if (Ycutter==1) {
    translate([0, cutD, 0])
      square([bY, bZ], center=true);
   }
   if (Zcutter==1) {
    translate([-cutD/2, 0, 0])
      square([bY-cutD+kerf/2, bZ], center=true);
   }
  }
}

module layout2D(uDivX, uDivY, uDivZ, uDivLX, uDivLY) {
  translate()
    color("orange") faceA(uDivX, uDivY, uDivZ, uDivLX); 


  if (addLid) {
  translate([0, -bZ/2-bY/2-separation, 0])
    color("green") faceB(uDivX, uDivY, uDivLX, uDivLY, lid=1);
  }
  
  translate([bX/2+bY/2+separation, 0, 0])
    color("blue") faceC(uDivY, uDivZ, uDivLY);

  translate([bX+separation+bY+separation, 0, 0])
    color("darkred") faceA(uDivX, uDivY, uDivZ, uDivLX);
  
  translate([bX/2+bY/2+separation, -bY, 0])
    color("navy") faceC(uDivY, uDivZ, uDivLY);

  translate([bX+separation+bY+separation, -bZ/2-bY/2-separation, 0])
    color("lime") faceB(uDivX, uDivY, lid=0);

  translate([bX/2+bY/2+separation, -bY-bZ-separation, 0])
    color("olive") internalSupport(uDivY, uDivZ, uDivLY);
}


module assemble3D(DivX, uDivY, uDivZ, uDivLX, uDivLY, alp=0.5) {
  //amount to shift for cut depth
  D=cutD/2;

  //bottom of box (B-)
  color("lime", alpha=alp)
    linear_extrude(height=cutD, center=true) faceB(uDivX, uDivY, lid=0);

  //lid of box (B+)
  
  if (addLid) {
  color("green", alpha=alp)
    translate([0, 0, bZ-cutD])
    linear_extrude(height=cutD, center=true) faceB(uDivX, uDivY, uDivLX, uDivLY, lid=1);
  }

  //faceA +/-
  color("red", alpha=alp)
    translate([0, bY/2-D, bZ/2-D]) rotate([90, 0, 0])
    linear_extrude(height=cutD, center=true) faceA(uDivX, uDivY, uDivZ, uDivLX);
  color("darkred", alpha=alp)
    translate([0, -bY/2+D, bZ/2-D]) rotate([90, 0, 0])
    linear_extrude(height=cutD, center=true) faceA(uDivX, uDivY, uDivZ, uDivLX);

  //FaceC +/-
  color("blue", alpha=alp)
    translate([bX/2-D, 0, bZ/2-D]) rotate([90, 0, 90])
    linear_extrude(height=cutD, center=true) faceC(uDivY, uDivZ, uDivLY);
  
  color("navy", alpha=alp)
    translate([-bX/2+D, 0, bZ/2-D]) rotate([90, 0, 90])
    linear_extrude(height=cutD, center=true) faceC(uDivY, uDivZ, uDivLY);

    
  color("olive", alpha=1)
    translate([supXpos, 0, bZ/2-D]) rotate([90, 0, 90])
    linear_extrude(height=cutD, center=true) internalSupport(uDivY, uDivZ, uDivLY);

}

module main() {
  //Calculate the maximum number of tabs and slots
  maxDivX=floor(bX/cutW);
  maxDivY=floor(bY/cutW);
  maxDivZ=floor(bZ/cutW);

  // calculate the maximum number of tabs for the lid cut width
  maxDivLX=floor(bX/cutWlid);
  maxDivLY=floor(bY/cutWlid);

  //Usable divisions on the X, Y, Z edges
  //NB! the maximum usable divisions MUST be odd
  uDivX= (maxDivX%2)==0 ? maxDivX-3 : maxDivX-2;
  uDivY= (maxDivY%2)==0 ? maxDivY-3 : maxDivY-2;
  uDivZ= (maxDivZ%2)==0 ? maxDivZ-3 : maxDivZ-2;

  uDivLX= (maxDivLX%2)==0 ? maxDivLX-3 : maxDivLX-2;
  uDivLY= (maxDivLY%2)==0 ? maxDivLY-3 : maxDivLY-2;


  alp=1-alpha/100;

  if (2D) {
    layout2D(uDivX, uDivY, uDivZ, uDivLX, uDivLY); 
  } else {
    assemble3D(uDivX, uDivY, uDivZ, uDivLX, uDivLY, alp);
  }
}


main();
