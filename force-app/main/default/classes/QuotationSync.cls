public interface QuotationSync {
    Boolean confirmProductExistByCode(String code);
    Integer searchProductByCode(String code);
}
