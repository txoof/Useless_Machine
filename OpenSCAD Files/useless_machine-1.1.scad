/*
Useless Machine!


V1.1 13 November 2014
  * merged in improved 2D layout from finger_joint 3.1
  * improved kerf handling

V1.0 12 November 2014

TODO
  * widen box? - added Z+10mm to accomodate switch
  * Add labels to all plates - do this in 2D Design
  * consider switching to bolt holes for servo mount over screws
  * remove lid catch holes punched in middle support
  * make a plan for plating out and testing fits
  * rewrite the support punch sub; something more general 
  * clean up lid catch

DONE
  X cut a hole in the support board for wires
  X punch holes in bottom face for switch support
  X make standoffs for electronics board 
  X Measure microswitch and place properly
  X Develop system for mounting microswtich
  X Fix rediculous variables and placement of Servo in 3D and 2D
  X flip around latches - nut should be on inside to prevent it pulling out
  X flip over dark red plate so illustrations are on OUTSIDE
  X double check motor placement
  X add electronics mount 
  X add hole for switch in lid
  X  add door in lid - add screw holes for hinges
  X add catch for lid 
    - MBI style bolts? Add a few mm to corner tabs to facilitate (see Maker Bot front)
    -Z tabs that extend downward from lid with nuts set into them?
*/

use <./libraries/futabaS3004.scad>
use <./libraries/toggle_switch.scad>
use <./libraries/stardard_hinge.scad>
use <./libraries/micro_switch.scad>
use <./libraries/4AA_battery.scad>
use <../libraries/scale.scad>


/*[Box Outside Dimensions]*/
//Box Width - X
bX=110;
//Box Depth - Y
bY=150;
//Box Height - Z
bZ=110; //100 -testing adjustments for microswtich
//Material Thickness
thick=3.8;
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
lidBolt=3; //metric bolt size for sizing nut

/*[Finger Width]*/
//Finger width (NB! width must be < 1/3 shortest side)
fingerW=5;//[3:20]
//Lid finger width 
fingerLidW=36;//[3:20]

/*[Layout]*/
//separation of finished pieces
separation=1;
//transparency of 3D model
alpha=80; //[1:100]
2D=1; //[1:2D for DXF, 0:3D for STL]

/*[Internal Support]*/
//horn to bottom of flange 17.6, armThickness=thickness of arm material
supXpos=-thick/2-17.6-armThick/2;

/*[Servo Position]*/
//placement

serY=-10; //-9 //was X
serZ=79; //50.5  //was Y
//shift the servo over the thicknes/2 of the arm to center the moving arm 
serX=-armThick/2; //was Z

/*[Arm]*/
armRot=11;
armRotAnim=$t*110; // rotate to +105 to see switch fliping position

/*[Switch]*/
switchX=0;
switchY=-48.5;
swtichZ=0;
switchDia=12;
holeDia=switchDia;

/*[Arm Hole]*/
//size
armHX=35;
armHY=50;
armFile="./libraries/arm_rv1.dxf";
headFile="./libraries/pusher_head_rv1.dxf";


//border to remove around hole opening to allow smooth open/close
armHBorder=thick/4;
//position
armFromYEdge=17;
armYpos=40; 
armXpos=0;

/*[Hinge Dimensions]*/
hingeX=15.3;
hingeY=18.2;


/*[Battery Pack]*/
//dimensions - useful for calculations below
batX=58.5; 
batY=64;
batZ=16;

/*[Driver Board]*/
//Driver Board dimensions
brdX=66;
brdY=40;
brdZ=10;
brdFile="./libraries/driver_board_rv1.dxf";
//position
brdXpos=0;
brdYpos=-48;
brdZpos=0;
//mounting bolt diameter (m size)
brdBlt=3;

/*[Micro Switch]*/
//Dimensions of switch 
mswX=20;
mswY=6.1;
mswZ=14;
mswXpos=0;
mswYpos=8;
//FIXME consider adjusting this if the microswitch does not fit properly
mswZpos=13.5; // was 8
//bY/supRatio to determines the length of the switch support
supRatio=2;

/*[Decorations :)]*/
ravenFile="./libraries/raven_rv1.dxf";

/*[Hidden]*/
//transparency alpha
alp=1-alpha/100;

//Catch Dimensions
cornerR=1; //corner radius of rounded supports
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
        hull(center=true) {
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
          circle(r=outRad, center=true, $fn=36);
          circle(r=inRad, center=true, $fn=36);
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
module holePunch(length, uDiv) {
  Q=supRatio;
  divLoc = (floor(uDiv/Q)%2)==0 ? floor(uDiv/Q)-1 : floor(uDiv/Q);
  
  numCuts=floor(divLoc/2);
  
  locLength=bY/Q; //length of support = boxY/Q
  endCut=(locLength-divLoc*fingerW)/2;
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



//Face A (X and Z dimensions)
//Front and back face
module faceA(uDivX, uDivY, uDivZ, uDivLX, uDivLY) {
  difference() {
    square([bX, bZ], center=true);

    //X+/- edge (X axis in OpenSCAD)
    //if true, make cuts for the lid, otherwise leave a blank edge
    if (addLid) {
      translate([-uDivLX*fingerLidW/2, bZ/2-thick, 0])
        insideCuts(len=bX, fWidth=fingerLidW, cutD=thick, uDiv=uDivLX);
    }
    translate([-uDivX*fingerW/2, -bZ/2, 0]) 
      insideCuts(length=bX, fWidth=fingerW, cutD=thick, uDiv=uDivX);

    //Z+/- edge (Y axis in OpenSCAD)
    translate([bX/2-thick, uDivZ*fingerW/2, 0]) rotate([0, 0, -90])
      insideCuts(length=bZ, fWidth=fingerW, cutD=thick, uDiv=uDivZ);
    translate([-bX/2, uDivZ*fingerW/2, 0]) rotate([0, 0, -90])
      insideCuts(length=bZ, fWidth=fingerW, cutD=thick, uDiv=uDivZ);

    //TODO cludged this to move down 2*fingerW (removed 4 divisions 
    // from uDivX in supportPunch)
    translate([supXpos, bZ/2-2*fingerW, 0]) rotate([0, 0, -90])
      supportPunch(length=bZ, fWidth=fingerW, cutD=thick, uDiv=uDivZ); 

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
      translate([supXpos, bY/2-2*fingerW, 0]) rotate([0, 0, -90])
        supportPunch(length=bY, fWidth=fingerW, cutD=thick, uDiv=uDivY);
     
      //punch holes for microswitch support
      //supportPunch(length=bY/supRatio, fWidth=fingerW, cutD=thick, uDiv=13);
      translate([(mswY/2+thick/2), mswYpos+bY/supRatio/2, 0])
        rotate([0, 0, -90])
        holePunch(bY/supRatio, uDivY);

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

    //TODO - catch holes punched into internal support; fix this
    if (lidCatch==1) {
      translate([bY/2-fingerW/2-thick-fingerLidW/2, bZ/2-thick])
        lidCatch(project=true, boltHole=false);
      translate([-1*(bY/2-fingerW/2-thick-fingerLidW/2), bZ/2-thick])
        lidCatch(project=true, boltHole=false);
    }
      

  }
}

module internalSupport(uDivX, uDivY, uDivZ, uDivLX, uDivLY) {
  // long internal support to hold the Servo, circuit board
  difference() {

    // reuse FaceC, but with less fingers
    faceC(uDivX-4, uDivY-4, uDivZ-4, uDivLX, uDivLX);
    //remove the top tabs alltogether
    translate([0, bZ/2-thick/2, 0])
      square([bY, thick], center=true);
    // Cut a hole for the servo 
    placeServo2D();
    placeBoard2D();
    //make a hole in the support for wires.  Why not make it awesome?
    translate([0, -bZ/4, 0])
      import(file=ravenFile);
      //circle(r=7.5, center=true);

  }
}

module switchSupport(uDiv, Q=3, holeZ=5, holeD=2.5) {
  // support to hold the microswitch under the arm 
  uDivLoc= (floor(uDiv/Q)%2)==0 ? floor(uDiv/Q)-1 : floor(uDiv/Q);
  
  ssY=bY/Q; //length of support = boxY/Q
  // add twice the hole diameter to be cut to make strong enough
  // add thick to make the fingers
  ssZ=holeZ+holeD*2.5+thick;

  //FIXME this translate is a kludge to make the 3D layout easier
  // it causes problems in the 2d layout (probably)
  translate([0, (ssZ-thick)/2, 0])
  difference() {
    square([ssY, ssZ], center=true);
    translate([(-bY/Q/2), -(ssZ)/2, 0,])
      outsideCuts(length=bY/Q, fWidth=fingerW, cutD=thick, uDiv=uDivLoc);
    translate([0, -ssZ/2+thick+mswZpos, 0])
      square([ssY*.75-holeD, holeD], center=true);
    translate([(-ssY*.75)/2+holeD/2, (-ssZ/2+thick+mswZpos), 0])
      circle(r=holeD/2, center=true, $fn=36);
    translate([(ssY*.75)/2-holeD/2, (-ssZ/2+thick+mswZpos), 0])
      circle(r=holeD/2, center=true, $fn=36);
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
  
}

module layout2D(uDivX, uDivY, uDivZ, uDivLX, uDivLY) {
  //handle layout more intelegently by using the larger of the two values
  yDisplace= bY>bZ ? bY : bZ+separation;
  
  translate([])
    color("red") faceA(uDivX, uDivY, uDivZ, uDivLX, uDivLY);

  translate([bX+separation+bY+separation, 0, 0]) rotate([0, 180, 0])
    color("darkred") faceA(uDivX, uDivY, uDivZ, uDivLX, uDivLY);

  translate([bX/2+bY/2+separation, 0, 0])
    color("blue") faceC(uDivX, uDivY, uDivZ, uDivLX, uDivLY);
  //Bottom Row
  translate([bX/2+bY/2+separation, -yDisplace, 0])
    color("darkblue") faceC(uDivX, uDivY, uDivZ, uDivLX, uDivLY);

  if (addLid) {
    translate([0, -bZ/2-bY/2-separation, 0])
      color("lime") faceB(uDivX, uDivY, uDivZ, uDivLX, uDivLY, makeLid=1);
  }
  translate([bX+separation+bY+separation, -bZ/2-bY/2-separation, 0])
    color("green") faceB(uDivX, uDivY, uDivZ, uDivLX, uDivLY, makeLid=0);

  //FIXME unsure what the final paramater of "1" does here 
  translate([bX/2+bY/2+separation, -yDisplace-bZ-separation, 0])
    color("olive") internalSupport(uDivX, uDivY, uDivZ, uDivLX, 1);

  //arm assembly
  translate([bX+separation+bY+separation+fingerW, -bZ/2-bY-separation-20, 0])
    color("purple") placeArm2D();

  translate([bX+separation+bY+separation+fingerW, -bZ/2-bY-separation-110, 0])
    scale2D(20, 20);

  //lid catch
    translate([-catch*4.5-separation*3.5, -bZ/2-bY-thick-separation*3, 0])
      color("royalblue") placeCatch2D();
    translate([-catch*4.5-separation*3.5, -bZ/2-bY-thick*3-separation*4-catch, 0])
      color("royalblue") placeCatch2D();


  //board standoffs 
  translate([(-brdBlt-4-separation)*1.5, 
    -bZ/2-bY-thick*3-separation*5-catch-(brdBlt+4)*2, 0])
    color("slateblue") boardStandOff(r=2, c=4);

  //usable divisions, bY/Q to use for support size, dividerZ over bottom
  translate([0, -bZ/2-bY-thick*3-separation*6-catch-(brdBlt+4)*4, 0])
    rotate([0, 0, 180])
    color("indigo")
    switchSupport(uDivY, Q=supRatio, holeZ=mswZpos); 
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


  color("red", alpha=alp)
    translate([0, bY/2-D, bZ/2-D]) rotate([90, 0, 0])
    linear_extrude(height=thick, center=true) faceA(uDivX, uDivY, uDivZ, uDivLX, 
      uDivLY);


  color("darkred", alpha=alp)
    translate([0, -bY/2+D, bZ/2-D]) rotate([90, 0, 0])
    linear_extrude(height=thick, center=true) faceA(uDivX, uDivY, uDivZ, uDivLX, 
      uDivLY);

/*
  color("blue", alpha=alp)
    translate([bX/2-D, 0, bZ/2-D]) rotate([90, 0, 90])
    linear_extrude(height=thick, center=true) faceC(uDivX, uDivY, uDivZ, uDivLX, 
      uDivLY);
*/

  color("darkblue", alpha=alp)
    translate([-bX/2+D, 0, bZ/2-D]) rotate([90, 0, 90])
    linear_extrude(height=thick, center=true) faceC(uDivX, uDivY, uDivZ, uDivLX, 
      uDivLY);


  color("olive", alpha=1)
    translate([supXpos, 0, bZ/2-D]) rotate([90, 0, 90])
      linear_extrude(height=thick, center=true) internalSupport(uDivX, uDivY, uDivZ,
        uDivLX, uDivLY);

  placeServo3D();

  placeSwitch3D();

  placeHinge3D();

  placeCatch3D();

  placeBattery3D();

  placeArm3D();

  placeBoard3D();


  color("indigo")
    translate([(mswY/2+thick/2), mswYpos, 0])
    rotate([90, 0, 90])
    linear_extrude(height=thick, center=true)
    switchSupport(uDivY, Q=supRatio, holeZ=mswZpos); 


  placeMicSwitch3D();
}

module placeServo3D() {
  translate([serX, serY, serZ])
  rotate([90, 0, 90]) translate([0, -thick/2, 0]) 
    futaba(center="shaft", horn=true);
}

module placeServo2D() {
  translate([serY, -bZ/2+serZ, 0])
    futaba(bolt=false, project=true, center="shaft", scalePct=1.0);
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
  //FIXME kludge in +5 to make some space between the support
  translate([batY/2+supXpos+thick/2+5, -bY/2+batZ/2+thick, batX/2+thick/2])
    rotate([-90, 90, 0])
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
      linear_extrude(height=thick, center=true, convexivity=10)
      import (file =armFile);

    translate([9.12+thick/2, -57.297, 0])
      rotate([90, 90, 90])
      color("green")
      linear_extrude(height=thick, center=true, covexivity=10)
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
//  translate([brdXpos+supXpos-brdZ/2-thick/2, brdYpos, brdZpos+brdY/2+brdZ])
  translate([supXpos-brdZ/2-thick/2, brdYpos, brdZpos+bZ/2-thick/2])
  color("yellow")
//    rotate([90, 90, 90])
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
    rotate([0, 0, -90])
    micro_switch();
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
    layout3D(uDivX, uDivY, uDivZ, uDivLX, uDivLY);
  }


}

main();

