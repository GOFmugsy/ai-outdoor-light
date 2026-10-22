// =====================================================================
//  Solar Garden Light - parametric enclosure
//
//  Holds:
//    * Adafruit QT Py ESP32-S2                          (controller)
//    * Adafruit NeoPixel Ring - 16 x 5050 RGB LED        (light source)
//    * Adafruit 5V 0.6W Mini ETFE Solar Panel - Voltaic P123 (65.5 x 65.5 x 3.1 mm)
//    * LiPo pouch  -or-  1x 18650 cell in a holder       (night power)
//    * Adafruit bq24074 solar LiPo charger (or similar)  (charging)
//
//  Stack (top to bottom):
//    cap (solar panel pocket, rain shade) + reflector cone underneath /
//    diffuser tube around a hollow spine (panel cable runs inside it) /
//    deck (NeoPixel ring faces up) / gasket / body (electronics) /
//    base (pole socket) / stake
//
//  Render a single part by setting `part`, or from the command line:
//    openscad -D 'part="body"' -o body.stl solar_light.scad
//  (see export_stls.sh)
// =====================================================================

/* [Part to render] */
part = "assembly"; // [assembly, exploded, cap, reflector, spine, diffuser, deck, gasket, body, base, stake, usb_plug]

/* [Solar panel - Voltaic P123] */
panel_size        = [65.5, 65.5, 3.1]; // x, y, thickness (some listings say 3.6)
panel_clearance   = 0.5;            // per side, pocket vs panel
panel_proud       = 0.4;            // panel sits this far above the cap so water runs off
panel_cable_pos   = [0, 20];        // cable exit relative to panel centre - MEASURE YOURS
panel_jbox        = [22, 14, 1.5];  // recess under the panel for cable strain relief (0 = none)
cable_channel     = [5, 2];         // width, depth of the hidden channel to the spine

/* [NeoPixel ring - 16 x 5050] */
ring_od           = 44.5;
ring_id           = 31.75;
ring_pcb_t        = 1.6;
ring_total_t      = 3.6;            // PCB + LEDs
ring_fit          = 0.3;            // radial clearance
ring_seat_depth   = 2.0;            // how deep the PCB is recessed into the deck
wire_hole_pos     = [12, -7];       // align the ring's solder pads over this hole
wire_hole_d       = 7;

/* [QT Py ESP32-S2] */
qtpy_size         = [17.8, 21.8, 1.0]; // x, y, PCB thickness (USB-C end faces -Y)
qtpy_ledge_h      = 2.5;               // air gap under the PCB for bottom-side parts
qtpy_usb          = [9.0, 3.3];        // USB-C receptacle width, height
qtpy_x            = 20;                // x position of the board centre
usb_access        = true;              // port in the end wall (closed with usb_plug)
usb_port          = [12.5, 7.5];       // opening size (fits most USB-C plug overmoulds)

/* [Charger board - bq24074 (verify dimensions!)] */
charger_size      = [30, 40, 1.6];
charger_pos       = [20, 9];
charger_ledge_h   = 3;

/* [Battery] */
battery_type      = "lipo";  // [lipo, 18650]  (18650 needs body_extra = [0, 6] or more)
holder_18650      = [21, 78, 20.5]; // single 18650 holder (e.g. Keystone 1042)
lipo_size         = [36, 62, 8];    // e.g. 2000 mAh pouch - set to your cell
battery_y         = 0;

/* [Body + deck] */
wall              = 3;
rim               = 8;     // border around the panel; also sets the body footprint
body_extra        = [0, 0]; // grow the body + deck beyond the cap footprint (x, y)
corner_r          = 5;
body_h            = 33;
floor_t           = 6;
deck_t            = 6;     // lid of the body; ring seat + diffuser groove are recessed into it
gasket_t          = 1.2;   // print in TPU
screw_inset       = 5;
screw_d           = 3.4;   // M3 clearance
screw_head_d      = 6.5;
screw_head_h      = 3.2;
insert_d          = 4.2;   // M3 heat-set insert (use 2.6 to self-tap instead)
insert_h          = 6;
boss_r            = 4.5;

/* [Light: cap, diffuser, reflector, spine] */
cap_t             = 8.5;
diff_od           = 64;
diff_wall         = 1.6;   // print in natural/white PETG, 2 perimeters
diff_h            = 70;    // visible height between deck and cap
groove_depth      = 3;
fit               = 0.25;
refl_r            = 24;    // reflector cone under the cap - print in white
refl_angle        = 55;    // cone half-angle from vertical; >45 throws light downward
refl_wall         = 1.6;
spine_od          = 12;
spine_id          = 8;     // panel cable passes through - cut off the DC plug if it won't fit
spine_socket      = 3;
tie_rods          = 3;     // M3 threaded rods: cap inserts -> nuts under the deck
tie_rod_r         = 27;
tie_rod_angle0    = 30;    // keep clear of the cable channel (+Y)

/* [Base + mounting] */
pole_d            = 18;    // 1/2" EMT is ~17.9 mm; also sets the printed stake
pole_fit          = 0.3;
socket_depth      = 28;
socket_wall       = 2.4;
base_flange_d     = 70;
base_flange_t     = 5;
base_flare_r      = 26;    // where the 45 degree flare meets the flange
base_screws       = 3;
base_screw_r      = 31;
stake_len         = 150;
stake_fin_t       = 4;

/* [Assembly view] */
explode           = 25;
show_components   = true;

$fn = 96;

// ---------------------------------------------------------------------
//  Derived values
// ---------------------------------------------------------------------
eps          = 0.01;
pocket       = [panel_size.x + 2*panel_clearance, panel_size.y + 2*panel_clearance];
enc          = pocket + [2*rim, 2*rim];
benc         = enc + body_extra;                  // body / deck / gasket footprint
inner        = benc - [2*wall, 2*wall];
inner_r      = max(corner_r - wall, 0.5);
screw_pts    = [for (sx = [-1, 1], sy = [-1, 1])
                  [sx*(benc.x/2 - screw_inset), sy*(benc.y/2 - screw_inset)]];

diff_r       = diff_od/2;
groove_ri    = diff_r - diff_wall - fit;
groove_ro    = diff_r + fit;
diff_total_h = diff_h + 2*(groove_depth - 0.3);   // 0.3 mm left for sealant
tie_pts      = [for (i = [0:tie_rods-1])
                  tie_rod_r*[cos(tie_rod_angle0 + i*360/tie_rods),
                             sin(tie_rod_angle0 + i*360/tie_rods)]];
pocket_depth = panel_size.z - panel_proud;
cap_insert_h = min(insert_h, cap_t - pocket_depth - 0.8);
deck_insert_h= min(insert_h, deck_t - 1);
floor_insert_h = floor_t - 1;
spine_len    = diff_h + ring_seat_depth + 2*spine_socket - 0.6;
refl_h       = refl_r/tan(refl_angle);

bat          = battery_type == "18650" ? holder_18650 : lipo_size;
rail_t       = 1.6;
bat_clear    = 0.4;
bat_pos      = [-inner.x/2 + rail_t + bat_clear + bat.x/2, battery_y];

qtpy_pos     = [qtpy_x, -inner.y/2 + 1.2 + qtpy_size.y/2];
usb_z        = floor_t + qtpy_ledge_h + qtpy_size.z + qtpy_usb.y/2;

pole_r       = pole_d/2 + pole_fit;
boss_rr      = pole_r + socket_wall;               // socket boss outer radius
flare_h      = base_flare_r - boss_rr;
base_h       = max(socket_depth + 2, base_flange_t + flare_h + 3);
base_pts     = [for (i = [0:base_screws-1])
                  base_screw_r*[cos(90 + i*360/base_screws), sin(90 + i*360/base_screws)]];

// ---------------------------------------------------------------------
//  Sanity checks
// ---------------------------------------------------------------------
assert(diff_od + 2 < min(enc.x, benc.x), "Diffuser wider than the cap or deck");
assert(base_flange_d <= benc.x, "Base flange wider than the body");
assert(ring_od/2 + ring_fit + 1 < groove_ri, "NeoPixel ring collides with diffuser groove");
assert(spine_od/2 + 1 < ring_id/2, "Spine does not fit through the ring");
assert(tie_rod_r - insert_d/2 > ring_od/2 + ring_fit + 0.8, "Tie rods hit the ring seat");
assert(tie_rod_r + insert_d/2 < groove_ri - 0.5, "Tie rods hit the diffuser groove");
assert(tie_rod_r - screw_d/2 > refl_r, "Tie rods pass through the reflector");
assert(cap_t - pocket_depth - cable_channel.y - groove_depth >= 0.6, "Cable channel breaks into the diffuser groove");
assert(groove_depth < deck_t - 1.5, "Deck too thin for the diffuser groove");
assert(base_screw_r - screw_head_d/2 > base_flare_r, "Base screw heads hit the flare");
assert(base_screw_r + screw_head_d/2 < base_flange_d/2, "Base screws too close to the flange edge");
assert(bat.y + 2*(bat_clear + rail_t) <= inner.y &&
       bat_pos.x + bat.x/2 + bat_clear + rail_t <
           min(charger_pos.x - charger_size.x/2, qtpy_pos.x - qtpy_size.x/2) - 2.3,
       str("Battery does not fit the body interior (", inner.x, " x ", inner.y, ") - increase body_extra"));
assert(abs(charger_pos.x) + charger_size.x/2 + 1.8 <= inner.x/2 &&
       abs(charger_pos.y) + charger_size.y/2 + 1.8 <= inner.y/2, "Charger cradle outside the body - move charger_pos");
assert(charger_pos.y - charger_size.y/2 - 1.8 > qtpy_pos.y + qtpy_size.y/2 + 1.8 ||
       abs(charger_pos.x - qtpy_pos.x) > (charger_size.x + qtpy_size.x)/2 + 3.6, "Charger and QT Py cradles overlap");
assert(bat.z < body_h - floor_t - 4, "Battery taller than the body interior (leave room for tie rod nuts)");

echo(str("Cap: ", enc.x, " x ", enc.y, " mm,  body: ", benc.x, " x ", benc.y, " mm"));
echo(str("Overall height (no stake): ", base_h + body_h + gasket_t + deck_t + diff_h + cap_t, " mm"));
echo(str("Tie rods (M3): ~", cap_insert_h + diff_h + deck_t + 3, " mm"));
echo(str("Deck screws (M3, from below): ", body_h - screw_head_h + gasket_t + deck_insert_h - 0.5, " mm max"));

// ---------------------------------------------------------------------
//  Helpers
// ---------------------------------------------------------------------
module rrect(size, r) {
    offset(r) square([size.x - 2*r, size.y - 2*r], center = true);
}

module rbox(size, h, r) {
    linear_extrude(h) rrect(size, r);
}

module annulus(ri, ro, h) {
    difference() {
        cylinder(r = ro, h = h);
        translate([0, 0, -1]) cylinder(r = ri, h = h + 2);
    }
}

// Open-topped frame with two side ledges for a PCB. Centred, sits on z=0.
module board_cradle(size, ledge_h, above = 1.5, open_front = false, notches = false) {
    c  = 0.2;
    t  = 1.6;
    ix = size.x + 2*c;
    iy = size.y + 2*c;
    h  = ledge_h + size.z + above;
    difference() {
        translate([-ix/2 - t, -iy/2 - t, 0]) cube([ix + 2*t, iy + 2*t, h]);
        translate([-ix/2, -iy/2, -1]) cube([ix, iy, h + 2]);
        if (open_front)
            translate([-ix/2, -iy/2 - t - 1, ledge_h]) cube([ix, t + 2, h]);
        if (notches) {
            translate([-4, -iy/2 - t - 1, ledge_h + size.z]) cube([8, iy + 2*t + 2, h]);
            translate([-ix/2 - t - 1, -4, ledge_h + size.z]) cube([ix + 2*t + 2, 8, h]);
        }
    }
    for (sx = [-1, 1])
        translate([sx > 0 ? ix/2 - 1.2 : -ix/2, -iy/2, 0]) cube([1.2, iy, ledge_h]);
}

module battery_cradle() {
    h = min(bat.z*0.6, 10);
    o = [bat.x + 2*bat_clear, bat.y + 2*bat_clear];
    translate([bat_pos.x, bat_pos.y, 0]) difference() {
        translate([-o.x/2 - rail_t, -o.y/2 - rail_t, 0]) cube([o.x + 2*rail_t, o.y + 2*rail_t, h]);
        translate([-o.x/2, -o.y/2, -1]) cube([o.x, o.y, h + 2]);
        // wire exits at both ends
        translate([-4, -o.y/2 - rail_t - 1, 1.5]) cube([8, o.y + 2*rail_t + 2, h]);
        // finger cut-outs to lift the battery out
        translate([0, 0, h]) rotate([0, 90, 0]) cylinder(r = h*0.7, h = o.x + 4*rail_t, center = true);
    }
}

// Rounded-top edge softener for the rectangular plates
module edge_chamfer(sz, h) {
    translate([0, 0, h - 0.8]) difference() {
        rbox(sz + [2, 2], 2, corner_r + 1);
        translate([0, 0, -eps]) linear_extrude(0.8 + eps, scale = [(sz.x - 1.6)/sz.x, (sz.y - 1.6)/sz.y])
            rrect(benc, corner_r);
    }
}

// ---------------------------------------------------------------------
//  Parts - light (top)
// ---------------------------------------------------------------------

// Solar panel cap. Prints top-up; everything underneath is recessed.
module cap() {
    difference() {
        rbox(enc, cap_t, corner_r);
        // panel pocket
        translate([0, 0, cap_t - pocket_depth]) linear_extrude(pocket_depth + 1) square(pocket, center = true);
        // recess for the panel's cable strain relief
        if (panel_jbox.z > 0)
            translate([panel_cable_pos.x, panel_cable_pos.y, cap_t - pocket_depth - panel_jbox.z])
                linear_extrude(panel_jbox.z + eps) rrect([panel_jbox.x, panel_jbox.y], 2);
        // hidden cable channel from the cable exit to the spine (under the panel)
        hull() for (p = [panel_cable_pos, [0, 0]])
            translate([p.x, p.y, cap_t - pocket_depth - cable_channel.y])
                cylinder(d = cable_channel.x, h = cable_channel.y + eps);
        // down into the spine
        translate([0, 0, -1]) cylinder(d = spine_id, h = cap_t + 2);
        // --- underside ---
        translate([0, 0, -eps]) annulus(groove_ri, groove_ro, groove_depth + eps);
        translate([0, 0, -eps]) cylinder(d = spine_od + 2*fit, h = spine_socket + eps);
        for (p = tie_pts) translate([p.x, p.y, -eps]) cylinder(d = insert_d, h = cap_insert_h);
        edge_chamfer(enc, cap_t);
    }
}

// Cone that hangs under the cap, point down. Print flat face down (as modelled).
module reflector() {
    hole_r = spine_od/2 + fit;
    difference() {
        union() {
            difference() {
                cylinder(r1 = refl_r, r2 = 0, h = refl_h);
                translate([0, 0, -eps])
                    cylinder(r1 = refl_r - refl_wall/cos(refl_angle), r2 = 0,
                             h = (refl_r - refl_wall/cos(refl_angle))/tan(refl_angle));
            }
            // collar that grips the spine
            intersection() {
                cylinder(r = hole_r + 2, h = refl_h);
                cylinder(r1 = refl_r, r2 = 0, h = refl_h);
            }
        }
        translate([0, 0, -1]) cylinder(r = hole_r, h = refl_h + 2);
        // clear the tie rods (only matters if refl_r is pushed out)
        for (p = tie_pts) translate([p.x, p.y, -1]) cylinder(d = screw_d, h = refl_h + 2);
    }
}

module spine() {
    annulus(spine_id/2, spine_od/2, spine_len);
}

module diffuser() {
    annulus(diff_r - diff_wall, diff_r, diff_total_h);
}

// Lid of the electronics body; carries the ring and the light column.
// Prints flat: top features and bottom features are all recesses.
module deck() {
    difference() {
        rbox(benc, deck_t, corner_r);
        // --- top ---
        translate([0, 0, deck_t - groove_depth]) annulus(groove_ri, groove_ro, groove_depth + 1);
        translate([0, 0, deck_t - ring_seat_depth]) cylinder(r = ring_od/2 + ring_fit, h = ring_seat_depth + 1);
        translate([0, 0, deck_t - ring_seat_depth - spine_socket])
            cylinder(d = spine_od + 2*fit, h = spine_socket + 1);
        translate([0, 0, -1]) cylinder(d = spine_id, h = deck_t + 2);            // panel cable
        translate([wire_hole_pos.x, wire_hole_pos.y, -1]) cylinder(d = wire_hole_d, h = deck_t + 2);
        for (p = tie_pts) translate([p.x, p.y, -1]) cylinder(d = screw_d, h = deck_t + 2);
        // --- underside: inserts for the screws coming up through the body ---
        for (p = screw_pts) translate([p.x, p.y, -eps]) cylinder(d = insert_d, h = deck_insert_h);
        edge_chamfer(benc, deck_t);
    }
}

// ---------------------------------------------------------------------
//  Parts - electronics + mounting (bottom)
// ---------------------------------------------------------------------
module gasket() {
    linear_extrude(gasket_t) difference() {
        rrect(benc, corner_r);
        difference() {
            rrect(inner, inner_r);
            for (p = screw_pts) translate(p) circle(r = boss_r);
        }
        for (p = screw_pts) translate(p) circle(d = screw_d);
    }
}

module body() {
    difference() {
        union() {
            difference() {
                rbox(benc, body_h, corner_r);
                translate([0, 0, floor_t]) rbox(inner, body_h, inner_r);
            }
            for (p = screw_pts) translate([p.x, p.y, 0]) cylinder(r = boss_r, h = body_h);
            translate([0, 0, floor_t - eps]) {
                battery_cradle();
                translate(qtpy_pos) board_cradle(qtpy_size, qtpy_ledge_h, 1.5, open_front = true);
                translate(charger_pos) board_cradle(charger_size, charger_ledge_h, 1.5, notches = true);
            }
        }
        // deck screws come up from underneath through the corner bosses
        for (p = screw_pts) translate([p.x, p.y, 0]) {
            translate([0, 0, -1]) cylinder(d = screw_d, h = body_h + 2);
            translate([0, 0, -eps]) cylinder(d = screw_head_d, h = screw_head_h);
        }
        // blind inserts for the base (do not break through the floor)
        for (p = base_pts) translate([p.x, p.y, -eps]) cylinder(d = insert_d, h = floor_insert_h);
        // USB-C access for reprogramming
        if (usb_access)
            translate([qtpy_pos.x, -benc.y/2 - 1, usb_z]) rotate([-90, 0, 0])
                linear_extrude(wall + 2) rrect(usb_port, 1.5);
    }
}

// Pole socket. Modelled in print orientation: flange on the bed, socket opening up.
// Flip it over to install (flange against the body floor).
module base() {
    difference() {
        rotate_extrude() polygon([
            [0, 0], [base_flange_d/2 - 1, 0], [base_flange_d/2, 1],
            [base_flange_d/2, base_flange_t], [base_flare_r, base_flange_t],
            [boss_rr, base_flange_t + flare_h], [boss_rr, base_h], [0, base_h]]);
        // socket, with lead-in
        translate([0, 0, base_h - socket_depth]) cylinder(r = pole_r, h = socket_depth + 1);
        translate([0, 0, base_h - 0.8]) cylinder(r1 = pole_r, r2 = pole_r + 0.8, h = 0.8 + eps);
        // screws up into the body floor, heads recessed on the underside of the flange
        for (p = base_pts) translate([p.x, p.y, 0]) {
            translate([0, 0, -1]) cylinder(d = screw_d, h = base_flange_t + 2);
            translate([0, 0, base_flange_t - 2]) cylinder(d = screw_head_d, h = 2 + eps);
        }
    }
    // crush ribs for a snug fit on the pole/stake
    for (i = [0:2]) rotate(i*120 + 30)
        translate([pole_r - 0.5, -0.6, base_h - socket_depth]) cube([0.7, 1.2, socket_depth - 1]);
}

module stake() {
    plug_h = socket_depth - 1;
    cylinder(d = pole_d, h = plug_h);
    translate([0, 0, plug_h - eps]) {
        for (a = [0, 90]) rotate(a) hull() {
            translate([-pole_d/2, -stake_fin_t/2, 0]) cube([pole_d, stake_fin_t, eps]);
            translate([-0.5, -stake_fin_t/2, stake_len]) cube([1, stake_fin_t, eps]);
        }
        cylinder(d1 = 8, d2 = 1.5, h = stake_len);
    }
}

module usb_plug() {
    rbox(usb_port + [5, 5], 1.6, 2.5);
    translate([0, 0, 1.6 - eps]) rbox(usb_port - [0.3, 0.3], wall - 0.2, 1.35);
}

// ---------------------------------------------------------------------
//  Component stand-ins for the assembly view
// ---------------------------------------------------------------------
module neopixel_ring_dummy() {   // PCB bottom at z=0, LEDs facing up
    color("black") annulus(ring_id/2, ring_od/2, ring_pcb_t);
    for (i = [0:15]) rotate(i*360/16) translate([(ring_od + ring_id)/4, 0, ring_pcb_t - eps])
        color("white") translate([-2.5, -2.5, 0]) cube([5, 5, ring_total_t - ring_pcb_t]);
}

module components_dummy() {
    translate([0, 0, floor_t]) {
        translate([bat_pos.x, bat_pos.y, 0]) {
            if (battery_type == "18650") {
                color("black") translate([-bat.x/2, -bat.y/2, 0]) cube([bat.x, bat.y, 2]);
                color("royalblue") translate([0, 0, 1.5 + 9.3]) rotate([90, 0, 0])
                    cylinder(d = 18.6, h = 65, center = true);
            } else {
                color("silver") translate([-bat.x/2, -bat.y/2, 0]) cube(bat);
            }
        }
        translate([qtpy_pos.x, qtpy_pos.y, qtpy_ledge_h]) {
            color("black") translate([-qtpy_size.x/2, -qtpy_size.y/2, 0]) cube(qtpy_size);
            color("silver") translate([-qtpy_usb.x/2, -qtpy_size.y/2 - 0.6, qtpy_size.z])
                cube([qtpy_usb.x, 7.5, qtpy_usb.y]);
        }
        translate([charger_pos.x, charger_pos.y, charger_ledge_h])
            color("purple") translate([-charger_size.x/2, -charger_size.y/2, 0]) cube(charger_size);
    }
}

module panel_dummy() {
    color("midnightblue") translate([-panel_size.x/2, -panel_size.y/2, 0]) cube(panel_size);
}

// ---------------------------------------------------------------------
//  Assembly (body floor at z = 0)
// ---------------------------------------------------------------------
module assembly(e = 0) {
    z_gasket = body_h + e*0.5;
    z_deck   = z_gasket + gasket_t + e*0.5;
    z_dtop   = z_deck + deck_t;                     // top of the deck
    z_cap    = z_dtop + diff_h + e*3;

    // base flipped (flange up against the floor), stake in its socket
    color("dimgray") translate([0, 0, -e]) mirror([0, 0, 1]) base();
    if (show_components) color("gray")
        translate([0, 0, -base_h + socket_depth - 1 - e*2]) mirror([0, 0, 1]) stake();

    color("slategray") body();
    if (show_components) components_dummy();
    color("black") translate([0, 0, z_gasket]) gasket();

    translate([0, 0, z_deck]) {
        color("slategray") deck();
        if (show_components) translate([0, 0, deck_t - ring_seat_depth + e*0.6]) neopixel_ring_dummy();
    }
    color("white", 0.4) translate([0, 0, z_dtop - groove_depth + 0.3 + e*1.5]) diffuser();
    color("lightgray") translate([0, 0, z_dtop - ring_seat_depth - spine_socket + 0.3 + e*1.5]) spine();

    translate([0, 0, z_cap]) {
        color("white") translate([0, 0, -e*0.6]) mirror([0, 0, 1]) reflector();
        color("dimgray") cap();
        if (show_components)
            translate([0, 0, cap_t - pocket_depth + e*0.6]) panel_dummy();
    }
}

if      (part == "assembly")  assembly(0);
else if (part == "exploded")  assembly(explode);
else if (part == "cap")       cap();
else if (part == "reflector") reflector();
else if (part == "spine")     spine();
else if (part == "diffuser")  diffuser();
else if (part == "deck")      deck();
else if (part == "gasket")    gasket();
else if (part == "body")      body();
else if (part == "base")      base();
else if (part == "stake")     stake();
else if (part == "usb_plug")  usb_plug();
