enum ProductListFilter {
  all('Tất cả'),
  readyToSell('Sẵn sàng bán'),
  incomplete('Thiếu dữ liệu'),
  inactive('Ngừng KD'),
  // deleted('Đã xóa'),
  inStock('Còn hàng'),
  outOfStock('Hết hàng');

  final String label;
  const ProductListFilter(this.label);
}
