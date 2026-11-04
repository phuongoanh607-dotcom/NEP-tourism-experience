-- NÉP 011: add regional tour cards while preserving the original collection.
-- Inquiry-led entries have no fabricated price or departure schedule. Safe to rerun.
with tours(title,region,summary,tour_type,duration_days,duration_label,departure_point,transport) as (values
('Cao Bằng – bản làng và thác nước','Miền Bắc','Khám phá cảnh quan núi đá, thác nước và câu chuyện cộng đồng vùng Đông Bắc.','Thiên nhiên – cộng đồng',3,'3 ngày 2 đêm','Cao Bằng','Xe du lịch; đi bộ tại điểm'),
('Ba Bể – nhịp sống bên hồ','Miền Bắc','Tìm hiểu hệ sinh thái hồ và nhịp sống của cộng đồng địa phương.','Sinh thái – cộng đồng',2,'2 ngày 1 đêm','Hồ Ba Bể, Bắc Kạn','Xe đường bộ; thuyền theo điều kiện vận hành'),
('Mộc Châu – mùa xanh cao nguyên','Miền Bắc','Khám phá nông nghiệp cao nguyên, cảnh quan theo mùa và văn hóa bản địa.','Nông nghiệp – thiên nhiên',2,'2 ngày 1 đêm','Mộc Châu, Sơn La','Xe du lịch; đi bộ ngắn'),
('Điện Biên – ký ức và miền biên viễn','Miền Bắc','Tìm hiểu lịch sử, văn hóa và đời sống vùng biên qua những điểm dừng có chọn lọc.','Lịch sử – văn hóa',2,'2 ngày 1 đêm','TP. Điện Biên Phủ','Xe du lịch; đi bộ tại di tích'),
('Hạ Long – di sản nhìn từ mặt nước','Miền Bắc','Khám phá cảnh quan vịnh và câu chuyện di sản thiên nhiên.','Di sản thiên nhiên',2,'2 ngày 1 đêm','Hạ Long, Quảng Ninh','Xe du lịch; tàu tham quan được cấp phép'),
('Quảng Bình – dấu chân miền di sản','Miền Trung','Kết nối cảnh quan thiên nhiên, di sản và đời sống địa phương miền Trung.','Thiên nhiên – di sản',3,'3 ngày 2 đêm','Đồng Hới, Quảng Bình','Xe du lịch; đi bộ theo tuyến được phép'),
('Đà Nẵng – thành phố bên sông và biển','Miền Trung','Khám phá không gian đô thị, văn hóa địa phương và cảnh quan biển.','Đô thị – biển',2,'2 ngày 1 đêm','Đà Nẵng','Xe du lịch; đi bộ nội đô'),
('Quy Nhơn – miền biển hiền hòa','Miền Trung','Tìm hiểu văn hóa miền biển, cảnh quan ven bờ và ẩm thực địa phương.','Biển – văn hóa',2,'2 ngày 1 đêm','Quy Nhơn, Bình Định','Xe du lịch; phương tiện địa phương'),
('Phú Yên – miền xanh xứ Nẫu','Miền Trung','Khám phá cảnh quan ven biển, văn hóa xứ Nẫu và nhịp sống địa phương.','Thiên nhiên – bản địa',2,'2 ngày 1 đêm','Tuy Hòa, Phú Yên','Xe du lịch; đi bộ tại điểm'),
('Buôn Ma Thuột – chuyện kể đại ngàn','Tây Nguyên','Tìm hiểu văn hóa cà phê, không gian đô thị cao nguyên và câu chuyện cộng đồng.','Văn hóa – nông nghiệp',2,'2 ngày 1 đêm','Buôn Ma Thuột, Đắk Lắk','Xe du lịch; đi bộ tại điểm'),
('Tây Ninh – hành trình về miền nắng','Miền Nam','Kết nối cảnh quan núi, không gian tín ngưỡng và câu chuyện vùng đất Tây Ninh.','Văn hóa – thiên nhiên',1,'1 ngày','Tây Ninh','Xe du lịch; đi bộ tại điểm'),
('Bến Tre – theo dòng xứ dừa','Miền Nam','Tìm hiểu sinh kế miệt vườn, nghề thủ công và văn hóa sông nước xứ dừa.','Nông nghiệp – bản địa',1,'1 ngày','Bến Tre','Xe đường bộ; thuyền nếu đủ điều kiện'),
('An Giang – sắc màu miền biên giới','Miền Nam','Khám phá văn hóa đa dạng, cảnh quan và đời sống cộng đồng vùng biên Tây Nam Bộ.','Văn hóa – cộng đồng',2,'2 ngày 1 đêm','Long Xuyên hoặc Châu Đốc, An Giang','Xe du lịch; đi bộ tại điểm'),
('Cà Mau – chạm miền cực Nam','Miền Nam','Tìm hiểu hệ sinh thái đất ngập nước và đời sống cư dân vùng đất cực Nam.','Sinh thái – cộng đồng',2,'2 ngày 1 đêm','Cà Mau','Xe du lịch; tàu/thuyền theo điều kiện vận hành')
)
insert into public.journeys(title,region,summary,price_from,is_published,tour_type,duration_days,duration_label,departure_point,transport,itinerary,operating_note,price_note,verified_at)
select t.title,t.region,t.summary,0,true,t.tour_type,t.duration_days,t.duration_label,t.departure_point,t.transport,'[]'::jsonb,
'Chương trình và lịch khởi hành được xác nhận trước khi mở đăng ký.',
'Liên hệ NÉP để được tư vấn lịch và chi phí.',null
from tours t where not exists(select 1 from public.journeys j where j.title=t.title);
