// AS5600 Bench Test Jig
// Two parts: board_holder + magnet_post
// Print board_holder upside-down (top plate on build plate).
// Print magnet_post arm-side down (arm flat on build plate).

$fn = 60;

// ── Board dimensions ──────────────────────────────────────────────
board_w       = 23;     // PCB width
board_d       = 23;     // PCB depth
board_h       = 1.6;    // PCB thickness
chip_h        = 1.0;    // AS5600 package height above PCB top
chip_cx       = 11.5;   // chip center X from PCB corner (assumed centered)
chip_cy       = 11.5;   // chip center Y from PCB corner

// Mounting holes: M2, 2mm inset from each corner edge → 19×19mm pitch
hole_d        = 2.0;
hole_inset    = 2.0;
peg_d         = 1.85;   // alignment peg diameter (press-fit into M2 hole)
peg_h         = 2.5;

// ── Holder geometry ───────────────────────────────────────────────
wall_t        = 2.0;    // corner post wall thickness
inner_clear   = 0.4;    // total clearance around PCB (0.2mm per side)
inner_w       = board_w + inner_clear;
inner_d       = board_d + inner_clear;

ledge_t       = 1.0;    // ledge width that PCB rests on
ledge_z       = 3.0;    // ledge height from holder bottom (breadboard clearance)

// Height stack: ledge_z + board_h + chip_h + clearance → top plate bottom
chip_clearance     = 0.5;
top_plate_bottom_z = ledge_z + board_h + chip_h + chip_clearance;  // 6.1
top_plate_t        = 2.5;
top_plate_top_z    = top_plate_bottom_z + top_plate_t;              // 8.6
holder_h           = top_plate_top_z;

chip_hole_d   = 7.0;    // hole above AS5600 chip in top plate

clamp_slot_w  = 4.0;    // binder-clip slot on one wall
clamp_slot_d  = 2.0;

// ── Magnet post geometry ──────────────────────────────────────────
post_od       = 6.4;    // fits in 7mm hole with 0.3mm clearance per side
post_length   = 4.5;    // hangs below flange; gives 1.5mm airgap (see plan)

magnet_d      = 4.0;    // pocket diameter (press-fit for 3.97mm magnet)
magnet_depth  = 2.5;    // actual magnet height
pocket_depth  = magnet_depth + 0.5;  // 3.0mm — 0.5mm push room
eject_hole_d  = 1.0;    // through-hole above pocket for ejection pin

flange_d      = 16.0;
flange_t      = 2.5;

arm_length    = 90.0;
arm_w         = 8.0;
arm_h         = 4.0;


// ═══════════════════════════════════════════════════════════════════
// MODULE: board_holder
// Origin: bottom-left-bottom corner of the holder outer envelope.
// The PCB sits at ledge_z with its bottom face on the ledges.
// ═══════════════════════════════════════════════════════════════════
module board_holder() {
    outer_w = inner_w + 2 * wall_t;
    outer_d = inner_d + 2 * wall_t;

    difference() {
        union() {
            // ── Four L-profile corner posts ──────────────────────
            // Each post is a solid wall_t × (wall_t + ledge_t) rectangle
            // minus the open inner area above the ledge.
            // Built as: full-height outer solid - inner void above ledge.
            //
            // Simpler: four corner solids, then subtract the center void.

            // Full-height corner blocks at each corner
            for (x = [0, inner_w + wall_t], y = [0, inner_d + wall_t]) {
                translate([x, y, 0])
                    cube([wall_t, wall_t, holder_h]);
            }

            // Connect adjacent corners with thin ledge rails along each side.
            // Each rail is wall_t wide, ledge_t tall, running between posts.
            // Bottom ledge rails (PCB seat)
            translate([wall_t, 0,           ledge_z - ledge_t])
                cube([inner_w, ledge_t, ledge_t]);
            translate([wall_t, inner_d + wall_t, ledge_z - ledge_t])
                cube([inner_w, ledge_t, ledge_t]);
            translate([0,      wall_t,           ledge_z - ledge_t])
                cube([ledge_t, inner_d, ledge_t]);
            translate([inner_w + wall_t, wall_t, ledge_z - ledge_t])
                cube([ledge_t, inner_d, ledge_t]);

            // ── Top plate ────────────────────────────────────────
            translate([0, 0, top_plate_bottom_z])
                cube([outer_w, outer_d, top_plate_t]);

            // ── Clamp slot tab on front wall (Y=0 side) ──────────
            // Extra 2mm-tall wall section so a binder clip has something to grip.
            clamp_tab_h = 6.0;
            translate([outer_w/2 - clamp_slot_w/2, 0, holder_h])
                cube([clamp_slot_w, wall_t + 2, clamp_tab_h]);
        }

        // ── Chip hole in top plate ────────────────────────────────
        translate([wall_t + chip_cx, wall_t + chip_cy, top_plate_bottom_z - 0.01])
            cylinder(d = chip_hole_d, h = top_plate_t + 0.02);

        // ── Alignment peg holes in top plate (poke down onto PCB holes) ──
        // PCB mounting hole centres relative to PCB corner:
        //   (hole_inset, hole_inset), (board_w-hole_inset, hole_inset), etc.
        // In holder coords: add wall_t offset for PCB corner.
        for (px = [hole_inset, board_w - hole_inset],
             py = [hole_inset, board_d - hole_inset]) {
            translate([wall_t + px, wall_t + py, top_plate_bottom_z - 0.01])
                cylinder(d = peg_d, h = top_plate_t + peg_h + 0.02);
        }

        // ── Clamp slot cutout in tab ─────────────────────────────
        translate([outer_w/2 - clamp_slot_w/2 + (clamp_slot_w - clamp_slot_d)/2,
                   -0.01,
                   holder_h + 1.0])
            cube([clamp_slot_d, wall_t + 2 + 0.02, 4.0]);
    }

    // ── Alignment pegs (solid, point down from top plate underside) ──
    for (px = [hole_inset, board_w - hole_inset],
         py = [hole_inset, board_d - hole_inset]) {
        translate([wall_t + px, wall_t + py, ledge_z + board_h])
            cylinder(d = peg_d, h = peg_h);
    }
}


// ═══════════════════════════════════════════════════════════════════
// MODULE: magnet_post
// Origin: centre of flange bottom face.
// Post hangs downward (negative Z). Arm extends in +X direction.
// Print with arm flat on build plate (rotate 180° around X before slicing).
// ═══════════════════════════════════════════════════════════════════
module magnet_post() {
    difference() {
        union() {
            // ── Flange ───────────────────────────────────────────
            cylinder(d = flange_d, h = flange_t);

            // ── Post (hangs below flange) ─────────────────────────
            translate([0, 0, -post_length])
                cylinder(d = post_od, h = post_length);

            // ── Arm (extends from flange top, centred, +X) ───────
            translate([0, -arm_w/2, flange_t])
                cube([arm_length, arm_w, arm_h]);

            // Small chamfer block to blend arm into flange
            translate([0, -arm_w/2, flange_t])
                cube([flange_d/2, arm_w, arm_h]);
        }

        // ── Magnet pocket (blind hole at post bottom) ─────────────
        translate([0, 0, -post_length - 0.01])
            cylinder(d = magnet_d, h = pocket_depth + 0.01);

        // ── Ejection through-hole (1mm dia, from arm top down to pocket) ──
        translate([0, 0, -post_length + pocket_depth])
            cylinder(d = eject_hole_d,
                     h = post_length - pocket_depth + flange_t + arm_h + 0.02);
    }
}


// ═══════════════════════════════════════════════════════════════════
// Render — both parts side by side for reference.
// Comment out one module to isolate a single part for export/slicing.
// ═══════════════════════════════════════════════════════════════════
board_holder();

translate([50, 0, flange_t + post_length])
    rotate([180, 0, 0])
        magnet_post();
