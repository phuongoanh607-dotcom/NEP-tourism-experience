-- NÉP: provisional retail pricing for tours departing from Ho Chi Minh City.
-- These are planning prices, not supplier-confirmed quotations or guaranteed live fares.
-- Re-running this migration is safe: it updates the same ten named products.
-- Before opening sales, NÉP must confirm supplier contracts, live transport fares,
-- hotel/meal/entrance costs, minimum group size, insurance, taxes and operating margin.

update public.journeys
set
  price_from = v.price_from,
  duration_days = v.duration_days,
  duration_label = v.duration_label,
  departure_point = 'TP. Hồ Chí Minh',
  transport = v.transport,
  price_note = 'Giá dự kiến của NÉP cho khách khởi hành từ TP. Hồ Chí Minh; đã dự trù vận chuyển đường dài theo phương án tour. Chưa phải giá bán xác nhận. Giá cuối cùng phụ thuộc ngày khởi hành, giá vé/nhà xe, số khách và xác nhận nhà cung cấp.',
  verified_at = null
from (values
  ('Sài Gòn qua những lớp ký ức', 490000::bigint, 1, 'Nửa ngày', 'Đi bộ; phương tiện nội đô khi cần'),
  ('Một ngày ở Củ Chi: đất và người', 1090000::bigint, 1, '1 ngày', 'Xe du lịch khứ hồi từ TP. Hồ Chí Minh; đi bộ tại điểm'),
  ('Miền vườn Cái Bè – chậm một nhịp', 1390000::bigint, 1, '1 ngày', 'Xe du lịch khứ hồi từ TP. Hồ Chí Minh; thuyền địa phương nếu đủ điều kiện'),
  ('Đà Lạt – dấu chân cao nguyên', 3490000::bigint, 3, '3 ngày 2 đêm', 'Xe giường nằm/xe du lịch khứ hồi từ TP. Hồ Chí Minh; xe tại điểm đến'),
  ('Hội An – phố nhỏ, chuyện dài', 7990000::bigint, 4, '4 ngày 3 đêm', 'Máy bay khứ hồi TP. Hồ Chí Minh–Đà Nẵng; xe đưa đón Đà Nẵng–Hội An và tham quan'),
  ('Huế – sống cùng di sản', 7990000::bigint, 4, '4 ngày 3 đêm', 'Máy bay khứ hồi TP. Hồ Chí Minh–Huế/Đà Nẵng tùy lịch; xe tham quan'),
  ('Hà Nội – ngõ nhỏ và ký ức phố', 6490000::bigint, 3, '3 ngày 2 đêm', 'Máy bay khứ hồi TP. Hồ Chí Minh–Hà Nội; xe sân bay và phương tiện nội đô'),
  ('Ninh Bình – non nước và làng quê', 8990000::bigint, 4, '4 ngày 3 đêm', 'Máy bay khứ hồi TP. Hồ Chí Minh–Hà Nội; xe đường bộ Hà Nội–Ninh Bình và tham quan'),
  ('Sa Pa – bản làng và sắc núi', 9490000::bigint, 5, '5 ngày 4 đêm', 'Máy bay khứ hồi TP. Hồ Chí Minh–Hà Nội; xe giường nằm/xe du lịch Hà Nội–Sa Pa khứ hồi'),
  ('Hà Giang – cung đường đá và bản sắc', 10990000::bigint, 6, '6 ngày 5 đêm', 'Máy bay khứ hồi TP. Hồ Chí Minh–Hà Nội; xe du lịch Hà Nội–Hà Giang khứ hồi')
) as v(title, price_from, duration_days, duration_label, transport)
where public.journeys.title = v.title;

-- Correct the geographic classification of Da Lat.
update public.journeys
set region = 'Tây Nguyên'
where title = 'Đà Lạt – dấu chân cao nguyên';
