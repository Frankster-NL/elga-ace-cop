// Behuizing Elga Ace COP-meter – v3
// Seeit ESP32-DEV-38U(E) + 3x Adafruit MAX31865 PT1000 (ADA-3648) + gaatjesprint 30x70
// Afgeronde hoeken, PLA-printbaar zonder support
// part = "box" | "lid"
part = "box";
$fn = 72;

// ---------- Hoofdmaten ----------
wall    = 2.5;
floor_t = 2.5;
in_x    = 150;     // binnenmaat
in_y    = 110;
in_h    = 40;
clr     = 0.6;

r_out   = 6;               // verticale buitenhoeken
r_in    = r_out - wall;    // verticale binnenhoeken
r_top   = 1.2;             // bovenrand bak / onderrand deksel
r_fill  = 2;               // holle ronding vloer-wand
ch_bed  = 0.8;             // 45° afschuining aan bedzijde

pcb     = 1.6;

// ---------- MAX31865 (ADA-3648: 28,0 x 25,4 mm) ----------
max_p     = 28.0 + clr;    // vierkante pocket, past in beide richtingen
max_ledge = 6;
max_gap   = 12;
max_y0    = 14;            // ruimte voor wartelmoeren
max_x0    = (in_x - (3*max_p + 2*max_gap)) / 2;

// ---------- ESP32-DEV-38U (± 55 x 28 mm, ruime pocket) ----------
esp_x  = 57.0 + clr;
esp_y  = 30.0 + clr;
esp_ledge = 16;            // ruimte voor pinnen + dupont onder het bord
esp_x0 = in_x - 0.5 - esp_x;          // USB tegen rechterwand
esp_y0 = in_y - 8 - esp_y;

// ---------- Gaatjesprint 30 x 70 mm (5V/GND-verdeling + spanningsdeler) ----------
pf_x   = 70 + clr;
pf_y   = 30 + clr;
pf_ledge = 5;
pf_x0  = 10;
pf_y0  = in_y - 8 - pf_y;

// ---------- Doorvoeren ----------
gland_d = 12.7;    // PG7 (kabel 3–6,5 mm)
gland_z = 22;      // hart boven binnenvloer
usb_w = 14;  usb_h = 9;
sma_d  = 6.6;      // SMA-schotdoorvoer (1/4"-36)
sma_x  = esp_x0 + 10;   // achterwand, bij de antenne-zijde van de ESP32
sma_z  = 30;

boss_d = 7;  boss_hole = 2.6;  boss_in = 3.4;
lid_t  = 2.5; lip_h = 3; lip_t = 1.6; lid_clr = 0.3;

// ---------- 2D-hulpvormen ----------
module rrect(x, y, r) { translate([r, r]) offset(r = r) square([x - 2*r, y - 2*r]); }

module tear(d) {              // druppel met afgeplatte top
    r = d/2;
    intersection() {
        hull() { circle(r = r); rotate(45) square(r); }
        translate([-r - 1, -r - 1]) square([2*r + 2, 2*r + 1.7]);
    }
}

module profile_solid(x0, y0, x, y, r, pts) {
    hull() for (p = pts)
        translate([x0, y0, p[0]]) linear_extrude(0.01)
            offset(delta = -p[1]) rrect(x, y, r);
}
function quarter_top(z1, rt) = [for (a = [0:15:90]) [z1 - rt + rt*sin(a), rt*(1 - cos(a))]];

// ---------- Bak ----------
module shell() {
    pts = concat([[-floor_t, ch_bed], [-floor_t + ch_bed, 0], [in_h - r_top, 0]], quarter_top(in_h, r_top));
    profile_solid(-wall, -wall, in_x + 2*wall, in_y + 2*wall, r_out, pts);
}

module cavity() {
    pts = concat([for (a = [0:15:90]) [r_fill*(1 - cos(a)), r_fill*(1 - sin(a))]], [[in_h + 2, 0]]);
    profile_solid(0, 0, in_x, in_y, r_in, pts);
}

module ears() {
    for (side = [0, 1]) {
        xw  = side == 0 ? -wall : in_x + wall;
        dir = side == 0 ? -1 : 1;
        for (yc = [22, in_y - 22]) difference() {
            translate([0, 0, -floor_t]) linear_extrude(4) hull() {
                translate([xw - dir*2, yc - 10]) square([0.01, 20]);
                for (dy = [-6, 6]) translate([xw + dir*9, yc + dy]) circle(r = 4);
            }
            translate([xw + dir*7, yc, -floor_t - 1]) cylinder(d = 4.5, h = 10);
        }
    }
}

module corner_posts(px, py, w, d, ledge, s = 5) {
    top = ledge + pcb + 2.5;
    difference() {
        union() for (cx = [px, px + w]) for (cy = [py, py + d])
            translate([cx - s/2, cy - s/2, 0]) linear_extrude(top) rrect(s, s, 1);
        translate([px, py, ledge]) cube([w, d, top]);
    }
}

module bosses() {
    for (bx = [boss_in, in_x - boss_in]) for (by = [boss_in, in_y - boss_in])
        translate([bx, by, 0]) difference() {
            cylinder(d = boss_d, h = in_h);
            translate([0, 0, in_h - 12]) cylinder(d = boss_hole, h = 13);
            translate([0, 0, in_h - 0.6]) cylinder(d1 = boss_hole, d2 = boss_hole + 1.2, h = 0.61);
        }
}

// Bevestigingsoog voor kabelbinder (trekontlasting achter de wartels)
module tie_anchor(x, y) {
    translate([x - 5, y - 3, 0]) difference() {
        linear_extrude(6) rrect(10, 6, 1.5);
        translate([2, -1, 1.5]) cube([6, 8, 2.5]);   // tunnel voor kabelbinder 5 mm
    }
}

module box() {
    difference() {
        union() { shell(); ears(); }
        cavity();
        // 3x PG7 PT1000 – voorwand, recht tegenover elke MAX31865
        for (i = [0:2]) translate([max_x0 + i*(max_p + max_gap) + max_p/2, 1, gland_z])
            rotate([90, 0, 0]) linear_extrude(wall + 2) tear(gland_d);
        // PG7 flowmeter – linkerwand, bij de gaatjesprint
        translate([-wall - 1, pf_y0 + pf_y/2, gland_z])
            rotate([90, 0, 90]) linear_extrude(wall + 2) tear(gland_d);
        // USB-voeding – rechterwand, uitgelijnd op de ESP32
        translate([in_x - 1, esp_y0 + esp_y/2 - usb_w/2, esp_ledge + pcb + 1.8 - usb_h/2])
            rotate([90, 0, 90]) linear_extrude(wall + 2) rrect(usb_w, usb_h, 2);
        // SMA-antenne – achterwand
        translate([sma_x, in_y - 1, sma_z]) rotate([-90, 0, 0])
            cylinder(d = sma_d, h = wall + 2);
    }
    intersection() {
        cavity();
        union() {
            for (i = [0:2]) corner_posts(max_x0 + i*(max_p + max_gap), max_y0, max_p, max_p, max_ledge);
            corner_posts(esp_x0, esp_y0, esp_x, esp_y, esp_ledge, 6);
            corner_posts(pf_x0, pf_y0, pf_x, pf_y, pf_ledge);
            for (i = [0:2]) tie_anchor(max_x0 + i*(max_p + max_gap) + max_p/2, 8);
            bosses();
        }
    }
    intersection() { shell(); bosses(); }
}

// ---------- Deksel (buitenzijde op het bed) ----------
module lid() {
    pts = concat([[0, ch_bed], [ch_bed, 0], [lid_t - r_top, 0]], quarter_top(lid_t, r_top));
    lr = r_in - lid_clr;
    difference() {
        union() {
            profile_solid(-wall, -wall, in_x + 2*wall, in_y + 2*wall, r_out, pts);
            translate([lid_clr, lid_clr, lid_t - 0.01]) linear_extrude(lip_h) difference() {
                rrect(in_x - 2*lid_clr, in_y - 2*lid_clr, lr);
                translate([lip_t, lip_t]) rrect(in_x - 2*(lid_clr + lip_t), in_y - 2*(lid_clr + lip_t), max(lr - lip_t, 0.5));
            }
        }
        for (bx = [boss_in, in_x - boss_in]) for (by = [boss_in, in_y - boss_in]) {
            translate([bx, by, lid_t - 0.02]) cylinder(d = boss_d + 1.4, h = lip_h + 1);
            translate([bx, by, -1]) cylinder(d = 3.4, h = lid_t + 2);
            translate([bx, by, -0.01]) cylinder(d1 = 6.6, d2 = 3.4, h = 1.6);
        }
        // ingegraveerde tekst aan buitenzijde (bedzijde, 0,6 mm diep)
        translate([in_x/2, in_y/2, -0.01]) mirror([0, 1, 0]) linear_extrude(0.6)
            text("Elga Ace COP", size = 9, halign = "center", valign = "center",
                 font = "Liberation Sans:style=Bold");
    }
}

if (part == "box") box();
else if (part == "lid") lid();
