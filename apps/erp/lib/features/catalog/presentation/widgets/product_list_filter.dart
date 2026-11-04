enum ProductListFilter {
  all('Tất cả'),
  readyToSell('Sẵn sàng bán'),
  incomplete('Thiếu dữ liệu'),
  inactive('Ngừng KD'),
  inStock('Còn hàng'),
  outOfStock('Hết hàng'),
  deleted('Đã xóa');

  final String label;
  const ProductListFilter(this.label);
}
