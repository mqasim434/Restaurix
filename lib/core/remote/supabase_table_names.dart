/// Supabase Postgres table names — never hardcode table strings elsewhere.
abstract final class SupabaseTableNames {
  static const String categories = 'categories';
  static const String products = 'products';
  static const String productVariants = 'product_variants';
  static const String deals = 'deals';
  static const String dealItems = 'deal_items';
  static const String halls = 'halls';
  static const String restaurantTables = 'restaurant_tables';
  static const String orders = 'orders';
  static const String orderItems = 'order_items';
  static const String discounts = 'discounts';
  static const String employees = 'employees';
  static const String attendanceRecords = 'attendance_records';
  static const String salarySlips = 'salary_slips';
  static const String pickupCompanies = 'pickup_companies';
  static const String riders = 'riders';
  static const String appUsers = 'app_users';
  static const String creditCustomers = 'credit_customers';
  static const String creditTransactions = 'credit_transactions';
}
