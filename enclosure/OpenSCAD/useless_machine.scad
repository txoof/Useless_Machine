/*
Useless Machine! By Aaron Ciuffo 
*/


//servo
//use <./libraries/futabaS3004.scad>
use <./libraries/hitec-HS422.scad>
//toggle switch
use <./libraries/toggle_switch.scad>
//mockup of external hinge
use <./libraries/stardard_hinge.scad>
//lever actuated micro switch
use <./libraries/micro_switch-variant.scad>
use <./libraries/micro_switch.scad>
//rough mockup of a 4XAA 6V battery pack
use <./libraries/4AA_battery.scad>

/*[Project Setup]*/
VERSION="UM V1.34";
// Layout 2D or 3D
2D=0; //[1:2D for DXF, 0:3D for Preview]
//Material Thickness
thick=3.8;
//separation of finished pieces in 2D layout
separation=2;
//transparency of 3D model
alpha=5; //[1:100]


/*[Box Outside Dimensions]*/
//Box Width - X
bX=110;
//Box Depth - Y
bY=150;
//Box Height - Z
bZ=110; //100 -testing adjustments for microswtich
//arm material thickness
armThick=thick;

/*[Box Features]*/
//Include a lid?
addLid=1; //[1:Lid, 0:No Lid]
//Finger Hole Diameter - 0==no hole
//holeDia=0; //[0:50] -- moved into switch configuration
holeFacets=36;//[3:36]
//lid fastners
lidCatch=1; //[0:no catch, 1:catch]
cornerR=1; //corner radius on lid catch
lidBolt=3; //metric bolt size for sizing nut

/*[Finger Width]*/
//Finger width (NB! width must be < 1/3 shortest side)
fingerW=5;//[3:20]
//Lid finger width 
fingerLidW=36;//[3:20]




/*[Internal Support]*/
//horn to bottom of flange 17.6, armThickness=thickness of arm material
supXpos=-thick/2-17.6-armThick/2;

/*[Servo Position]*/
//placement on internal support
serX=0; // just off center to accomodate arm thickness
serY=-15; //-10 
serZ=79;   

/*[Switch]*/
switchX=0;
switchY=-53.5; //48.5
swtichZ=0;
switchDia=6.05;
holeDia=switchDia;

/*[Arm]*/
//size of hole
armHX=40; //35
armHY=75; //50
//border to remove around hole opening to allow smooth open/close
armHBorder=thick/4;
//position of hole from edge
armFromYEdge=17;
// files for arm
armFile="./libraries/arm_rv1.dxf";
headFile="./libraries/pusher_head_rv1.dxf";
armRot=11; //off position
armRotAnim=$t*110; // rotate to +105 to see switch fliping position
//Door jamb dimensions
doorJX=armHX+6;
doorJY=10;


/*[Hinge Dimensions]*/
//hingeX=15.3;
//hingeY=18.2;
//Larger Hinge
hingeX=18.8;
hingeY=25.6;


/*[Internal Supports]*/
//bDimension/Ratio to determines the length and number of tabs on internal supports
//switch support
ssRatio=2;
//internal support Z dimension ratio to decrease the tabs by
isRatioZ=1.5;
//internal support Y dimension ratio to decrease the tabs by
isRatioY=1.3;



/*[Battery Pack]*/
//dimensions - useful for calculations below
batX=58.5; 
batY=64;
batZ=16;
batPosX=30;
batPosY=35;
batPosZ=0;

/*[Driver Board]*/
//Driver Board dimensions
brdX=66;
brdY=40;
brdZ=10;
brdFile="./libraries/driver_board_rv1.dxf";
//position
brdXpos=0;
brdYpos=48;
brdZpos=-17;
//mounting bolt diameter (m size)
brdBlt=3;

/*[Micro Switch]*/
//Dimensions of switch 
mswX=20;
mswY=10.3;
mswZ=14;
mswXpos=0;
mswYpos=-29;
//FIXME consider adjusting this if the microswitch does not fit properly
mswZpos=8.5; // was 8

//position for the switch support
swXsup=0;
swYsup=-20;
swZaup=0;

/*[Wire Routing Hole]*/
holeY=-bY/6;
holeZ=-bZ/5;
holeScale=1.5;
holeFile="./libraries/raven_rv1.dxf";

/*[Zip Tie Holes]*/
zTieX=3.5; //width
zTieZ=1.6; //thickness
zTieY=18; //distance betwen holes
// Locations for zip ties [X, Y, Z, rotation]
zTieLoc=[
          [-48, -5, 0, -65],
          [-50, 20, 0, 90],
          [-2, -35, 0, 0], 
          [15, -35, 0 , 0] ];


/*[Hidden]*/
//transparency alpha
alp=1-alpha/100;

//Catch Dimensions
f=1.8*lidBolt; //flat distance is 1.8 * m bolt diameter
r=(f*1/cos(30))/2; //radius of metric nut
catch=r*3-2*cornerR; //catch X and Y dimensions


//cuts that fall complete inside the edge
module insideCuts(length, fWidth, cutD, uDiv) {
  //Calculate the number of fingers and cuts
  numFinger=floor(uDiv/2);
  numCuts=ceil(uDiv/2);

  //draw out rectangles for slots
  for (i=[0:numCuts-1]) {
    translate([i*(fWidth*2), 0, 0])
      square([fWidth, cutD]);
  }
}

//cuts that fall at the end of an edge requirng an extra long cut
module outsideCuts(length, fWidth, cutD, uDiv) {
  numFinger=ceil(uDiv/2);
  numCuts=floor(uDiv/2);
  //calculate the length of the extra long cut
  endCut=(length-uDiv*fWidth)/2;
  //amount of padding to add to the itterative placement of cuts 
  // this is the extra long cut at the beginning and end of the edge
  padding=endCut+fWidth;
  
  square([endCut, cutD]);

  for (i=[0:numCuts]) {
    if (i < numCuts) {
      translate([i*(fWidth*2)+padding, 0, 0])
        square([fWidth, cutD]);
    } else {
      translate([i*(fWidth*2)+padding, 0, 0])
        square([endCut, cutD]);
    }
  }
}

module lidCatch(boltHole=true, project=false, tab=false, pct=1.05) {
  if (project==false) {
    //center on the base of the tab to make positioning easier
    translate([0, -catch/2-cornerR])
    difference() {
      union() {
        hull() {
          square(catch, center=true);
          //iterate over quadrants I-IV 
          //place a circle in each corner to make the rounded square hull
          for (i=[ [-1, 1], [1, 1], [1, -1], [-1, -1]]) {
            translate([i[0]*(catch/2), i[1]*(catch/2)])
              circle(r=cornerR, $fn=36);
          } // close for
        } //close hull

        //add a tab to the piece without the nut hole
        if (boltHole==false) {
          translate([0, (catch/2+cornerR)+thick/2])
            square([fingerW, thick], center=true);
        } //close if bolthole
      } //close union
      if (boltHole==true) {
        circle(r=r*pct, $fn=6);
      } else {
        circle(r=lidBolt/2*pct, $fn=36);
      } // close if boltHole
    } //close difference
  } else { //close if project 
    if (tab==false) {
      translate([0, -catch/2-cornerR])
        circle(r=lidBolt/2*pct, $fn=36);
    } else {
        //center the tab projection
        square([fingerW*pct, thick], center=true);
    } 
  }
}

module boardStandOff(r=2, c=4) {
  inRad=brdBlt/2*1.05;
  outRad=inRad+2;
  for (i = [0:r-1] ) {
    translate([0, -i*(outRad*2+separation), 0])
    for (j = [0:c-1]) { 
      translate([j*(outRad*2+separation), 0])
        difference() {
          circle(r=outRad, $fn=36);
          circle(r=inRad, $fn=36);
        }
    }
  }
  
}


//Punch holes in the other faces to match the tabs on the support
module supportPunch(length, fWidth, cutD, uDiv) {
  //subract 4 tabs to make the support less intrusive.
  //TODO find a better way of dealing with this; breaks down below 30mm with 5mm tabs
  locuDiv=uDiv-4;
  numFinger=ceil(locuDiv/2);
  numCuts=floor(locuDiv/2);

  //calculate the length of the extra long cut
  endCut=(length-uDiv*fWidth)/2;
  //amount of padding to add to the itterative placement of cuts 
  // this is the extra long cut at the beginning and end of the edge
  padding=endCut+fWidth;
  
//  square([endCut, cutD]);
  
  for (i=[0:numCuts]) {
    translate([i*(fWidth*2)+endCut, -cutD/2, 0])
      square([fWidth, cutD]);

  }
}


//Punch holes in other faces to match the tabs on an internal support
module holePunch(length, uDiv, Q=2) {
  divLoc = (floor(uDiv/Q)%2)==0 ? floor(uDiv/Q)-1 : floor(uDiv/Q);
  numCuts=floor(divLoc/2);
  
  locLength=bY/Q; //length of support = boxY/Q
  endCut=(locLength-divLoc*fingerW)/2;
  translate([-divLoc*fingerW/2-endCut, 0, 0])
  for (i=[0:numCuts]) {
    translate([i*(fingerW*2)+endCut, -thick/2, 0])
      square([fingerW, thick]);
  }
}

module armHole() {
  difference() {
    square([armHX, armHY], center=true);
    square([armHX-armHBorder, armHY-armHBorder], center=true);
  }
}

module zipTie() {
  translate([0, -zTieY/2, 0])
    square([zTieX, zTieZ], center=true);
  translate([0, zTieY/2, 0])
    square([zTieX, zTieZ], center=true);

}

//Face A (X and Z dimensions)
//Front and back face
module faceA(uDivX, uDivY, uDivZ, uDivLX, uDivLY) {
  difference() {
    square([bX, bZ], center=true);

    //X+/- edge (X axis in OpenSCAD)
    //if true, make cuts for the lid, otherwise leave a blank edge
    if (addLid) {
      translate([-uDivLX*fingerLidW/2, bZ/2-thick, 0])
        insideCuts(length=bX, fWidth=fingerLidW, cutD=thick, uDiv=uDivLX);
    }
    translate([-uDivX*fingerW/2, -bZ/2, 0]) 
      insideCuts(length=bX, fWidth=fingerW, cutD=thick, uDiv=uDivX);

    //Z+/- edge (Y axis in OpenSCAD)
    translate([bX/2-thick, uDivZ*fingerW/2, 0]) rotate([0, 0, -90])
      insideCuts(length=bZ, fWidth=fingerW, cutD=thick, uDiv=uDivZ);
    translate([-bX/2, uDivZ*fingerW/2, 0]) rotate([0, 0, -90])
      insideCuts(length=bZ, fWidth=fingerW, cutD=thick, uDiv=uDivZ);

    translate([supXpos, 0, 0]) rotate([0, 0, -90])
      //supportPunch(length=bZ, fWidth=fingerW, cutD=thick, uDiv=uDivZ); 
      holePunch(length=bZ, uDiv=uDivZ, Q=isRatioZ);

    /*
    translate([bX/2-thick, -bZ/2+fingerW*2, 0]) 
      rotate([0, 0, -90])
      lidCatch(project=true, boltHole=false);
    translate([-bX/2+thick, -bZ/2+fingerW*2, 0]) 
      rotate([0, 0, 90])
      lidCatch(project=true, boltHole=false);
    */
 }
}

//Face B (X and Y dimensions)
//Lid and base
module faceB(uDivX, uDivY, uDivZ, uDivLX, uDivLY, makeLid=0) {

  //if this is the "lid" use fingerLidW dimensions instead of fingerW
  //create the local version of these variables

  uDivXloc= makeLid==1 ? uDivLX : uDivX;
  uDivYloc= makeLid==1 ? uDivLY : uDivY;
  fingerWloc= makeLid==1 ? fingerLidW : fingerW;
  lidHoleLoc= makeLid==1 ? holeDia/2 : 0;

  difference() {
    square([bX, bY], center=true);
      
    //X+/- edge
    translate([-bX/2, bY/2-thick, 0])
      outsideCuts(length=bX, fWidth=fingerWloc, cutD=thick, uDiv=uDivXloc);
    translate([-bX/2, -bY/2, 0])
      outsideCuts(length=bX, fWidth=fingerWloc, cutD=thick, uDiv=uDivXloc);

    //Y+/- edge
    translate([bX/2-thick, uDivYloc*fingerWloc/2, 0]) rotate([0, 0, -90])
      insideCuts(length=bY, fWidth=fingerWloc, cutD=thick, uDiv=uDivYloc);
    translate([-bX/2, uDivYloc*fingerWloc/2, 0]) rotate([0, 0, -90])
      insideCuts(length=bY, fWidth=fingerWloc, cutD=thick, uDiv=uDivYloc);

    //add holes for support
    if (makeLid==0) {
      translate([supXpos, 0, 0]) rotate([0, 0, -90])
//        supportPunch(length=bY, fWidth=fingerW, cutD=thick, uDiv=uDivY);
      holePunch(length=bZ, uDiv=uDivY, Q=isRatioY);
    
      //punch holes for microswitch support
      //translate([(mswY/2+thick/2), mswYpos, 0])
      translate([(mswY/2+thick/2), swYsup, 0])
        rotate([0, 0, -90])
        holePunch(length=bY/ssRatio, uDiv=uDivY, Q=ssRatio);
      
      // add holes in the base for catches
      for (i=[ [-1, 1], [1, 1], [1, -1], [-1, -1] ] ) {
        translate([i[0]*(bX/2-thick/2-thick*2), i[1]*(bY/2-fingerW/2-thick-fingerLidW/2), 0]) 
        rotate([0, 0, 90])
          lidCatch(project=true, tab=true); 
      }


    } else {
      //Add lid features
      //switch hole with holeFacets sides
      translate([switchX, switchY, 0])
        circle(r=lidHoleLoc);

      //armHole
      translate([0, bY/2-armHY/2-armFromYEdge, 0])
        armHole();
      //add hinge holes
      translate([0, bY/2-hingeX/2-armFromYEdge/2-armHBorder, 0]) rotate([0, 0, 90]) 
        hinge(project=true);

      //add holes for catch tabs
      for (i=[ [-1, 1], [1, 1], [1, -1], [-1, -1] ] ) {
        translate([i[0]*(bX/2-thick/2-thick), i[1]*(bY/2-fingerW/2-thick-fingerLidW/2), 0]) 
        rotate([0, 0, 90])
          lidCatch(project=true, tab=true); 
      }

      

    } //close if makelid
  
  } //close difference
  
}

//Face C (Z and Y dimensions)
//left and right sides
module faceC(uDivX, uDivY, uDivZ, uDivLX, uDivLY) {

  difference() {
    square([bY, bZ], center=true);
    
    //Y+/- edge (X axis in OpenSCAD)
    //make cuts for the lid or leave a straight edge
    if(addLid) {
      translate([-bY/2, bZ/2-thick, 0])
        outsideCuts(length=bY, fWidth=fingerLidW, cutD=thick, uDiv=uDivLY);  
    }
    translate([-bY/2, -bZ/2, 0])
      outsideCuts(length=bY, fWidth=fingerW, cutD=thick, uDiv=uDivY);

    //Z+/- edge (Y axis in OpenSCAD)
    translate([bY/2-thick, bZ/2, 0]) rotate([0, 0, -90])
      outsideCuts(length=bZ, fWidth=fingerW, cutD=thick, uDiv=uDivZ);
    translate([-bY/2, bZ/2, 0]) rotate([0, 0, -90])
      outsideCuts(length=bZ, fWidth=fingerW, cutD=thick, uDiv=uDivZ);

    if (lidCatch==1) {
      translate([bY/2-fingerW/2-thick-fingerLidW/2, bZ/2-thick])
        lidCatch(project=true, boltHole=false);
      translate([-1*(bY/2-fingerW/2-thick-fingerLidW/2), bZ/2-thick])
        lidCatch(project=true, boltHole=false);

      translate([bY/2-fingerW/2-thick-fingerLidW/2, -1*(bZ/2-thick)])
        rotate([180, 0, 0])
        lidCatch(project=true, boltHole=false);
      translate([-1*(bY/2-fingerW/2-thick-fingerLidW/2), -1*(bZ/2-thick)])
        rotate([180, 0, 0])
        lidCatch(project=true, boltHole=false);
    }
      
    //add holes for catch tabs
    /*
    for (i=[ [1, -1], [-1, -1] ] ) {
      #translate([i[0]*(bY/2-thick/2-2*thick), i[1]*(bZ/2-fingerW/2-2*thick), 0]) 
        rotate([0, 0, 90])
       lidCatch(project=true, tab=true); 
    }
    */

  }
}


module internalSupport(uDivY, uDivZ) {
  qZ=isRatioZ;
  qY=isRatioY;
  // long internal support to hold the Servo, circuit board
  uDivLocY= (floor(uDivY/qY)%2)==0 ? floor(uDivY/qY)-1 : floor(uDivY/qY);
  uDivLocZ= (floor(uDivZ/qZ)%2)==0 ? floor(uDivZ/qZ)-1 : floor(uDivZ/qZ);
  difference() {

    // reuse FaceC, but with less fingers

    square([bY, bZ], center=true);
    //outsideCuts(length=bY/Q, fwidth=fingerW, cutD=thick, uDiv=uDivLocY);
    translate([bY/2-thick, bZ/2, 0])
      rotate([0, 0, -90])
      outsideCuts(length=bZ, fWidth=fingerW, cutD=thick, uDiv=uDivLocZ);
    translate([-bY/2, bZ/2, 0])
      rotate([0, 0, -90])
      outsideCuts(length=bZ, fWidth=fingerW, cutD=thick, uDiv=uDivLocZ);
    translate([-bY/2, -bZ/2, 0])
      rotate([0, 0, 0])
      outsideCuts(length=bY, fWidth=fingerW, cutD=thick, uDiv=uDivLocY);
    //remove the top tabs alltogether
    translate([0, bZ/2-thick/2, 0])
      square([bY, thick], center=true);
    // Cut a hole for the servo 
    placeServo2D();
    placeBoard2D();
    //make a hole in the support for wires.  Why not make it awesome?
    translate([holeY, holeZ, 0])
      scale(holeScale) import(file=holeFile);
      //circle(r=7.5, center=true);

    placeZipTies2D();



  }
}

module switchSupport(uDiv, holeZ=5, holeD=3.6) {
  // support to hold the microswitch under the arm 
  Q=ssRatio;
  uDivLoc= (floor(uDiv/Q)%2)==0 ? floor(uDiv/Q)-1 : floor(uDiv/Q);
  
  ssY=bY/Q; //length of support = boxY/Q
  // add twice the hole diameter to be cut to make strong enough
  // add thick to make the fingers

  //changing this to accomodate a different style switch
  //ssZ=holeZ+holeD*2.5+thick; 
  //FIXME kludge to handle different style switch - add topHOle into a paramater?
  ssZ=holeZ+holeD*4.5+thick; 
  topHole=9.9;


  //FIXME this translate is a kludge to make the 3D layout easier
  // it causes problems in the 2d layout (probably)
  translate([0, (ssZ-thick)/2, 0])
  difference() {
    square([ssY, ssZ], center=true);
    translate([(-bY/Q/2), -(ssZ)/2, 0,])
      outsideCuts(length=bY/Q, fWidth=fingerW, cutD=thick, uDiv=uDivLoc);
    translate([0, -ssZ/2+thick+mswZpos, 0])
      square([ssY*.8-holeD, holeD], center=true);
    translate([(-ssY*.8)/2+holeD/2, (-ssZ/2+thick+mswZpos), 0])
      circle(r=holeD/2, $fn=36);
    translate([(ssY*.8)/2-holeD/2, (-ssZ/2+thick+mswZpos), 0])
      circle(r=holeD/2, $fn=36);
    // top hole
    translate([0, -ssZ/2+thick+mswZpos+topHole, 0])
      square([ssY*.8-holeD, holeD], center=true);
    translate([(-ssY*.8)/2+holeD/2, (-ssZ/2+thick+mswZpos)+topHole, 0])
      circle(r=holeD/2, $fn=36);
    translate([(ssY*.8)/2-holeD/2, (-ssZ/2+thick+mswZpos)+topHole, 0])
      circle(r=holeD/2, $fn=36);
   }

}

module doorJamb() {
  djX=doorJX-2*cornerR;
  djY=doorJY-2*cornerR;
  hull() {
    translate([djX/2, djY/2])
      circle(r=cornerR, $fn=36);
    translate([-djX/2, djY/2])
      circle(r=cornerR, $fn=36);
    translate([-djX/2, -djY/2])
      circle(r=cornerR, $fn=36);
    translate([djX/2, -djY/2])
      circle(r=cornerR, $fn=36);
    square([djX, djY], center=true);
  }
}


module catch3D() {
  rotate([90, 0, 90])
  translate([0, 0, thick/2])
    color("purple") linear_extrude(height=thick) lidCatch(boltHole=false);
  rotate([90, 0, 90])
  translate([0, 0, -thick/2])
    color("red") linear_extrude(height=thick) lidCatch(boltHole=true);
}

module placeCatch2D() {
  xDisp=catch+cornerR*2;
  for (i=[0:3]) {
    translate([i*(xDisp*2+separation*2), 0])
      lidCatch();
    translate([i*(xDisp*2+separation*2)+xDisp+separation, 0])
      lidCatch(boltHole=false);
  }
}

module placeCatch3D() {
  //catches on lid
  translate([bX/2-thick*2.5, bY/2-fingerW/2-fingerLidW/2-thick, bZ-thick*1.5])
    catch3D();
  translate([(bX/2-thick*2.5), -1*(bY/2-fingerW/2-fingerLidW/2-thick), bZ-thick*1.5])
    catch3D();
  translate([-1*(bX/2-thick*2.5), bY/2-fingerW/2-fingerLidW/2-thick, bZ-thick*1.5]) 
    rotate([0, 0, -180])
    catch3D();
  translate([-1*(bX/2-thick*2.5), -1*(bY/2-fingerW/2-fingerLidW/2-thick), bZ-thick*1.5]) 
    rotate([0, 0, -180])
    catch3D();

  //catches on base
  translate([bX/2-thick*3.5, bY/2-fingerW/2-fingerLidW/2-thick, thick/2])
    rotate([180, 0, 0])
    catch3D();
  translate([(bX/2-thick*3.5), -1*(bY/2-fingerW/2-fingerLidW/2-thick), thick/2])
    rotate([180, 0, 0])
    catch3D();
  translate([-1*(bX/2-thick*3.5), bY/2-fingerW/2-fingerLidW/2-thick, thick/2]) 
    rotate([180, 0, -180])
    catch3D();
  translate([-1*(bX/2-thick*3.5), -1*(bY/2-fingerW/2-fingerLidW/2-thick), thick/2]) 
    rotate([180, 0, -180])
    catch3D();

  echo(thick);


// translate([-1*(bX/2-thick), bY/2-thick*3.5, fingerW/2+1.5*thick])
//    rotate([-90, 0, 90])
//    catch3D(); 
}

module layout2D(uDivX, uDivY, uDivZ, uDivLX, uDivLY) {
  //handle layout more intelegently by using the larger of the two values
  yDisplace= bY>bZ ? bY : bZ+separation;
 
  //The layout is a total cluster bang.  
  //Additive layout format revision; use variables: Column, Element, name:
  //c0e0x=0; c0e0y=0; etc.

  //Column 0

  c0e0x=0;
  c0e0y=0;
  //XZ face c0e0
  translate([c0e0x, c0e0y, 0])
    color("red") faceA(uDivX, uDivY, uDivZ, uDivLX, uDivLY);

  c0e1x=0;
  c0e1y=c0e0x-bZ/2-bY/2-separation;
  if (addLid) {
    //Lid c0e1
    translate([c0e1x, c0e1y, 0])
      color("lime") faceB(uDivX, uDivY, uDivZ, uDivLX, uDivLY, makeLid=1);
  }

  c0e2x=c0e1x-catch*5.5-separation*4.5;
  c0e2y=c0e1y-bY/2-thick-separation;
  //lid catch 1 c0e2
    translate([c0e2x, c0e2y, 0])
      color("royalblue") placeCatch2D();
  
  c0e3x=c0e2x;
  c0e3y=c0e2y-thick*2-catch-separation;
  //lid catch 2 c0e3
    translate([c0e3x, c0e3y, 0])
      color("royalblue") placeCatch2D();

  c0e4x=c0e3x;
  c0e4y=c0e3y-thick*2-catch-separation;

  //lid catch3 c0e4
    translate([c0e4x, c0e4y, 0])
      color("royalblue") placeCatch2D();

  c0e5x=c0e4x;
  c0e5y=c0e4y-thick*2-catch-separation;
  //lidCatch4 c0e5
    translate([c0e5x, c0e5y, 0])
      color("royalblue") placeCatch2D();


  c0e6x=0;
  c0e6y=c0e5y-separation-(brdBlt+4)*2;
  //microswitch support c0e5
  //usable divisions, bY/Q to use for support size, dividerZ over bottom
  translate([c0e6x, c0e6y, 0])
    rotate([0, 0, 180])
    color("indigo")
    switchSupport(uDivY, holeZ=mswZpos); 

  //FIXME - better positioning
  c0e7x=0;
  c0e7y=c0e6y-14-separation-doorJX/2;
  translate([c0e7x, c0e7y, 0])
    color("lime")
    doorJamb();

  //Column 1

  c1e0x=bX/2+bY/2+separation;
  c1e0y=0;

  //YZ face c1e0
  translate([c1e0x, c1e0y, 0])
    color("blue") faceC(uDivX, uDivY, uDivZ, uDivLX, uDivLY);

  c1e1x=c1e0x;
  c1e1y=-yDisplace;
  //yZ face c1e1
  translate([c1e1x, c1e1y, 0])
    color("darkblue") faceC(uDivX, uDivY, uDivZ, uDivLX, uDivLY);

  c1e2x=c1e1x;
  c1e2y=c1e1y-bZ-separation;
  //YZ support for servo c1e2
  translate([c1e2x, c1e2y, 0])
    color("olive") internalSupport(uDivY, uDivZ);

  // Column 2
  c2e0x=c1e0x+bY/2+bX/2+separation;
  c2e0y=0;
  //XZ Face c2e0
  translate([c2e0x, c2e0y, 0]) rotate([0, 180, 0])
    color("darkred") faceA(uDivX, uDivY, uDivZ, uDivLX, uDivLY);
  
  c2e1x=c2e0x;
  c2e1y=c2e0y-bZ/2-bY/2-separation;
  //XY Face - Bottm c2e
  translate([c2e1x, c2e1y, 0])
  rotate([0, 180, 0])
    color("green") faceB(uDivX, uDivY, uDivZ, uDivLX, uDivLY, makeLid=0);

  c2e2x=c2e1x+10;
  c2e2y=c2e1y-bY/2-separation-20;
  //arm assembly c2e2
  translate([c2e2x, c2e2y, 0])
    color("purple") placeArm2D();

/*
  c2e3x=c2e2x;
  c2e3y=c2e2y-90;
  //Scale marker c2e3
  translate([c2e3x, c2e3y, 0])
    scale2D(20, 20);
*/

  c2e3x=c2e2x-(-brdBlt-4-separation)*1.5;
  c2e3y=c2e2y-55-separation-(brdBlt+4)*2;
  //board standoffs c0e4 
  translate([c2e3x, c2e3y, 0])
    color("slateblue") boardStandOff(r=2, c=4);

 

  c2e4x=c2e3x;
  c2e4y=c2e3y-40;
  translate([c2e4x, c2e4y, 0])
    text(VERSION, 20);



  }


module layout3D(uDivX, uDivY, uDivZ, uDivLX, uDivLY, alp=0.5) {
  //amount to shift for cut depth 
  D=thick/2;

  //bottom of box (B-)

  color("green", alpha=alp)
    translate([0, 0, 0])
    linear_extrude(height=thick, center=true) faceB(uDivX, uDivY, uDivZ, uDivLX, 
      uDivLY, makeLid=0);


  if (addLid) {
    color("lime", alpha=alp)
      translate([0, 0, bZ-thick])
      linear_extrude(height=thick, center=true) faceB(uDivX, uDivY, uDivZ, uDivLX, 
        uDivLY, makeLid=1);
  }

/*
  color("red", alpha=alp)
    translate([0, bY/2-D, bZ/2-D]) rotate([90, 0, 0])
    linear_extrude(height=thick, center=true) faceA(uDivX, uDivY, uDivZ, uDivLX, 
      uDivLY);
*/

  color("darkred", alpha=alp)
    translate([0, -bY/2+D, bZ/2-D]) rotate([90, 0, 0])
    linear_extrude(height=thick, center=true) faceA(uDivX, uDivY, uDivZ, uDivLX, 
      uDivLY);

/*
  color("blue", alpha=alp)
    translate([bX/2-D, 0, bZ/2-D]) rotate([90, 0, 90])
    linear_extrude(height=thick, center=true) faceC(uDivX, uDivY, uDivZ, uDivLX, 
      uDivLY);

/*
  color("darkblue", alpha=alp)
    translate([-bX/2+D, 0, bZ/2-D]) rotate([90, 0, 90])
    linear_extrude(height=thick, center=true) faceC(uDivX, uDivY, uDivZ, uDivLX, 
      uDivLY);
*/

  color("olive", alpha=1)
    translate([supXpos, 0, bZ/2-D]) rotate([90, 0, 90])
      linear_extrude(height=thick, center=true) internalSupport(uDivY, uDivZ);

  placeServo3D();

  placeSwitch3D();

  placeHinge3D();

  placeCatch3D();

  //placeBattery3D();

  placeArm3D();

  placeBoard3D();

  // place switch support
  color("indigo")
    translate([(mswY/2+thick/2), swYsup, 0])
    rotate([90, 0, 90])
    linear_extrude(height=thick, center=true)
    switchSupport(uDivY,, holeZ=mswZpos); 


  placeMicSwitch3D();
}

module placeServo3D() {
  translate([serX-armThick/2, serY, serZ])
  rotate([90, 0, 90]) translate([0, -thick/2, 0]) 
    servo(center="shaft", horn=true);
}

module placeServo2D() {
  translate([serY, -bZ/2+serZ, 0])
    servo(bolt=false, project=true, center="shaft", scalePct=1.05);
}


module placeSwitch3D() {
  translate([switchX, switchY, bZ-thick/2-thick]) rotate([0, 0, 90])
    switch(nut1H=0, nut2H=thick, center="nut");
}

module placeHinge3D() {
  color("orange") 
    translate([0, bY/2-hingeX/2-armFromYEdge/2-armHBorder, bZ-thick/2]) rotate([0, 0, 90])
    hinge();
  
}

module placeBattery3D() {
  translate([batY/2+supXpos+thick/2+batPosX, -bY/2+batZ/2+thick+batPosY, 
    batX/2+thick/2+batPosZ])
    rotate([-90, 90, 90])
    battery_pack();
}

module placeArm3D() {
  // Two levels of rotate - the first situates the arm on the axis, the other
  // controls the rotation at the servo 
  translate([0, serY, serZ-thick/2])
  rotate([armRot+armRotAnim, 0, 0])
    rotate([0, -90, 180])
  union() {
    color("purple")
      linear_extrude(height=thick, center=true, convexity=10)
      import (file =armFile);

    translate([9.12+thick/2, -57.297, 0])
      rotate([90, 90, 90])
      color("plum")
      linear_extrude(height=thick, center=true, convexity=10)
      import (file =headFile);
  }
  
}

module placeArm2D() {
  import (file=armFile);
  translate([0, -30, 0])
  difference() {
    import (file=headFile);
    square([thick, 5.15], center=true);
  }
}

module placeBoard3D() {
  translate([supXpos-brdZ/2-thick/2, brdYpos, brdZpos+bZ/2-thick/2])
  color("yellow")
      rotate([0, 90, 0])    
    linear_extrude(height=brdZ, center=true)
      difference() {
        square([brdX, brdY], center=true);
        import (file=brdFile);
      }
}

module placeBoard2D() {
  translate([brdYpos, brdZpos, 0])
    rotate([0, 0, 90])
    import (file=brdFile);
}


module placeMicSwitch3D() {
  translate([mswXpos, mswYpos, mswZpos+thick/2])
    rotate([0, 0, 90])
    //micro_switch();
    micro_switch_var();
}


module placeZipTies2D() {
  for (i=[0:len(zTieLoc)-1]) {
    translate([zTieLoc[i][0], zTieLoc[i][1], zTieLoc[i][2]])
      rotate([0, 0, zTieLoc[i][3]])
      zipTie();
  }
}

module main() {

    
  //Calculate the maximum number of fingers and cuts possible
  maxDivX=floor(bX/fingerW);
  maxDivY=floor(bY/fingerW);
  maxDivZ=floor(bZ/fingerW);

  //Calculate the max number of fingers and cuts for the lid
  maxDivLX=floor(bX/fingerLidW);
  maxDivLY=floor(bY/fingerLidW);

  //the usable divisions value must be odd for this layout
  uDivX= (maxDivX%2)==0 ? maxDivX-3 : maxDivX-2;
  uDivY= (maxDivY%2)==0 ? maxDivY-3 : maxDivY-2;
  uDivZ= (maxDivZ%2)==0 ? maxDivZ-3 : maxDivZ-2;
  uDivLX= (maxDivLX%2)==0 ? maxDivLX-3 : maxDivLX-2;
  uDivLY= (maxDivLY%2)==0 ? maxDivLY-3 : maxDivLY-2;


  if(2D) {
    layout2D(uDivX, uDivY, uDivZ, uDivLX, uDivLY);
  } else {
    layout3D(uDivX, uDivY, uDivZ, uDivLX, uDivLY, alp);
  }


}

rotate([0, 0, $t*-360]) {
    main();
}

