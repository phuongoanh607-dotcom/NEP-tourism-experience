-- NÉP 014: sample dining, lodging and package details for the original 10 tours.
-- Names and prices are illustrative planning data for the presentation.
with samples(title,restaurant,hotel,menu,price) as (values
('Sài Gòn qua những lớp ký ức','Nhà hàng Cục Gạch Quán','Không lưu trú – tour nửa ngày','Cà phê/sữa đậu nành nhẹ giữa hành trình; kết thúc tự do ăn trưa tại khu trung tâm',590000),
('Một ngày ở Củ Chi: đất và người','Bò tơ Xuân Đào','Không lưu trú – tour trong ngày','Bữa trưa: bò tơ hấp cuốn bánh tráng, rau rừng, khoai mì và trà đá',1190000),
('Miền vườn Cái Bè – chậm một nhịp','Nhà hàng Mekong Rest Stop','Không lưu trú – tour trong ngày','Bữa sáng nhẹ; trưa cá tai tượng chiên xù, canh chua cá, cá kho tộ, rau luộc',1490000),
('Đà Lạt – dấu chân cao nguyên','Nhà hàng cơm niêu Fresh','Sandals Lily Hotel Đà Lạt','Bữa sáng buffet; trưa cơm niêu, gà nướng; tối lẩu gà lá é, rau Đà Lạt',3690000),
('Hội An – phố nhỏ, chuyện dài','Nhà hàng Morning Glory','Hoi An Historic Hotel','Bữa sáng buffet; trưa cao lầu, hoành thánh; tối cơm gà Hội An và món địa phương',8290000),
('Huế – sống cùng di sản','Nhà hàng Ancient Hue','Romance Hotel Huế','Bữa sáng buffet; trưa cơm cung đình theo set; tối bánh bèo, nậm, lọc và món Huế',8290000),
('Hà Nội – ngõ nhỏ và ký ức phố','Nhà hàng Bếp Việt','Hanoi Pearl Hotel','Bữa sáng buffet; trưa bún chả, nem; tối chả cá hoặc set món Bắc',6690000),
('Ninh Bình – non nước và làng quê','Nhà hàng Đức Dê','Ninh Bình Hidden Charm Hotel & Resort','Bữa sáng buffet; trưa dê núi, cơm cháy; tối cá sông, rau theo mùa',9290000),
('Sa Pa – bản làng và sắc núi','Nhà hàng A Phủ','Bamboo Sapa Hotel','Bữa sáng buffet; trưa cá suối, rau cải mèo; tối lẩu cá hồi hoặc gà đen',9790000),
('Hà Giang – cung đường đá và bản sắc','Nhà hàng Âu Việt','Yên Biên Luxury Hotel','Bữa sáng tại khách sạn; trưa thắng cố phiên bản phù hợp đoàn, thịt lợn bản; tối gà đồi, rau địa phương',11290000)
)
update public.journeys j set
 price_from=s.price,
 itinerary=coalesce((
  select jsonb_agg(
    step || jsonb_build_object(
      'restaurant',s.restaurant,
      'menu',s.menu,
      'hotel',case when j.duration_days>1 then s.hotel else 'Không lưu trú – tour trong ngày' end,
      'stay',case when j.duration_days>1 then (j.duration_days-1)::text || ' đêm · nhận phòng 14:00, trả phòng 12:00' else 'Không áp dụng' end
    ) order by ord
  )
  from jsonb_array_elements(coalesce(j.itinerary,'[]'::jsonb)) with ordinality as x(step,ord)
 ),'[]'::jsonb),
 price_note='Giá tour mẫu theo khách khởi hành từ TP. Hồ Chí Minh, dùng cho bản trình bày NÉP; có thể thay đổi theo ngày đi, số lượng khách và dịch vụ lựa chọn.'
from samples s where j.title=s.title;
