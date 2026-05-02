title = Cool Article
#---

Hello, this is a test.

```rust
// Initialize freetype
let library = freetype::Library::init().unwrap();
let face = library.new_face(font_file_path, 0).unwrap();
face.set_pixel_sizes(0, size).unwrap();

let fields = Vec::empty();

// Iterate over characters
for char_code in 33..127 {
	face.load_char(char_code, LoadFlag::empty()).unwrap();
	let metrics = face.glyph().metrics();
	let width = metrics.width as usize / 64 + spread * 2;
	let height = metrics.height as usize / 64 + spread * 2;
	let left_edge_padded = metrics.horiBearingX as f64 / 64.0 - spread_f64;
	let top_edge_padded = metrics.horiBearingY as f64 / 64.0 + spread_f64;
	let outline = face.glyph().outline().unwrap();

	let mut field = Vec::with_capacity(height);

	// Iterate over texels in our distance field
	for row in 0..height {
		let mut field_row = Vec::with_capacity(width);

		for col in 0..width {
			let mut min_dist = f64::MAX;
			let mut total_cross_num = 0;
			let p = Vector {
				x: left_edge_padded + col as f64 + 0.5,
				y: top_edge_padded - row as f64 - 0.5
			};

			// Find the minimum distance from p to each curve
			for contour in outline.contours_iter() {
				let mut start = *contour.start();

				for curve in contour {
					let s = Vector {
						x: start.x as f64 / 64.0,
						y: start.y as f64 / 64.0
					};

					let (end, dist, cross_num) = match curve {
						Curve::Line(end) => {
							let e = Vector {
								x: end.x as f64 / 64.0,
								y: end.y as f64 / 64.0
							};

							let dist = find_dist_to_line(&p, &s, &e);
							let cross_num = find_cross_num_of_line(&p, &s, &e);

							(end, dist, cross_num)
						},
						Curve::Bezier2(control, end) => {
							let c = Vector {
								x: control.x as f64 / 64.0,
								y: control.y as f64 / 64.0
							};

							let e = Vector {
								x: end.x as f64 / 64.0,
								y: end.y as f64 / 64.0
							};

							let dist = find_dist_to_bezier(&p, &s, &c, &e);
							let cross_num = find_cross_num_of_bezier(&p, &s, &c, &e);

							(end, dist, cross_num)
						},
						Curve::Bezier3(_, _, _) => {
							panic!("cubic beziers not supported");
						}
					};

					if dist < min_dist {
						min_dist = dist;
					}

					total_cross_num += cross_num;
					start = end;
				}
			}

			// Clamp the signed distance to the spread and normalize it to a u8
			let dist_signed = if total_cross_num % 2 == 0 { -min_dist } else { min_dist };
			let dist_clamped = dist_signed.min(spread_f64).max(-spread_f64);
			let dist_positive = dist_clamped + spread_f64;
			let dist_scaled = (dist_positive * 255.0 / (spread_f64 * 2.0)).round() as u8;

			field_row.push(dist_scaled);
		}

		field.push(field_row);
	}

	fields.push(field);
}

let atlas = generate_atlas(&fields);
```

Here is some inline code: `thing: Vec<Option<u8>>`, testing the angle brackets.

Code block done.

