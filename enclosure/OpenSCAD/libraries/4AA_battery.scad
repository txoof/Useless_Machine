/*
 4x AA battery pack
 6V battery pack
*/

/*[body]*/
bX=58.5;
bY=64;
bZ=16;
//wire outlet
wX=8;
wY=2;
wZ=4;
wireFromEdge=12;

module body() {
  union() {
    cube([bX, bY, bZ], center=true);  
    translate([bX/2-wX/2-wireFromEdge, bY/2+wY/2, -bZ/2+wZ/2])
      cube([wX, wY, wZ], center=true);
  }
}


module battery_pack() {
  color("orange")
    translate([0, 0, 0])
    body();
}

batery_pack();
