export const moodPlans = {
  'Bình yên': ['Bắt đầu bằng một quán cà phê nhỏ do người địa phương gợi ý', 'Đi bộ chậm qua không gian xanh hoặc khu dân cư lâu đời', 'Dừng ở một điểm ngắm cảnh và ghi lại điều khiến bạn thấy thư thái'],
  'Khám phá': ['Tìm hiểu một dấu tích kiến trúc hoặc lịch sử ít được chú ý', 'Thử nhiệm vụ quan sát chi tiết ẩn tại điểm đến', 'Ghé một không gian văn hóa và nghe câu chuyện tại chỗ'],
  'Sống như người địa phương': ['Khám phá chợ hoặc khu sinh hoạt cộng đồng', 'Gặp người kể chuyện bản địa đã được NÉP tuyển chọn', 'Tham gia một hoạt động đời thường phù hợp với văn hóa địa phương'],
  'Sáng tạo': ['Chọn tuyến có chất liệu hình ảnh và kiến trúc đặc sắc', 'Thực hiện thử thách chụp ảnh theo chủ đề', 'Tạo một bưu thiếp kể chuyện từ trải nghiệm trong ngày']
};
export function makeMoodPlan(mood, duration) {
  const steps = moodPlans[mood];
  if (!steps) throw new Error('Vui lòng chọn một phong cách trải nghiệm hợp lệ.');
  return { mood, duration, steps };
}
export function estimateTripBudget(people, dailyBudget, days) {
  const p = Number(people), b = Number(dailyBudget), d = Number(days);
  if (![p,b,d].every(Number.isFinite) || p < 1 || b < 0 || d < 1) throw new Error('Thông tin ngân sách không hợp lệ.');
  return p * b * d;
}
