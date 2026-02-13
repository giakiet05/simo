class AppLocalizations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Navigation
      'dashboard': 'Dashboard',
      'transactions': 'Transactions',
      'categories': 'Categories',
      'recurring': 'Recurring',
      'settings': 'Settings',

      // Dashboard
      'income': 'Income',
      'expense': 'Expense',
      'monthly_budget': 'Monthly Budget',
      'budget_not_set': 'Budget not set',
      'percent_used': '% used',
      'total_transactions': 'Transactions',
      'current_month': 'Current Month',
      'balance': 'Balance',
      'recent_transactions': 'Recent Transactions',
      'view_all': 'View All',
      'income_by_category': 'Income by Category',
      'expense_by_category': 'Expense by Category',
      'no_data': 'No data',
      'income_vs_expense': 'Income vs Expense',
      'spending_trend': 'Income & Expense Trend',
      'select_month': 'Month',
      'select_year': 'Year',
      '3_months': '3 months',
      '6_months': '6 months',
      '1_year': '1 year',
      'jan': 'Jan',
      'feb': 'Feb',
      'mar': 'Mar',
      'apr': 'Apr',
      'may': 'May',
      'jun': 'Jun',
      'jul': 'Jul',
      'aug': 'Aug',
      'sep': 'Sep',
      'oct': 'Oct',
      'nov': 'Nov',
      'dec': 'Dec',

      // Transactions
      'no_transactions': 'No transactions yet',
      'add_transaction': 'Add Transaction',
      'add_more': 'Add New Transaction',
      'save_all': 'Save',
      'type': 'Type',
      'amount': 'Amount',
      'formula': 'Formula',
      'category': 'Category',
      'note': 'Note',
      'no_category': 'No category',
      'delete_transaction': 'Delete Transaction',
      'delete_transaction_confirm':
          'Are you sure you want to delete this transaction?',
      'transaction_deleted': 'Transaction deleted',
      'transaction_created': 'Transactions created',
      'fill_all_fields': 'Please fill amount for all items',
      'item': 'Item',
      'transaction': 'Transaction',
      'optional': 'optional',
      'income_plus': 'Income (+)',
      'expense_minus': 'Expense (-)',
      'long_press_hint': 'Long press an item for more options',

      // Filter
      'filter': 'Filter',
      'filter_transactions': 'Filter Transactions',
      'time': 'Time',
      'all': 'All',
      'this_month': 'This Month',
      'last_month': 'Last Month',
      'last_3_months': 'Last 3 Months',
      'custom_range': 'Custom Range',
      'all_types': 'All Types',
      'all_categories': 'All Categories',
      'amount_range': 'Amount Range',
      'min_amount': 'Min Amount',
      'max_amount': 'Max Amount',
      'clear_all': 'Clear All',
      'apply': 'Apply',
      'from_date': 'From Date',
      'to_date': 'To Date',
      'active_filters': 'Active Filters',
      'load_more': 'Load More',
      'select_multiple': 'Select Multiple',

      // Categories
      'no_categories': 'No categories yet',
      'no_categories_warning':
          'No categories yet. Please create categories to get started.',
      'add_category': 'Add Category',
      'edit_category': 'Edit Category',
      'delete_category': 'Delete Category',
      'category_name': 'Category name',
      'delete_category_confirm': 'Are you sure you want to delete',
      'category_added': 'Category added',
      'category_updated': 'Category updated',
      'category_deleted': 'Category deleted',

      // Recurring
      'recurring_transactions': 'Recurring Transactions',
      'no_recurring': 'No recurring transactions yet',
      'add_recurring': 'Add Recurring',
      'edit_recurring': 'Edit Recurring',
      'delete_recurring': 'Delete Recurring Transaction',
      'delete_recurring_confirm': 'Are you sure you want to delete',
      'recurring_deleted': 'Recurring transaction deleted',
      'recurring_created': 'Recurring transaction created',
      'recurring_updated': 'Recurring transaction updated',
      'run_now': 'Run Now',
      'run_now_confirm': 'Execute this recurring transaction immediately?',
      'transaction_triggered': 'Transaction created',
      'name': 'Name',
      'frequency': 'Frequency',
      'interval': 'Interval',
      'day_of_week': 'Day of Week',
      'day_of_month': 'Day of Month (1-31)',
      'next_run': 'Next run',
      'daily': 'Daily',
      'weekly': 'Weekly',
      'monthly': 'Monthly',
      'by_day': 'By day',
      'by_week': 'By week',
      'by_month': 'By month',
      'days': 'days',
      'week': 'week',
      'weeks': 'weeks',
      'month': 'month',
      'months': 'months',
      'every': 'Every',
      'on': 'on',
      'day': 'day',
      'sunday': 'Sunday',
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',

      // Settings
      'monthly_budget_setting': 'Monthly Budget',
      'currency': 'Currency',
      'language': 'Language',
      'save': 'Save',
      'settings_saved': 'Settings saved',
      'vietnamese': 'Vietnamese',
      'english': 'English',
      'about': 'About',
      'app_description':
          'A simple and intuitive personal finance management app.',

      // Account
      'account': 'Account',
      'sync_data': 'Sync Data',
      'syncing': 'Syncing...',
      'sync_success': 'Sync successful',
      'sync_failed': 'Sync failed',
      'logout': 'Logout',
      'logout_confirm':
          'Are you sure you want to logout?\n\nData will be synced to cloud before logout.',
      'syncing_data': 'Syncing data...',
      'logout_error': 'Logout error',
      'loading_data': 'Loading data...',

      // Auth
      'email': 'Email',
      'password': 'Password',
      'login': 'Login',
      'register': 'Register',
      'dont_have_account': 'Don\'t have an account?',
      'create_new_account': 'Create New Account',
      'register_to_sync': 'Register to sync data across multiple devices',
      'confirm_password': 'Confirm Password',
      'app_tagline': 'Simple Money Management',

      // Auth Validation
      'please_enter_email': 'Please enter email',
      'invalid_email': 'Invalid email',
      'please_enter_password': 'Please enter password',
      'password_min_6': 'Password must be at least 6 characters',
      'password_min_8': 'Password must be at least 8 characters',
      'password_helper':
          'Minimum 8 characters, with uppercase, lowercase, number and special character',
      'password_need_uppercase':
          'Password must have at least 1 uppercase letter',
      'password_need_lowercase':
          'Password must have at least 1 lowercase letter',
      'password_need_number': 'Password must have at least 1 number',
      'password_need_special':
          'Password must have at least 1 special character',
      'please_confirm_password': 'Please confirm password',
      'passwords_not_match': 'Passwords do not match',

      // Auth Errors
      'login_failed': 'Login failed',
      'invalid_credentials': 'Invalid email or password',
      'email_not_confirmed':
          'Please confirm your email before logging in.\nCheck your inbox.',
      'network_error': 'Network error. Please check your internet connection.',
      'register_failed': 'Registration failed',
      'email_already_registered':
          'This email is already registered.\nPlease use another email or login.',
      'password_too_weak':
          'Password is too weak.\nPlease use a stronger password.',
      'system_error': 'System error.\nPlease try again later.',
      'register_success_confirm':
          'Registration successful!\n\nPlease check your email to confirm your account before logging in.',
      'register_success': 'Registration successful! You can login now.',

      // Common
      'cancel': 'Cancel',
      'add': 'Add',
      'edit': 'Edit',
      'delete': 'Delete',
      'error': 'Error',
      'category_optional': 'Category (optional)',
      'done': 'Done',

      // Calculator
      'please_enter_amount': 'Please enter an amount',
      'amount_cannot_negative': 'Amount cannot be negative',
      'invalid_formula': 'Invalid formula',

      // Default Categories
      'cat_salary': 'Salary',
      'cat_bonus': 'Bonus',
      'cat_investment': 'Investment',
      'cat_other_income': 'Other Income',
      'cat_food': 'Food & Dining',
      'cat_transport': 'Transportation',
      'cat_shopping': 'Shopping',
      'cat_entertainment': 'Entertainment',
      'cat_bills': 'Bills & Utilities',
      'cat_healthcare': 'Healthcare',
      'cat_other_expense': 'Other',
    },
    'vi': {
      // Navigation
      'dashboard': 'Tổng quan',
      'transactions': 'Giao dịch',
      'categories': 'Danh mục',
      'recurring': 'Định kỳ',
      'settings': 'Cài đặt',

      // Dashboard
      'income': 'Thu nhập',
      'expense': 'Chi tiêu',
      'monthly_budget': 'Giới hạn tháng',
      'budget_not_set': 'Chưa đặt giới hạn',
      'percent_used': '% đã dùng',
      'total_transactions': 'Giao dịch',
      'current_month': 'Tháng hiện tại',
      'balance': 'Số dư',
      'recent_transactions': 'Giao dịch gần đây',
      'view_all': 'Xem tất cả',
      'income_by_category': 'Thu nhập theo danh mục',
      'expense_by_category': 'Chi tiêu theo danh mục',
      'no_data': 'Không có dữ liệu',
      'income_vs_expense': 'Thu nhập vs Chi tiêu',
      'spending_trend': 'Xu hướng thu nhập và chi tiêu',
      'select_month': 'Tháng',
      'select_year': 'Năm',
      '3_months': '3 tháng',
      '6_months': '6 tháng',
      '1_year': '1 năm',
      'jan': 'Thg 1',
      'feb': 'Thg 2',
      'mar': 'Thg 3',
      'apr': 'Thg 4',
      'may': 'Thg 5',
      'jun': 'Thg 6',
      'jul': 'Thg 7',
      'aug': 'Thg 8',
      'sep': 'Thg 9',
      'oct': 'Thg 10',
      'nov': 'Thg 11',
      'dec': 'Thg 12',

      // Transactions
      'no_transactions': 'Chưa có giao dịch',
      'add_transaction': 'Thêm giao dịch',
      'add_more': 'Thêm giao dịch mới',
      'save_all': 'Lưu',
      'type': 'Loại',
      'amount': 'Số tiền',
      'formula': 'Công thức',
      'category': 'Danh mục',
      'note': 'Ghi chú',
      'no_category': 'Không có danh mục',
      'delete_transaction': 'Xóa giao dịch',
      'delete_transaction_confirm': 'Bạn chắc chắn muốn xóa giao dịch này?',
      'transaction_deleted': 'Đã xóa giao dịch',
      'transaction_created': 'Đã tạo giao dịch',
      'fill_all_fields': 'Vui lòng điền số tiền cho tất cả các mục',
      'item': 'Mục',
      'transaction': 'Giao dịch',
      'optional': 'tùy chọn',
      'income_plus': 'Thu nhập (+)',
      'expense_minus': 'Chi tiêu (-)',
      'long_press_hint': 'Nhấn giữ một mục để xem thêm tùy chọn',

      // Filter
      'filter': 'Lọc',
      'filter_transactions': 'Lọc giao dịch',
      'time': 'Thời gian',
      'all': 'Tất cả',
      'this_month': 'Tháng này',
      'last_month': 'Tháng trước',
      'last_3_months': '3 tháng gần đây',
      'custom_range': 'Tùy chỉnh',
      'all_types': 'Tất cả loại',
      'all_categories': 'Tất cả danh mục',
      'amount_range': 'Khoảng số tiền',
      'min_amount': 'Số tiền tối thiểu',
      'max_amount': 'Số tiền tối đa',
      'clear_all': 'Xóa hết',
      'apply': 'Áp dụng',
      'from_date': 'Từ ngày',
      'to_date': 'Đến ngày',
      'active_filters': 'Bộ lọc đang dùng',
      'load_more': 'Tải thêm',
      'select_multiple': 'Chọn nhiều',

      // Categories
      'no_categories': 'Chưa có danh mục',
      'no_categories_warning':
          'Chưa có danh mục nào. Hãy tạo các danh mục của bạn.',
      'add_category': 'Thêm danh mục',
      'edit_category': 'Sửa danh mục',
      'delete_category': 'Xóa danh mục',
      'category_name': 'Tên danh mục',
      'delete_category_confirm': 'Bạn chắc chắn muốn xóa',
      'category_added': 'Đã thêm danh mục',
      'category_updated': 'Đã cập nhật danh mục',
      'category_deleted': 'Đã xóa danh mục',

      // Recurring
      'recurring_transactions': 'Giao dịch định kỳ',
      'no_recurring': 'Chưa có giao dịch định kỳ',
      'add_recurring': 'Thêm định kỳ',
      'edit_recurring': 'Sửa định kỳ',
      'delete_recurring': 'Xóa giao dịch định kỳ',
      'delete_recurring_confirm': 'Bạn chắc chắn muốn xóa',
      'recurring_deleted': 'Đã xóa giao dịch định kỳ',
      'recurring_created': 'Đã tạo giao dịch định kỳ',
      'recurring_updated': 'Đã cập nhật giao dịch định kỳ',
      'run_now': 'Chạy ngay',
      'run_now_confirm': 'Thực hiện giao dịch định kỳ này ngay lập tức?',
      'transaction_triggered': 'Đã tạo giao dịch',
      'name': 'Tên',
      'frequency': 'Tần suất',
      'interval': 'Khoảng cách',
      'day_of_week': 'Thứ trong tuần',
      'day_of_month': 'Ngày trong tháng (1-31)',
      'next_run': 'Lần chạy tiếp theo',
      'daily': 'Hàng ngày',
      'weekly': 'Hàng tuần',
      'monthly': 'Hàng tháng',
      'by_day': 'Theo ngày',
      'by_week': 'Theo tuần',
      'by_month': 'Theo tháng',
      'days': 'ngày',
      'week': 'tuần',
      'weeks': 'tuần',
      'month': 'tháng',
      'months': 'tháng',
      'every': 'Mỗi',
      'on': 'vào',
      'day': 'ngày',
      'sunday': 'Chủ nhật',
      'monday': 'Thứ 2',
      'tuesday': 'Thứ 3',
      'wednesday': 'Thứ 4',
      'thursday': 'Thứ 5',
      'friday': 'Thứ 6',
      'saturday': 'Thứ 7',

      // Settings
      'monthly_budget_setting': 'Giới hạn tháng',
      'currency': 'Tiền tệ',
      'language': 'Ngôn ngữ',
      'save': 'Lưu',
      'settings_saved': 'Đã lưu cài đặt',
      'vietnamese': 'Tiếng Việt',
      'english': 'Tiếng Anh',
      'about': 'Giới thiệu',
      'app_description':
          'Ứng dụng quản lý tài chính cá nhân đơn giản và trực quan.',

      // Account
      'account': 'Tài khoản',
      'sync_data': 'Đồng bộ dữ liệu',
      'syncing': 'Đang đồng bộ...',
      'sync_success': 'Đồng bộ thành công',
      'sync_failed': 'Đồng bộ thất bại',
      'logout': 'Đăng xuất',
      'logout_confirm':
          'Bạn có chắc chắn muốn đăng xuất?\n\nDữ liệu sẽ được đồng bộ lên cloud trước khi đăng xuất.',
      'syncing_data': 'Đang đồng bộ dữ liệu...',
      'logout_error': 'Lỗi khi đăng xuất',
      'loading_data': 'Đang tải dữ liệu...',

      // Auth
      'email': 'Email',
      'password': 'Mật khẩu',
      'login': 'Đăng nhập',
      'register': 'Đăng ký',
      'dont_have_account': 'Chưa có tài khoản?',
      'create_new_account': 'Tạo tài khoản mới',
      'register_to_sync': 'Đăng ký để đồng bộ dữ liệu trên nhiều thiết bị',
      'confirm_password': 'Xác nhận mật khẩu',
      'app_tagline': 'Quản lý tài chính đơn giản',

      // Auth Validation
      'please_enter_email': 'Vui lòng nhập email',
      'invalid_email': 'Email không hợp lệ',
      'please_enter_password': 'Vui lòng nhập mật khẩu',
      'password_min_6': 'Mật khẩu phải có ít nhất 6 ký tự',
      'password_min_8': 'Mật khẩu phải có ít nhất 8 ký tự',
      'password_helper':
          'Tối thiểu 8 ký tự, có chữ hoa, chữ thường, số và ký tự đặc biệt',
      'password_need_uppercase': 'Mật khẩu phải có ít nhất 1 chữ hoa',
      'password_need_lowercase': 'Mật khẩu phải có ít nhất 1 chữ thường',
      'password_need_number': 'Mật khẩu phải có ít nhất 1 chữ số',
      'password_need_special': 'Mật khẩu phải có ít nhất 1 ký tự đặc biệt',
      'please_confirm_password': 'Vui lòng xác nhận mật khẩu',
      'passwords_not_match': 'Mật khẩu không khớp',

      // Auth Errors
      'login_failed': 'Đăng nhập thất bại',
      'invalid_credentials': 'Email hoặc mật khẩu không đúng',
      'email_not_confirmed':
          'Vui lòng xác nhận email trước khi đăng nhập.\nKiểm tra hộp thư của bạn.',
      'network_error': 'Lỗi kết nối mạng. Vui lòng kiểm tra internet.',
      'register_failed': 'Đăng ký thất bại',
      'email_already_registered':
          'Email này đã được đăng ký.\nVui lòng sử dụng email khác hoặc đăng nhập.',
      'password_too_weak':
          'Mật khẩu quá yếu.\nVui lòng sử dụng mật khẩu mạnh hơn.',
      'system_error': 'Lỗi hệ thống.\nVui lòng thử lại sau.',
      'register_success_confirm':
          'Đăng ký thành công!\n\nVui lòng kiểm tra email để xác nhận tài khoản trước khi đăng nhập.',
      'register_success': 'Đăng ký thành công! Bạn có thể đăng nhập ngay.',

      // Common
      'cancel': 'Hủy',
      'add': 'Thêm',
      'edit': 'Sửa',
      'delete': 'Xóa',
      'error': 'Lỗi',
      'category_optional': 'Danh mục (tùy chọn)',
      'done': 'Xong',

      // Calculator
      'please_enter_amount': 'Vui lòng nhập số tiền',
      'amount_cannot_negative': 'Số tiền không thể âm',
      'invalid_formula': 'Công thức không hợp lệ',

      // Default Categories
      'cat_salary': 'Lương',
      'cat_bonus': 'Thưởng',
      'cat_investment': 'Đầu tư',
      'cat_other_income': 'Thu nhập khác',
      'cat_food': 'Ăn uống',
      'cat_transport': 'Đi lại',
      'cat_shopping': 'Mua sắm',
      'cat_entertainment': 'Giải trí',
      'cat_bills': 'Hóa đơn & Tiện ích',
      'cat_healthcare': 'Y tế',
      'cat_other_expense': 'Khác',
    },
  };

  final String locale;

  AppLocalizations(this.locale);

  String translate(String key) {
    return _localizedValues[locale]?[key] ?? key;
  }

  String get dashboard => translate('dashboard');
  String get transactions => translate('transactions');
  String get categories => translate('categories');
  String get recurring => translate('recurring');
  String get settings => translate('settings');

  String get income => translate('income');
  String get expense => translate('expense');
  String get monthlyBudget => translate('monthly_budget');
  String get budgetNotSet => translate('budget_not_set');
  String get percentUsed => translate('percent_used');
  String get totalTransactions => translate('total_transactions');
  String get currentMonth => translate('current_month');
  String get balance => translate('balance');
  String get recentTransactions => translate('recent_transactions');
  String get viewAll => translate('view_all');
  String get incomeByCategory => translate('income_by_category');
  String get expenseByCategory => translate('expense_by_category');
  String get noData => translate('no_data');
  String get incomeVsExpense => translate('income_vs_expense');
  String get spendingTrend => translate('spending_trend');
  String get selectMonth => translate('select_month');
  String get selectYear => translate('select_year');

  String get noTransactions => translate('no_transactions');
  String get addTransaction => translate('add_transaction');
  String get addMore => translate('add_more');
  String get saveAll => translate('save_all');
  String get type => translate('type');
  String get amount => translate('amount');
  String get formula => translate('formula');
  String get category => translate('category');
  String get note => translate('note');
  String get noCategory => translate('no_category');
  String get deleteTransaction => translate('delete_transaction');
  String get deleteTransactionConfirm =>
      translate('delete_transaction_confirm');
  String get transactionDeleted => translate('transaction_deleted');
  String get transactionCreated => translate('transaction_created');
  String get fillAllFields => translate('fill_all_fields');

  String get noCategories => translate('no_categories');
  String get noCategoriesWarning => translate('no_categories_warning');
  String get addCategory => translate('add_category');
  String get editCategory => translate('edit_category');
  String get deleteCategory => translate('delete_category');
  String get categoryName => translate('category_name');
  String get deleteCategoryConfirm => translate('delete_category_confirm');
  String get categoryAdded => translate('category_added');
  String get categoryUpdated => translate('category_updated');
  String get categoryDeleted => translate('category_deleted');

  String get recurringTransactions => translate('recurring_transactions');
  String get noRecurring => translate('no_recurring');
  String get addRecurring => translate('add_recurring');
  String get editRecurring => translate('edit_recurring');
  String get deleteRecurring => translate('delete_recurring');
  String get deleteRecurringConfirm => translate('delete_recurring_confirm');
  String get recurringDeleted => translate('recurring_deleted');
  String get recurringCreated => translate('recurring_created');
  String get recurringUpdated => translate('recurring_updated');
  String get runNow => translate('run_now');
  String get runNowConfirm => translate('run_now_confirm');
  String get transactionTriggered => translate('transaction_triggered');
  String get name => translate('name');
  String get frequency => translate('frequency');
  String get interval => translate('interval');
  String get dayOfWeek => translate('day_of_week');
  String get dayOfMonth => translate('day_of_month');
  String get nextRun => translate('next_run');
  String get daily => translate('daily');
  String get weekly => translate('weekly');
  String get monthly => translate('monthly');
  String get byDay => translate('by_day');
  String get byWeek => translate('by_week');
  String get byMonth => translate('by_month');
  String get days => translate('days');
  String get week => translate('week');
  String get weeks => translate('weeks');
  String get month => translate('month');
  String get months => translate('months');
  String get every => translate('every');
  String get on => translate('on');
  String get day => translate('day');
  String get sunday => translate('sunday');
  String get monday => translate('monday');
  String get tuesday => translate('tuesday');
  String get wednesday => translate('wednesday');
  String get thursday => translate('thursday');
  String get friday => translate('friday');
  String get saturday => translate('saturday');

  String get monthlyBudgetSetting => translate('monthly_budget_setting');
  String get currency => translate('currency');
  String get language => translate('language');
  String get save => translate('save');
  String get settingsSaved => translate('settings_saved');
  String get vietnamese => translate('vietnamese');
  String get english => translate('english');
  String get about => translate('about');
  String get appDescription => translate('app_description');

  String get account => translate('account');
  String get syncData => translate('sync_data');
  String get syncing => translate('syncing');
  String get syncSuccess => translate('sync_success');
  String get syncFailed => translate('sync_failed');
  String get logout => translate('logout');
  String get logoutConfirm => translate('logout_confirm');
  String get syncingData => translate('syncing_data');
  String get logoutError => translate('logout_error');
  String get loadingData => translate('loading_data');

  String get email => translate('email');
  String get password => translate('password');
  String get login => translate('login');
  String get register => translate('register');
  String get dontHaveAccount => translate('dont_have_account');
  String get createNewAccount => translate('create_new_account');
  String get registerToSync => translate('register_to_sync');
  String get confirmPassword => translate('confirm_password');
  String get appTagline => translate('app_tagline');

  String get pleaseEnterEmail => translate('please_enter_email');
  String get invalidEmail => translate('invalid_email');
  String get pleaseEnterPassword => translate('please_enter_password');
  String get passwordMin6 => translate('password_min_6');
  String get passwordMin8 => translate('password_min_8');
  String get passwordHelper => translate('password_helper');
  String get passwordNeedUppercase => translate('password_need_uppercase');
  String get passwordNeedLowercase => translate('password_need_lowercase');
  String get passwordNeedNumber => translate('password_need_number');
  String get passwordNeedSpecial => translate('password_need_special');
  String get pleaseConfirmPassword => translate('please_confirm_password');
  String get passwordsNotMatch => translate('passwords_not_match');

  String get loginFailed => translate('login_failed');
  String get invalidCredentials => translate('invalid_credentials');
  String get emailNotConfirmed => translate('email_not_confirmed');
  String get networkError => translate('network_error');
  String get registerFailed => translate('register_failed');
  String get emailAlreadyRegistered => translate('email_already_registered');
  String get passwordTooWeak => translate('password_too_weak');
  String get systemError => translate('system_error');
  String get registerSuccessConfirm => translate('register_success_confirm');
  String get registerSuccess => translate('register_success');

  String get cancel => translate('cancel');
  String get add => translate('add');
  String get edit => translate('edit');
  String get delete => translate('delete');
  String get error => translate('error');
  String get categoryOptional => translate('category_optional');
  String get done => translate('done');

  String get pleaseEnterAmount => translate('please_enter_amount');
  String get amountCannotNegative => translate('amount_cannot_negative');
  String get invalidFormula => translate('invalid_formula');

  String get item => translate('item');
  String get transaction => translate('transaction');
  String get optional => translate('optional');
  String get incomePlus => translate('income_plus');
  String get expenseMinus => translate('expense_minus');
  String get longPressHint => translate('long_press_hint');

  String get threeMonths => translate('3_months');
  String get sixMonths => translate('6_months');
  String get oneYear => translate('1_year');

  String get filter => translate('filter');
  String get filterTransactions => translate('filter_transactions');
  String get time => translate('time');
  String get all => translate('all');
  String get thisMonth => translate('this_month');
  String get lastMonth => translate('last_month');
  String get last3Months => translate('last_3_months');
  String get customRange => translate('custom_range');
  String get allTypes => translate('all_types');
  String get allCategories => translate('all_categories');
  String get amountRange => translate('amount_range');
  String get minAmount => translate('min_amount');
  String get maxAmount => translate('max_amount');
  String get clearAll => translate('clear_all');
  String get apply => translate('apply');
  String get fromDate => translate('from_date');
  String get toDate => translate('to_date');
  String get activeFilters => translate('active_filters');
  String get loadMore => translate('load_more');
  String get selectMultiple => translate('select_multiple');

  // Translate default category name by ID
  String translateCategoryName(String categoryId, String defaultName) {
    if (categoryId.startsWith('cat_')) {
      return translate(categoryId);
    }
    return defaultName;
  }

  // Get month name by number (1-12)
  String getMonthName(int month) {
    final monthKeys = [
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec',
    ];
    if (month >= 1 && month <= 12) {
      return translate(monthKeys[month - 1]);
    }
    return month.toString();
  }
}
