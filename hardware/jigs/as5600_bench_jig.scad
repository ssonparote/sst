// AS5600 Bench Test Jig
// Two parts: board_holder + magnet_post
// Print board_holder upside-down (top plate on build plate).
// Print magnet_post arm-side down (arm flat on build plate).

$fn = 60;

// ── Board dimensions ──────────────────────────────────────────────
board_w          = 23;      // PCB width mm
board_d          = 23;      // PCB depth mm
board_h          = 1.75;    // PCB thickness (measured)

// Mounting holes: 3.5mm dia, hole EDGE 2mm from PCB edge
//   → hole centre is 2 + 3.5/2 = 3.75mm from each PCB edge
hole_d           = 3.5;
hole_cx_inset    = 3.75;    // hole centre distance from PCB edge
peg_d            = 3.0;     // alignment post dia (0.25mm clearance in 3.5mm hole)
peg_h            = 3.0;

// ── Height measurements — all relative to breadboard surface = z=0 ─
// (holder bottom sits on breadboard, so holder coords = absolute coords)
ledge_z          = 2.5;     // PCB bottom rests here  (4.2 - 1.75 = 2.45, rounded)
pcb_top_z        = ledge_z + board_h;   // 4.25
chip_top_z       = 6.5;                 // measured chip top above breadboard

// ── Holder geometry ───────────────────────────────────────────────
wall_t           = 2.0;
inner_clear      = 0.4;     // total XY clearance around PCB (0.2 per side)
inner_w          = board_w + inner_clear;
inner_d          = board_d + inner_clear;
outer_w          = inner_w + 2 * wall_t;
outer_d          = inner_d + 2 * wall_t;

ledge_t          = 1.0;     // ledge depth (PCB lip)

// Chip centre in holder XY coords
chip_cx          = 11.5;
chip_cy          = 11.5;
cx               = wall_t + chip_cx;    // 13.5
cy               = wall_t + chip_cy;    // 13.5

chip_hole_d      = 7.0;

// Top plate height: bottom clears chip top; thick enough so post length
// equals pocket depth with a little to spare.
chip_clearance   = 0.5;
target_airgap    = 1.0;     // magnet bottom to chip top (mm)
magnet_h_actual  = 2.5;     // magnet physical height
pocket_depth     = magnet_h_actual + 0.5;   // 3.0 — 0.5mm push room
post_length      = pocket_depth + 0.5;      // 3.5 — post slightly longer than pocket

magnet_bottom_z  = chip_top_z + target_airgap;          // 7.5
top_plate_top_z  = magnet_bottom_z + post_length;        // 11.0
top_plate_btm_z  = chip_top_z + chip_clearance;          // 7.0
top_plate_t      = top_plate_top_z - top_plate_btm_z;    // 4.0
holder_h         = top_plate_top_z;                       // 11.0

// ── Degree marks (debossed into top plate surface) ────────────────
mark_depth       = 0.4;
mark_inner_r     = chip_hole_d / 2 + 1.0;  // start just outside chip hole
// minor = every 10°, major = every 30°
mark_minor_w     = 0.5;    mark_minor_l = 4.5;
mark_major_w     = 0.8;    mark_major_l = 8.5;

// ── Magnet post geometry ──────────────────────────────────────────
post_od          = 6.4;    // 0.3mm clearance per side in 7mm hole
magnet_d         = 4.0;    // press-fit for 3.97mm magnet
eject_hole_d     = 1.0;    // through-hole for ejection pin

flange_d         = 16.0;
flange_t         = 2.5;

arm_length       = 90.0;
arm_w            = 8.0;
// arm thickness = flange_t (arm is coplanar with flange, same Z plane)


// ═══════════════════════════════════════════════════════════════════
// MODULE: board_holder
// Origin: holder bottom-front-left corner = breadboard surface level.
// ═══════════════════════════════════════════════════════════════════
module board_holder() {
    difference() {
        union() {
            // ── Four full-height corner posts ─────────────────────
            for (x = [0, inner_w + wall_t], y = [0, inner_d + wall_t]) {
                translate([x, y, 0])
                    cube([wall_t, wall_t, holder_h]);
            }

            // ── Ledge rails (PCB seat) ────────────────────────────
            translate([wall_t, 0,                 ledge_z - ledge_t])
                cube([inner_w, ledge_t, ledge_t]);
            translate([wall_t, inner_d + wall_t,  ledge_z - ledge_t])
                cube([inner_w, ledge_t, ledge_t]);
            translate([0,      wall_t,             ledge_z - ledge_t])
                cube([ledge_t, inner_d, ledge_t]);
            translate([inner_w + wall_t, wall_t,  ledge_z - ledge_t])
                cube([ledge_t, inner_d, ledge_t]);

            // ── Top plate (flat) ──────────────────────────────────
            translate([0, 0, top_plate_btm_z])
                cube([outer_w, outer_d, top_plate_t]);
        }

        // ── Chip hole ─────────────────────────────────────────────
        translate([cx, cy, top_plate_btm_z - 0.01])
            cylinder(d = chip_hole_d, h = top_plate_t + 0.02);

        // ── Peg holes through top plate ───────────────────────────
        // Hole centres: hole_cx_inset from each PCB edge, offset by wall_t
        for (px = [hole_cx_inset, board_w - hole_cx_inset],
             py = [hole_cx_inset, board_d - hole_cx_inset]) {
            translate([wall_t + px, wall_t + py, top_plate_btm_z - 0.01])
                cylinder(d = peg_d, h = top_plate_t + peg_h + 0.02);
        }

        // ── Degree marks (debossed on top surface) ────────────────
        // 0° = +X direction; rotate CCW for positive angles (standard math).
        for (deg = [0 : 10 : 350]) {
            is_major = (deg % 30 == 0);
            mlen = is_major ? mark_major_l : mark_minor_l;
            mwid = is_major ? mark_major_w : mark_minor_w;

            translate([cx, cy, top_plate_top_z - mark_depth])
            rotate([0, 0, deg])
            translate([mark_inner_r, -mwid / 2, 0])
                cube([mlen, mwid, mark_depth + 0.01]);
        }
    }

    // ── Alignment pegs (hang down from top plate underside) ───────
    for (px = [hole_cx_inset, board_w - hole_cx_inset],
         py = [hole_cx_inset, board_d - hole_cx_inset]) {
        translate([wall_t + px, wall_t + py, pcb_top_z])
            cylinder(d = peg_d, h = peg_h);
    }
}


// ═══════════════════════════════════════════════════════════════════
// MODULE: magnet_post
// Origin: centre of flange bottom face (= pivot axis centre).
//
// Arm offset: one long edge of the arm lies on the pivot centre line
// (Y=0). Rotate the post until that edge aligns with a degree mark
// to read the angle directly off the dial.
//
// Print orientation: arm flat on build plate (rotate 180° in slicer).
// ═══════════════════════════════════════════════════════════════════
module magnet_post() {
    difference() {
        union() {
            // ── Full flange disc ──────────────────────────────────
            cylinder(d = flange_d, h = flange_t);

            // ── Post (hangs below flange) ─────────────────────────
            translate([0, 0, -post_length])
                cylinder(d = post_od, h = post_length);

            // ── Arm ───────────────────────────────────────────────
            // Same Z plane and thickness as the flange — one flat
            // bottom surface, no step. One long edge at Y=0 (pivot
            // centre line) for reading angles against the degree marks.
            translate([0, 0, 0])
                cube([arm_length, arm_w, flange_t]);
        }

        // ── Magnet pocket (blind, at post bottom) ─────────────────
        translate([0, 0, -post_length - 0.01])
            cylinder(d = magnet_d, h = pocket_depth + 0.01);

        // ── Ejection through-hole (1mm, vertical through top surface) ──
        // Enters at top of flange/arm surface, exits above magnet pocket.
        translate([0, 0, -post_length + pocket_depth])
            cylinder(d = eject_hole_d,
                     h = post_length - pocket_depth + flange_t + 0.02);
    }
}


// ═══════════════════════════════════════════════════════════════════
// Render — side by side. Comment out one to isolate for export.
// ═══════════════════════════════════════════════════════════════════
board_holder();

translate([50, 0, flange_t + post_length])
    rotate([180, 0, 0])
        magnet_post();
